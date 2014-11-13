//
//  LocationService.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationService : NSObject <CLLocationManagerDelegate>

@property (nonatomic, readonly) CLBeaconRegion *carBeaconRegion;
@property (nonatomic, readonly) CLBeaconRegion *walletBeaconRegion;

@property (nonatomic, readonly) CLProximity carBeaconProximity;
@property (nonatomic, readonly) CLProximity walletBeaconProximity;

@property (nonatomic, readonly) BOOL monitoringAllowed;
@property (nonatomic, readonly) BOOL monitoring;

+ (LocationService *)instance;

- (void)startMonitoring;
- (void)stopMonitoring;

@end
