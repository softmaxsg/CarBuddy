//
//  MainViewController.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MainViewController.h"
#import "BeaconDetails.h"
#import "BeaconDetailsViewModel.h"
#import "SoundsService.h"

@interface MainViewController ()

@property (nonatomic) IBOutlet UIButton *toggleMonitoringButton;
@property (nonatomic) IBOutlet UIImageView *carImageView;
@property (nonatomic) IBOutlet UIImageView *walletImageView;

@property (nonatomic) UIColor *carImageDefaultTintColor;
@property (nonatomic) UIColor *walletImageDefaultTintColor;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLBeaconRegion *carBeaconRegion;
@property (nonatomic) CLBeaconRegion *walletBeaconRegion;

@property (nonatomic) CLProximity carBeaconProximity;
@property (nonatomic) CLProximity walletBeaconProximity;

@property (nonatomic) NSTimer *beepingTimer;

@property (nonatomic) BOOL forgottenWalletAlertDisplayed;

- (void)beaconRegion:(CLBeaconRegion *)beaconRegion logChangedProximity:(CLProximity)proximity;

- (void)configureBeaconRegions;
- (CLBeaconRegion *)configureRegionForBeacon:(BeaconDetails *)beacon oldRegion:(CLBeaconRegion *)oldRegion;
- (void)configureCarBeaconRegion;
- (void)configureWalletBeaconRegion;

- (void)showForgottenWalletAlert;
- (void)alertUserIfRequired;

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue;
- (IBAction)toggleMonitoringStatusTapped;

@end

@implementation MainViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView *carImageView = self.carImageView;
    UIImageView *walletImageView = self.walletImageView;

    self.carImageDefaultTintColor = carImageView.tintColor;
    self.walletImageDefaultTintColor = walletImageView.tintColor;

    carImageView.image = [carImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    walletImageView.image = [walletImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    self.toggleMonitoringButton.enabled = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;

    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    self.locationManager = locationManager;

    [self startTimers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeModelObservers];
    [self stopTimers];
}

- (void)startTimers
{
    if (self.beepingTimer == nil)
    {
        self.beepingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(warnUserIfRequired) userInfo:nil repeats:YES];
    }
}

- (void)stopTimers
{
    [self.beepingTimer invalidate];
    self.beepingTimer = nil;
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

- (CLBeaconRegion *)configureRegionForBeacon:(BeaconDetails *)beacon oldRegion:(CLBeaconRegion *)oldRegion
{
    CLLocationManager *locationManager = self.locationManager;
    if (oldRegion != nil)
    {
        [locationManager stopMonitoringForRegion:oldRegion];
        [locationManager stopRangingBeaconsInRegion:oldRegion];
    }

    if (beacon.isValid &&
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways &&
       self.toggleMonitoringButton.selected)
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

- (void)configureCarBeaconRegion
{
    self.carBeaconProximity = (CLProximity)INT_MIN;

    self.carBeaconRegion = [self configureRegionForBeacon:[[BeaconDetailsViewModel instance] beaconForKind:BeaconKindCar]
                                                oldRegion:self.carBeaconRegion];

    if (self.carBeaconRegion == nil)
    {
        self.carImageView.tintColor = self.carImageDefaultTintColor;
    }
}

- (void)configureWalletBeaconRegion
{
    self.walletBeaconProximity = (CLProximity)INT_MIN;

    self.walletBeaconRegion = [self configureRegionForBeacon:[[BeaconDetailsViewModel instance] beaconForKind:BeaconKindWallet]
                                                   oldRegion:self.walletBeaconRegion];

    if (self.walletBeaconRegion == nil)
    {
        self.walletImageView.tintColor = self.walletImageDefaultTintColor;
    }
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

- (void)warnUserIfRequired
{
    CLProximity carBeaconProximity = self.carBeaconProximity;
    CLProximity walletBeaconProximity = self.walletBeaconProximity;

    if ((walletBeaconProximity == CLProximityFar && (carBeaconProximity == CLProximityImmediate || carBeaconProximity == CLProximityNear)) ||
        (walletBeaconProximity == CLProximityUnknown && carBeaconProximity == CLProximityFar))
    {
        [[SoundsService instance] playBeepSound];
    }
}

- (void)applicationDidBecomeActive:(__unused NSNotification *)notification
{
    [self startTimers];
}

- (void)applicationWillResignActive:(__unused NSNotification *)notification
{
    [self stopTimers];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    UIImageView *imageView;

    CLBeacon *beacon = beacons.firstObject;
    if ([region.proximityUUID isEqual:self.carBeaconRegion.proximityUUID])
    {
        self.carBeaconProximity = beacon.proximity;
        imageView = self.carImageView;
    }
    else if ([region.proximityUUID isEqual:self.walletBeaconRegion.proximityUUID])
    {
        self.walletBeaconProximity = beacon.proximity;
        imageView = self.walletImageView;
    }
    else
    {
        return;
    }

    switch (beacon.proximity)
    {
        case CLProximityImmediate:
        case CLProximityNear:
            imageView.tintColor = [UIColor greenColor]; break;
        case CLProximityFar:
            imageView.tintColor = [UIColor yellowColor]; break;
        default:
            imageView.tintColor = [UIColor redColor]; break;
    }

    [self alertUserIfRequired];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Ranging beacons failed for region %@ (%@). %@", region.identifier, region.proximityUUID.UUIDString, error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager has been failed. %@", error);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        NSLog(@"Monitoring failed for region %@ (%@). %@", beaconRegion.identifier, beaconRegion.proximityUUID.UUIDString, error);
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    self.toggleMonitoringButton.enabled = status == kCLAuthorizationStatusAuthorizedAlways;

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

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue
{
}

- (IBAction)toggleMonitoringStatusTapped
{
    self.toggleMonitoringButton.selected = !self.toggleMonitoringButton.selected;
    if (self.toggleMonitoringButton.selected)
    {
        self.forgottenWalletAlertDisplayed = NO;

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
#pragma clang diagnostic pop
    }
    else
    {
        [self removeModelObservers];
        [self configureBeaconRegions];

        self.carImageView.tintColor = self.carImageDefaultTintColor;
        self.walletImageView.tintColor = self.walletImageDefaultTintColor;
    }
}

@end
