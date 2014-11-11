//
//  MainViewController.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic) IBOutlet UIImageView *carImageView;
@property (nonatomic) IBOutlet UIImageView *walletImageView;

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.carImageView.image = [self.carImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.walletImageView.image = [self.walletImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (IBAction)closeModalSegue:(UIStoryboardSegue *)segue
{
}

@end
