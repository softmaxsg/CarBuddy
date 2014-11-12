//
//  SettingsViewModel.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <libextobjc/EXTKeyPathCoding.h>
#import "SettingsViewModel.h"

NSString * const kEnergySavingModeSettingsKey = @"kEnergySavingModeSettingsKey";

@implementation SettingsViewModel

+ (SettingsViewModel *)instance
{
    static SettingsViewModel *instance;

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
        self.energySavingMode = [[NSUserDefaults standardUserDefaults] boolForKey:kEnergySavingModeSettingsKey];

        [self addObserver:self forKeyPath:@keypath(self.energySavingMode) options:NSKeyValueObservingOptionNew context:nil];
    }

    return self;
}

- (void)save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.energySavingMode forKey:kEnergySavingModeSettingsKey];
    [userDefaults synchronize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self save];
}

@end
