//
//  SoundsService.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SoundsService : NSObject

+ (SoundsService *)instance;

- (void)playSound:(SystemSoundID)soundID;
- (void)playAlertSound;
- (void)playBeepSound;

@end
