//
//  SettingsViewModel.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsViewModel : NSObject

@property (nonatomic) BOOL energySavingMode;

+ (SettingsViewModel *)instance;

@end
