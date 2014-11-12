//
//  BeaconDetails.h
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BeaconKind)
{
    BeaconKindCar = 1,
    BeaconKindWallet
};

@interface BeaconDetails : NSObject <NSCoding>

@property (nonatomic, readonly) BeaconKind kind;
@property (nonatomic) NSUUID *uuid;
@property (nonatomic) NSString *identifier;

- (instancetype)initWithKind:(BeaconKind)kind;
+ (instancetype)beaconWithKind:(BeaconKind)kind;

- (BOOL)isValid;
- (NSString *)kindString;

- (void)addObserver:(NSObject *)observer options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(NSObject *)observer;

@end
