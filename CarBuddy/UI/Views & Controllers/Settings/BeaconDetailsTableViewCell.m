//
//  BeaconDetailsTableViewCell.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <libextobjc/EXTKeyPathCoding.h>
#import "BeaconDetailsTableViewCell.h"
#import "BeaconDetails.h"
#import "NSString+StringUtils.h"

@implementation BeaconDetailsTableViewCell

- (void)dealloc
{
    [self removeObservers];
}

- (void)setBeacon:(BeaconDetails *)beacon
{
    if (_beacon != beacon)
    {
        [self removeObservers];

        _beacon = beacon;

        [self addObservers];
        [self updateUI];
    }
}

- (void)addObservers
{
    [self.beacon addObserver:self options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservers
{
    [self.beacon removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.beacon)
    {
        [self updateUI];
    }
}

- (void)updateUI
{
    BeaconDetails *beacon = self.beacon;
    BOOL isBeaconValid = beacon.isValid;

    UILabel *textLabel = self.textLabel;
    if ([NSString isNullOrWhitespace:beacon.identifier])
    {
        textLabel.text = @"Configure";
    }
    else
    {
        textLabel.text = beacon.identifier;
    }
    textLabel.enabled = isBeaconValid;

    UILabel *detailTextLabel = self.detailTextLabel;
    detailTextLabel.text = beacon.uuid.UUIDString;
    detailTextLabel.enabled = isBeaconValid;
}

@end
