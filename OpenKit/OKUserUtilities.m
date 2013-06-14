//
//  OKUserUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/8/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUserUtilities.h"
#import "OKManager.h"
#import "OKUser.h"
#import "OKNetworker.h"
#import "OKDefines.h"
#import "OKMacros.h"
#import "OKError.h"



@implementation OKUserUtilities

+ (OKUser *)createOKUserWithJSONData:(NSDictionary *)jsonData
{
    OKUser *user = [[OKUser alloc] init];
    
    NSString *_userNick = [jsonData objectForKey:@"nick"];
    NSNumber *_twitterID = [jsonData objectForKey:@"twitter_id"];
    
    if(_twitterID == (id)[NSNull null])
        _twitterID = nil;
    
    NSNumber *_OKUserID = [jsonData objectForKey:@"id"];
    NSNumber *_fbID = [jsonData objectForKey:@"fb_id"];
    NSString *_gameCenterID = [jsonData objectForKey:@"gamecenter_id"];
    NSNumber *_customID = [jsonData objectForKey:@"custom_id"];

    
    if(_fbID == (id)[NSNull null])
        _fbID = nil;
    
    [user setOKUserID:_OKUserID];
    [user setUserNick:_userNick];
    [user setFbUserID:_fbID];
    [user setTwitterUserID:_twitterID];
    [user setGameCenterID:_gameCenterID];
    [user setCustomID:_customID];
    
    return user;
}

+ (NSDictionary *)getJSONRepresentationOfUser:(OKUser *)user
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [dict setValue:[user userNick] forKey:@"nick"];
    [dict setValue:[user twitterUserID] forKey:@"twitter_id"];
    [dict setValue:[user OKUserID] forKey:@"id"];
    [dict setValue:[user fbUserID] forKey:@"fb_id"];
    [dict setValue:[user gameCenterID] forKey:@"gamecenter_id"];
    [dict setValue:[user customID] forKey:@"custom_id"];
    
    return dict;
}

+(void)updateOKUser:(OKUser *)user withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    if(!user){
        completionHandler([OKError noOKUserError]);
    }
    
    NSDictionary *userDict = [OKUserUtilities getJSONRepresentationOfUser:user];
    NSDictionary *params = [NSDictionary dictionaryWithObject:userDict forKey:@"user"];
    NSString *requestPath = [NSString stringWithFormat:@"/users/%@", [user.OKUserID stringValue]];
    
    [OKNetworker putToPath:requestPath parameters:params
                   handler:^(id responseObject, NSError *error)
     {
         if(!error){
             //Check to make sure the user was returned, that way we know the response was successful
             OKUser *responseUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
             
             if([responseUser OKUserID] == [user OKUserID]) {
                 [[OKManager sharedManager] saveCurrentUser:responseUser];
             }
             else {
                 error = [OKError unknownError];
             }
         } else {
             NSLog(@"Error updating OKUser: %@", error);
         }
         completionHandler(error);
     }];
}


+ (void)updateUserNickForOKUser:(OKUser *)user withNewNick:(NSString *)newNick withCompletionHandler:(void(^)(NSError *error))completionHandler
{    
    //Setup the parameters
    NSDictionary *userDict = [NSDictionary dictionaryWithObject:newNick forKey:@"nick"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userDict, @"user", nil];
    
    NSString *requestPath = [NSString stringWithFormat:@"/users/%@", [user.OKUserID stringValue]];
    
    [OKNetworker putToPath:requestPath parameters:params
                   handler:^(id responseObject, NSError *error)
     {
         if(!error){
             //Check to make sure the user was returned, that way we know the response was successful
             OKUser *responseUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
             
             if([responseUser OKUserID] == [user OKUserID])
             {
                 [[OKManager sharedManager] saveCurrentUser:responseUser];
             }
             else
             {
                 NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Unknown error from OpenKit when trying to update user nick" forKey:NSLocalizedDescriptionKey];
                 error = [[NSError alloc] initWithDomain:OKErrorDomain code:0 userInfo:errorInfo];
             }
         }else{
             NSLog(@"Error updating username: %@", error);
         }
         completionHandler(error);
     }];
}


+(void)createOKUserWithUserIDType:(OKUserIDType)userIDtype withUserID:(NSString*)userID withUserNick:(NSString *)userNick withCompletionHandler:(void(^)(OKUser *user, NSError *errror))completionHandler
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            userNick, @"nick", nil];
    
    
    // Set the correct parameter based on UserID type
    switch(userIDtype) {
        case FacebookIDType:
            [params setObject:userID forKey:@"fb_id"];
            break;
        case TwitterIDType:
            [params setObject:userID forKey:@"twitter_id"];
            break;
        case GoogleIDType:
            [params setObject:userID forKey:@"google_id"];
            break;
        case GameCenterIDType:
            [params setObject:userID forKey:@"gamecenter_id"];
            break;
        case CustomIDType:
            [params setObject:userID forKey:@"custom_id"];
            break;
    }
    
    [OKNetworker postToPath:@"/users" parameters:params
                    handler:^(id responseObject, NSError *error)
     {
         OKUser *newUser = nil;
         if(!error) {
             //Success
             OKLog(@"Successfully created/found user ID: %@", [responseObject valueForKeyPath:@"id"]);
             newUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
             
             // Save current user
             //[[OKManager sharedManager] saveCurrentUser:newUser];
         } else {
             OKLog(@"Failed to create user with error: %@", error);
         }
         
         completionHandler(newUser, error);
     }];
}
@end
