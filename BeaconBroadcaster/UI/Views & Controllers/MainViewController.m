//
//  MainViewController.m
//  BeaconBroadcaster
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <libextobjc/EXTKeyPathCoding.h>
#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic) IBOutlet UILabel *beaconUUIDLabel;
@property (nonatomic) IBOutlet UILabel *beaconIdentifierLabel;
@property (nonatomic) IBOutlet UIImageView *broadcastingStatusImageView;
@property (nonatomic) IBOutlet UIButton *toggleBroadcastingStatusButton;

@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (nonatomic) NSMutableDictionary *beaconPeripheralData;
@property (nonatomic) CBPeripheralManager *peripheralManager;

- (void)startBroadcasting;
- (void)stopBroadcasting;

- (void)checkForStoppedBroadcasting;

- (IBAction)toggleBroadcastingStatusTapped;

@end

@implementation MainViewController
{
    UIImage *_broadcastingImage;
    UIImage *_broadcastingStoppedImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _broadcastingImage = [UIImage animatedImageNamed:@"Broadcasting" duration:2.0];
    _broadcastingStoppedImage = [UIImage imageNamed:@"BroadcastingStopped"];

    [self.toggleBroadcastingStatusButton addObserver:self
                                          forKeyPath:@keypath(UIButton.new, selected)
                                             options:NSKeyValueObservingOptionNew
                                             context:nil];

    self.toggleBroadcastingStatusButton.enabled = NO;
    self.toggleBroadcastingStatusButton.selected = NO;

    UIDevice *currentDevice = [UIDevice currentDevice];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:currentDevice.identifierForVendor
                                                           identifier:currentDevice.name];

    self.beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:nil];

    self.beaconUUIDLabel.text = self.beaconRegion.proximityUUID.UUIDString;
    self.beaconIdentifierLabel.text = self.beaconRegion.identifier;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.toggleBroadcastingStatusButton && [keyPath isEqualToString:@keypath(UIButton.new, selected)])
    {
        self.broadcastingStatusImageView.image = [change[NSKeyValueChangeNewKey] boolValue] ? _broadcastingImage : _broadcastingStoppedImage;
    }
}

- (void)startBroadcasting
{
    NSAssert(self.peripheralManager.state == CBPeripheralManagerStatePoweredOn, @"Bluetooth should be turned ON");

    [self.peripheralManager startAdvertising:self.beaconPeripheralData];
}

- (void)stopBroadcasting
{
    if (self.peripheralManager.isAdvertising)
    {
        [self.peripheralManager stopAdvertising];
        [self checkForStoppedBroadcasting];
    }
}

- (void)checkForStoppedBroadcasting
{
    if (self.peripheralManager.isAdvertising)
    {
        [self performSelector:_cmd withObject:nil afterDelay:0];
    }
    else
    {
        self.toggleBroadcastingStatusButton.selected = NO;

        NSLog(@"Beacon broadcasting stopped");
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"Bluetooth state changed to %d", (int)peripheral.state);

    BOOL peripheralEnabled = peripheral.state == CBPeripheralManagerStatePoweredOn;
    if (!peripheralEnabled)
    {
        [self stopBroadcasting];
    }

    self.toggleBroadcastingStatusButton.enabled = peripheralEnabled;
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    self.toggleBroadcastingStatusButton.selected = peripheral.isAdvertising;

    if (error != nil)
    {
        NSLog(@"Beacon broadcasting starting failed due error %@", error);

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat:@"Cannot start broadcasting due error. %@", error.localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        NSLog(@"Beacon broadcasting started");
    }
}

- (IBAction)toggleBroadcastingStatusTapped
{
    if (!self.toggleBroadcastingStatusButton.selected)
    {
        if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn)
        {
            [self startBroadcasting];
        }
    }
    else
    {
        [self stopBroadcasting];
    }
}

@end
