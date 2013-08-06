//
//  OKScoreCache.m
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCache.h"
#import "OKMacros.h"
#import "OKUser.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"

@implementation OKScoreCache

+ (OKScoreCache*)sharedCache
{
    static dispatch_once_t pred;
    static OKScoreCache *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKScoreCache alloc] init];
    });
    return sharedInstance;
}

// Data Storage structure
// Array of cached scores

- (id)init
{
    self = [super init];
    if (self) {
        //init code
    }
    return self;
}

-(void)storeArrayOfEncodedScoresInDefaults:(NSArray*)encodedScores
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedScores forKey:SCORES_CACHE_KEY];
    [defaults synchronize];
}

-(void)storeScore:(OKScore*)score
{
    NSMutableArray *mutableScoreCache = [[NSMutableArray alloc] initWithArray:[self getCachedEncodedScoresArray]];
    NSData *encodedScore = [NSKeyedArchiver archivedDataWithRootObject:score];
    [mutableScoreCache addObject:encodedScore];
    
    [self storeArrayOfEncodedScoresInDefaults:mutableScoreCache];
    
    OKLog(@"Cached score with value: %lld & leaderboard id: %d",[score scoreValue], [score OKLeaderboardID]);
}

-(NSArray*)getCachedScores
{
    NSMutableArray *scoreArray = [[NSMutableArray alloc] init];
    NSArray *encodedScoresArray = [self getCachedEncodedScoresArray];
    
    for(int x = 0; x < [encodedScoresArray count]; x++)
    {
        NSData *encodedScore = [encodedScoresArray objectAtIndex:x];
        OKScore *score = (OKScore *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedScore];
        [scoreArray addObject:score];
    }
    
    //OKLog(@"Got %d cached scores", [encodedScoresArray count]);
    return scoreArray;
}

-(void)removeScoreFromCache:(OKScore*)scoreToRemove
{
    NSArray *cachedEncodedScores = [self getCachedEncodedScoresArray];
    NSMutableArray *mutableScoreCache = [[NSMutableArray alloc] init];
    
    // Copy the array (cache) but exclude the item to be removed
    for(int x = 0; x < [cachedEncodedScores count]; x++)
    {
        NSData *encodedScore = [cachedEncodedScores objectAtIndex:x];
        OKScore *score = (OKScore *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedScore];
        
        if([score OKScoreID] == [scoreToRemove OKScoreID]) {
            // Don't add it to the new one
            OKLog(@"Removed cached score ID: %d", [scoreToRemove OKScoreID]);
        } else {
            [mutableScoreCache addObject:encodedScore];
        }
    }
    
    [self storeArrayOfEncodedScoresInDefaults:mutableScoreCache];
}


-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID
{
    NSArray *cachedScores = [self getCachedScores];
    
    NSMutableArray *leaderboardScores = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < [cachedScores count]; x++)
    {
        OKScore *score = [cachedScores objectAtIndex:x];
        
        if([score OKLeaderboardID] == leaderboardID)
            [leaderboardScores addObject:score];
    }
    
    return leaderboardScores;
}

-(NSArray*)getCachedEncodedScoresArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *scoresCache = [defaults objectForKey:SCORES_CACHE_KEY];
    
    // If the cache is not found, return an empty array
    if(scoresCache == nil || ![scoresCache isKindOfClass:[NSArray class]]) {
        return [[NSArray alloc] init];
    } else {
        return scoresCache;
    }
}

-(void)submitCachedScore:(OKScore*)score
{
    if( [OKUser currentUser]) {
        [score setUser:[OKUser currentUser]];
        
        [score submitScoreWithCompletionHandler:^(NSError *error) {
            if(!error)
            {
                [self removeScoreFromCache:score];
                OKLog(@"Submitted cached core succesfully");
            }
        }];
        
    } else {
        OKLog(@"Tried to submit a cached score without having an OKUser logged in");
        return;
    }
}

-(void)clearCache
{
    OKLog(@"Clear cached scores");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:SCORES_CACHE_KEY];
    [defaults synchronize];
}

-(void)submitAllCachedScores
{
    NSArray *cachedScores = [self getCachedScores];
    
    if([cachedScores count] > 0)
    {
        OKLog(@"Submit all cached scores");
        
        for(int x = 0; x < [cachedScores count]; x++)
        {
            OKScore *score = [cachedScores objectAtIndex:x];
            [self submitCachedScore:score];
        }
    }
}

- (void)dealloc
{
    // Do not call super here.  Using arc.
}

@end