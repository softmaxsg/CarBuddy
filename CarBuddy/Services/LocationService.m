//
//  LocationService.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "LocationService.h"
#import "BeaconDetails.h"
#import "BeaconDetailsViewModel.h"
#import "SoundsService.h"

NSString * const kMonitoringStatusKey = @"kMonitoringStatusKey";

@interface LocationService ()

@property (nonatomic, readwrite) CLBeaconRegion *carBeaconRegion;
@property (nonatomic, readwrite) CLBeaconRegion *walletBeaconRegion;

@property (nonatomic, readwrite) CLProximity carBeaconProximity;
@property (nonatomic, readwrite) CLProximity walletBeaconProximity;

@property (nonatomic, readwrite) BOOL monitoringAllowed;
@property (nonatomic, readwrite) BOOL monitoring;

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) BOOL forgottenWalletAlertDisplayed;

- (BOOL)monitoringStatusSetting;
- (void)setMonitoringStatusSetting:(BOOL)status;

- (void)requestForAuthorization;

- (void)beaconRegion:(CLBeaconRegion *)beaconRegion logChangedProximity:(CLProximity)proximity;

- (void)addModelObservers;
- (void)removeModelObservers;

- (CLBeaconRegion *)configureRegionForBeacon:(BeaconDetails *)beacon oldRegion:(CLBeaconRegion *)oldRegion;

- (void)configureBeaconRegions;
- (void)configureCarBeaconRegion;
- (void)configureWalletBeaconRegion;

- (void)showForgottenWalletAlert;

- (void)alertUserIfRequired;

@end

@implementation LocationService

- (BOOL)monitoringStatusSetting
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kMonitoringStatusKey];
}

- (void)setMonitoringStatusSetting:(BOOL)status
{
    if (status != self.monitoringStatusSetting)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:status forKey:kMonitoringStatusKey];
        [userDefaults synchronize];
    }
}

- (void)setCarBeaconProximity:(CLProximity)carBeaconProximity
{
    if (_carBeaconProximity != carBeaconProximity)
    {
        _carBeaconProximity = carBeaconProximity;

        [self beaconRegion:self.carBeaconRegion logChangedProximity:carBeaconProximity];
    }
}

- (void)setWalletBeaconProximity:(CLProximity)walletBeaconProximity
{
    if (_walletBeaconProximity != walletBeaconProximity)
    {
        if (_walletBeaconProximity == CLProximityUnknown && walletBeaconProximity > CLProximityUnknown)
        {
            self.forgottenWalletAlertDisplayed = NO;
        }

        _walletBeaconProximity = walletBeaconProximity;

        [self beaconRegion:self.walletBeaconRegion logChangedProximity:walletBeaconProximity];
    }
}

- (void)setMonitoring:(BOOL)monitoring
{
    if (_monitoring != monitoring)
    {
        _monitoring = monitoring;

        [self setMonitoringStatusSetting:monitoring];
    }
}

+ (LocationService *)instance
{
    static LocationService *instance;

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
        self.monitoringAllowed = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;

        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        self.locationManager = locationManager;

        if (self.monitoringStatusSetting)
        {
            [self startMonitoring];
        }
        else
        {
            [self requestForAuthorization];
        }
    }

    return self;
}

- (void)dealloc
{
    [self removeModelObservers];
}

- (void)requestForAuthorization
{
    CLLocationManager *locationManager = self.locationManager;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)] &&
        [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways)
    {
        [locationManager requestAlwaysAuthorization];
    }
    else
    {
        [self locationManager:locationManager didChangeAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

- (void)startMonitoring
{
    self.monitoring = YES;
    self.forgottenWalletAlertDisplayed = NO;

    [self requestForAuthorization];
}

- (void)stopMonitoring
{
    if (!self.monitoring) return;

    self.monitoring = NO;

    [self removeModelObservers];
    [self configureBeaconRegions];
}

- (void)beaconRegion:(CLBeaconRegion *)beaconRegion logChangedProximity:(CLProximity)proximity
{
    if (beaconRegion == nil) return;

    if (proximity >= CLProximityUnknown)
    {
        NSLog(@"Proximity has been changed to %d for region %@ (%@)", (int)proximity, beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString);
    }
    else
    {
        NSLog(@"Proximity has been cleared for region %@ (%@)", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString);
    }
}

- (void)addModelObservers
{
    BeaconDetailsViewModel *beaconsViewModel = [BeaconDetailsViewModel instance];
    [[beaconsViewModel beaconForKind:BeaconKindCar] addObserver:self options:NSKeyValueObservingOptionNew context:nil];
    [[beaconsViewModel beaconForKind:BeaconKindWallet] addObserver:self options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeModelObservers
{
    BeaconDetailsViewModel *beaconsViewModel = [BeaconDetailsViewModel instance];
    [[beaconsViewModel beaconForKind:BeaconKindCar] removeObserver:self];
    [[beaconsViewModel beaconForKind:BeaconKindWallet] removeObserver:self];
}

- (CLBeaconRegion *)configureRegionForBeacon:(BeaconDetails *)beacon oldRegion:(CLBeaconRegion *)oldRegion
{
    CLLocationManager *locationManager = self.locationManager;
    if (oldRegion != nil)
    {
        [locationManager stopMonitoringForRegion:oldRegion];
        [locationManager stopRangingBeaconsInRegion:oldRegion];
    }

    if (self.monitoring && beacon.isValid && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)
    {
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.uuid identifier:beacon.identifier];
        beaconRegion.notifyEntryStateOnDisplay = YES;
        beaconRegion.notifyOnEntry = YES;
        beaconRegion.notifyOnExit = YES;

        [locationManager startMonitoringForRegion:beaconRegion];
        [locationManager startRangingBeaconsInRegion:beaconRegion];

        return beaconRegion;
    }

    return nil;
}

- (void)configureBeaconRegions
{
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound | UIUserNotificationTypeAlert
                                                                                        categories:nil]];
    }
#pragma clang diagnostic pop

    [self configureCarBeaconRegion];
    [self configureWalletBeaconRegion];
}

- (void)configureCarBeaconRegion
{
    self.carBeaconProximity = (CLProximity)INT_MIN;

    self.carBeaconRegion = [self configureRegionForBeacon:[[BeaconDetailsViewModel instance] beaconForKind:BeaconKindCar]
                                                oldRegion:self.carBeaconRegion];
}

- (void)configureWalletBeaconRegion
{
    self.walletBeaconProximity = (CLProximity)INT_MIN;

    self.walletBeaconRegion = [self configureRegionForBeacon:[[BeaconDetailsViewModel instance] beaconForKind:BeaconKindWallet]
                                                   oldRegion:self.walletBeaconRegion];
}

- (void)showForgottenWalletAlert
{
    if (self.forgottenWalletAlertDisplayed) return;

    NSString * const kForgottenWalletNotificationMessage = @"Seems you are going to drive without your wallet.";

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        self.forgottenWalletAlertDisplayed = YES;

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:kForgottenWalletNotificationMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];

        [alertView show];

        [[SoundsService instance] playAlertSound];
    }
    else
    {
        BOOL notificationsAllowed = YES;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(currentUserNotificationSettings)])
        {
            UIUserNotificationType currentNotificationTypes = application.currentUserNotificationSettings.types;
            notificationsAllowed = (currentNotificationTypes & (UIUserNotificationTypeSound | UIUserNotificationTypeAlert)) != 0;
        }
#pragma clang diagnostic pop

        if (notificationsAllowed)
        {
            self.forgottenWalletAlertDisplayed = YES;

            UILocalNotification*notification = [[UILocalNotification alloc] init];
            notification.alertBody = kForgottenWalletNotificationMessage;
            notification.soundName = @"Alert.wav";
            [application presentLocalNotificationNow:notification];
        }
    }
}

- (void)alertUserIfRequired
{
    CLProximity carBeaconProximity = self.carBeaconProximity;
    CLProximity walletBeaconProximity = self.walletBeaconProximity;

    if (walletBeaconProximity == CLProximityUnknown && (carBeaconProximity == CLProximityImmediate || carBeaconProximity == CLProximityNear))
    {
        [self showForgottenWalletAlert];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[BeaconDetails class]])
    {
        BeaconKind beaconKind = ((BeaconDetails *)object).kind;
        switch (beaconKind)
        {
            case BeaconKindCar:
                [self configureCarBeaconRegion]; break;
            case BeaconKindWallet:
                [self configureWalletBeaconRegion]; break;
            default:
                NSAssert(NO, @"Should not happen"); break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    CLBeacon *beacon = beacons.firstObject;
    if ([region.proximityUUID isEqual:self.carBeaconRegion.proximityUUID])
    {
        self.carBeaconProximity = beacon.proximity;
    }
    else if ([region.proximityUUID isEqual:self.walletBeaconRegion.proximityUUID])
    {
        self.walletBeaconProximity = beacon.proximity;
    }

    [self alertUserIfRequired];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Ranging beacons failed for region %@ (%@). %@", region.identifier, region.proximityUUID.UUIDString, error);

    [self stopMonitoring];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager has been failed. %@", error);

    [self stopMonitoring];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        NSLog(@"Monitoring failed for region %@ (%@). %@", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString, error);

        [self stopMonitoring];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    self.monitoringAllowed = status == kCLAuthorizationStatusAuthorizedAlways;

    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        NSLog(@"Monitoring is allowed.");

        [self addModelObservers];
    }
    else
    {
        NSLog(@"Monitoring is disabled.");

        [self removeModelObservers];
    }

    [self configureBeaconRegions];
}

@end
