//
//  SoundsService.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "SoundsService.h"

@implementation SoundsService
{
    SystemSoundID alertSoundID;
    SystemSoundID beepSoundID;
}

+ (SoundsService *)instance
{
    static SoundsService *instance;

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
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
        NSBundle *mainBundle = [NSBundle mainBundle];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[mainBundle URLForResource:@"Alert" withExtension:@"wav"], &alertSoundID);
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[mainBundle URLForResource:@"Beep" withExtension:@"wav"], &beepSoundID);
#pragma clang diagnostic pop
    }

    return self;
}

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(alertSoundID);
    AudioServicesDisposeSystemSoundID(beepSoundID);
}

- (void)playSound:(SystemSoundID)soundID
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        AudioServicesPlaySystemSound(soundID);
    }
}

- (void)playAlertSound
{
    [self playSound:alertSoundID];
}

- (void)playBeepSound
{
    [self playSound:beepSoundID];
}

@end
