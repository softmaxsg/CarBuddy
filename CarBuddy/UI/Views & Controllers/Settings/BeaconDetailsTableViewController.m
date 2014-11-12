//
//  BeaconDetailsTableViewController.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <FruitMaskedTextfield/UITextField+Mask.h>
#import "BeaconDetailsTableViewController.h"
#import "BeaconDetails.h"
#import "NSString+StringUtils.h"

@interface BeaconDetailsTableViewController ()

@property (nonatomic) IBOutlet UITextField *identifierTextField;
@property (nonatomic) IBOutlet UITextField *uuidTextField;

+ (NSCharacterSet *)hexCharacterSet;

- (void)updateUI;
- (void)updateTextFieldUI:(UITextField *)textField;

@end

@implementation BeaconDetailsTableViewController

+ (NSCharacterSet *)hexCharacterSet
{
    static NSCharacterSet *hexCharacterSet;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        hexCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
    });

    return hexCharacterSet;
}

- (void)setBeacon:(BeaconDetails *)beacon
{
    if (_beacon != beacon)
    {
        _beacon = beacon;

        [self updateUI];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateUI];
}

- (void)updateUI
{
    [self updateTextFieldUI:nil];
}

- (void)updateTextFieldUI:(UITextField *)textField
{
    if (self.isViewLoaded)
    {
        BeaconDetails *beacon = self.beacon;

        UITextField *identifierTextField = self.identifierTextField;
        if (textField == nil || textField == identifierTextField)
        {
            identifierTextField.text = beacon.identifier;
        }

        UITextField *uuidTextField = self.uuidTextField;
        if (textField == nil || textField == uuidTextField)
        {
            uuidTextField.text = [beacon.uuid.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:NSStringEmpty];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.beacon.kindString;
    }

    return [super tableView:tableView titleForHeaderInSection:section];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.identifierTextField)
    {
        self.beacon.identifier = textField.text;
    }

    if (textField == self.uuidTextField)
    {
        self.beacon.uuid = [[NSUUID alloc] initWithUUIDString:textField.maskedText];
    }

    [self updateTextFieldUI:textField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.uuidTextField)
    {
        NSRange testRange = [string rangeOfCharacterFromSet:[self.class hexCharacterSet]];
        return testRange.length == string.length;
    }

    return YES;
}

@end
