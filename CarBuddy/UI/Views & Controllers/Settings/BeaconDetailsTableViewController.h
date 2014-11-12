//
//  BeaconDetailsTableViewController.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BeaconDetails;

@interface BeaconDetailsTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic) BeaconDetails *beacon;

@end
