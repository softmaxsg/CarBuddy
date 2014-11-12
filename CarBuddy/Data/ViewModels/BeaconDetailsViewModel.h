//
//  BeaconDetailsViewModel.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconDetails.h"

@class BeaconDetails;

@interface BeaconDetailsViewModel : NSObject

+ (BeaconDetailsViewModel *)instance;

- (BeaconDetails *)beaconForKind:(BeaconKind)kind;

@end
