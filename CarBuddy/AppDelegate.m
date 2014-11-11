//
//  AppDelegate.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureNavigationBarsAppearance];

    return YES;
}

- (void)configureNavigationBarsAppearance
{
    UINavigationBar *appearance = [UINavigationBar appearance];

    appearance.titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:22] };
}

@end
