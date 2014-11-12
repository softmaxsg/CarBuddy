//
//  SettingsViewController.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsViewModel.h"
#import "BeaconDetailsTableViewCell.h"
#import "BeaconDetailsViewModel.h"

@interface SettingsViewController ()

@property (nonatomic) IBOutlet BeaconDetailsTableViewCell *carBeaconCell;
@property (nonatomic) IBOutlet BeaconDetailsTableViewCell *walletBeaconCell;
@property (nonatomic) IBOutlet UISwitch *energySavingModeSwitch;

- (IBAction)energySavingModeChanged;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    BeaconDetailsViewModel *beaconsViewModel = [BeaconDetailsViewModel instance];
    self.carBeaconCell.beacon = [beaconsViewModel beaconForKind:BeaconKindCar];
    self.walletBeaconCell.beacon = [beaconsViewModel beaconForKind:BeaconKindWallet];

    self.energySavingModeSwitch.on = [SettingsViewModel instance].energySavingMode;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    if ([sender respondsToSelector:@selector(beacon)] && [segue.destinationViewController respondsToSelector:@selector(setBeacon:)])
    {
        [segue.destinationViewController setBeacon:[sender beacon]];
    }
}

- (IBAction)energySavingModeChanged
{
    [SettingsViewModel instance].energySavingMode = self.energySavingModeSwitch.on;
}

@end
