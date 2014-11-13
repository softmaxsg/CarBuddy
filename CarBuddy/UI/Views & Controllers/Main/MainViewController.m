//
//  MainViewController.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <libextobjc/EXTKeyPathCoding.h>
#import <CoreLocation/CoreLocation.h>
#import "MainViewController.h"
#import "SoundsService.h"
#import "LocationService.h"

@interface MainViewController ()

@property (nonatomic) IBOutlet UIButton *toggleMonitoringButton;
@property (nonatomic) IBOutlet UIImageView *carImageView;
@property (nonatomic) IBOutlet UIImageView *walletImageView;

@property (nonatomic) UIColor *carImageDefaultTintColor;
@property (nonatomic) UIColor *walletImageDefaultTintColor;

@property (nonatomic) NSTimer *beepingTimer;

- (void)addObservers;
- (void)removeObservers;

- (void)startTimers;
- (void)stopTimers;

- (void)updateImageView:(UIImageView *)imageView forProximity:(CLProximity)proximity;

- (void)warnUserIfRequired;

- (void)applicationDidBecomeActive:(__unused NSNotification *)notification;
- (void)applicationWillResignActive:(__unused NSNotification *)notification;

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue;
- (IBAction)toggleMonitoringStatusTapped;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView *carImageView = self.carImageView;
    UIImageView *walletImageView = self.walletImageView;

    self.carImageDefaultTintColor = carImageView.tintColor;
    self.walletImageDefaultTintColor = walletImageView.tintColor;

    carImageView.image = [carImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    walletImageView.image = [walletImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [self addObservers];
    [self startTimers];

    LocationService *locationService = [LocationService instance];
    self.toggleMonitoringButton.enabled = locationService.monitoringAllowed;
    self.toggleMonitoringButton.selected = locationService.monitoring;
}

- (void)dealloc
{
    [self removeObservers];
    [self stopTimers];
}

- (void)addObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];

    LocationService *locationService = [LocationService instance];
    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.carBeaconRegion)
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.walletBeaconRegion)
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.carBeaconProximity)
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.walletBeaconProximity)
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.monitoringAllowed)
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [locationService addObserver:self
                      forKeyPath:@keypath(locationService.monitoring)
                         options:NSKeyValueObservingOptionNew
                         context:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    LocationService *locationService = [LocationService instance];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.carBeaconRegion)];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.walletBeaconRegion)];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.carBeaconProximity)];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.walletBeaconProximity)];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.monitoringAllowed)];
    [locationService removeObserver:self forKeyPath:@keypath(locationService.monitoring)];
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

-(void)updateImageView:(UIImageView *)imageView forProximity:(CLProximity)proximity
{
    switch (proximity)
    {
        case CLProximityImmediate:
        case CLProximityNear:
            imageView.tintColor = [UIColor greenColor]; break;
        case CLProximityFar:
            imageView.tintColor = [UIColor yellowColor]; break;
        default:
            imageView.tintColor = [UIColor redColor]; break;
    }
}

- (void)warnUserIfRequired
{
    LocationService *locationService = [LocationService instance];
    CLProximity carBeaconProximity = locationService.carBeaconProximity;
    CLProximity walletBeaconProximity = locationService.walletBeaconProximity;

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    LocationService *locationService = [LocationService instance];
    if (object == locationService)
    {
        if ([keyPath isEqualToString:@keypath(locationService.carBeaconRegion)])
        {
            if (locationService.carBeaconRegion == nil)
            {
                self.carImageView.tintColor = self.carImageDefaultTintColor;
            }
        }
        else if ([keyPath isEqualToString:@keypath(locationService.walletBeaconRegion)])
        {
            if (locationService.walletBeaconRegion == nil)
            {
                self.walletImageView.tintColor = self.walletImageDefaultTintColor;
            }
        }
        else  if ([keyPath isEqualToString:@keypath(locationService.monitoringAllowed)])
        {
            self.toggleMonitoringButton.enabled = locationService.monitoringAllowed;
        }
        else  if ([keyPath isEqualToString:@keypath(locationService.monitoring)])
        {
            self.toggleMonitoringButton.selected = locationService.monitoring;
        }
        else  if ([keyPath isEqualToString:@keypath(locationService.carBeaconProximity)])
        {
            [self updateImageView:self.carImageView forProximity:locationService.carBeaconProximity];
        }
        else  if ([keyPath isEqualToString:@keypath(locationService.walletBeaconProximity)])
        {
            [self updateImageView:self.walletImageView forProximity:locationService.walletBeaconProximity];
        }
    }
}

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue
{
}

- (IBAction)toggleMonitoringStatusTapped
{
    LocationService *locationService = [LocationService instance];
    if (!self.toggleMonitoringButton.selected)
    {
        [locationService startMonitoring];
    }
    else
    {
        [locationService stopMonitoring];
    }
}

@end
