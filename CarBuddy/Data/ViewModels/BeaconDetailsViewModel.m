//
//  BeaconDetailsViewModel.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "BeaconDetailsViewModel.h"

NSString * const kBeaconsSettingsKey = @"kBeaconsSettingsKey";

@interface BeaconDetailsViewModel ()

@property (nonatomic) NSMutableDictionary *beacons;

@end

@implementation BeaconDetailsViewModel

+ (BeaconDetailsViewModel *)instance
{
    static BeaconDetailsViewModel *instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[self alloc] init];
    });

    return instance;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        NSData *beaconsData = [[NSUserDefaults standardUserDefaults] dataForKey:kBeaconsSettingsKey];
        if (beaconsData != nil)
        {
            @try
            {
                self.beacons = [NSKeyedUnarchiver unarchiveObjectWithData:beaconsData];
                [self.beacons enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
                {
                    if ([obj respondsToSelector:@selector(addObserver:options:context:)])
                    {
                        [obj addObserver:self options:NSKeyValueObservingOptionNew context:nil];
                    }
                }];
            }
            @catch (NSException *e)
            {
                NSLog(@"[EXCEPTION] Can't read %@ key from settings. %@", kBeaconsSettingsKey, e);
            }
        }

        if (self.beacons == nil)
        {
            self.beacons = [NSMutableDictionary dictionary];
        }
    }

    return self;
}

- (void)save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.beacons] forKey:kBeaconsSettingsKey];
    [userDefaults synchronize];
}

- (BeaconDetails *)beaconForKind:(BeaconKind)kind
{
    BeaconDetails *beacon = self.beacons[@(kind)];
    if (beacon == nil)
    {
        beacon = [BeaconDetails beaconWithKind:kind];
        self.beacons[@(kind)] = beacon;

        [beacon addObserver:self options:NSKeyValueObservingOptionNew context:nil];
    }

    return  beacon;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[BeaconDetails class]])
    {
        [self save];
    }
}

@end
