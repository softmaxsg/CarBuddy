//
//  BeaconDetails.m
//  CarBuddy
//
//  Copyright (c) 2014 Vitaly Chupryk. All rights reserved.
//

#import <libextobjc/EXTKeyPathCoding.h>
#import "BeaconDetails.h"
#import "NSString+StringUtils.h"

@interface BeaconDetails ()

@property (nonatomic, readwrite) BeaconKind kind;

@end

@implementation BeaconDetails

- (instancetype)initWithKind:(BeaconKind)kind
{
    if ((self = [super init]))
    {
        self.kind = kind;
    }

    return self;
}

+ (instancetype)beaconWithKind:(BeaconKind)kind
{
    return [[self alloc] initWithKind:kind];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {
        self.kind = (BeaconKind)[coder decodeIntForKey:@keypath(self.kind)];
        self.uuid = [coder decodeObjectForKey:@keypath(self.uuid)];
        self.identifier = [coder decodeObjectForKey:@keypath(self.identifier)];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.kind forKey:@keypath(self.kind)];
    [coder encodeObject:self.uuid forKey:@keypath(self.uuid)];
    [coder encodeObject:self.identifier forKey:@keypath(self.identifier)];
}

- (BOOL)isValid
{
    return ![NSString isNullOrWhitespace:self.identifier] && self.uuid != nil;
}

- (NSString *)kindString
{
    switch (self.kind)
    {
        case BeaconKindCar: return @"Car";
        case BeaconKindWallet: return @"Wallet";
        default: return @"Unknown";
    }
}

- (void)addObserver:(NSObject *)observer options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [self addObserver:observer forKeyPath:@keypath(self.uuid) options:options context:context];
    [self addObserver:observer forKeyPath:@keypath(self.identifier) options:options context:context];
}

- (void)removeObserver:(NSObject *)observer
{
    [self removeObserver:observer forKeyPath:@keypath(self.uuid)];
    [self removeObserver:observer forKeyPath:@keypath(self.identifier)];
}

@end
