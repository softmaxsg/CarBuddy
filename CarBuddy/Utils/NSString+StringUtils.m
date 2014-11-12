//
//  NSString+StringUtils.m
//
//  Copyright 2011 Vitaly Chupryk. All rights reserved.
//

#import "NSString+StringUtils.h"

NSString * const NSStringEmpty = @"";

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
@implementation NSString (StringUtils)

+ (NSString *)empty
{
    return NSStringEmpty;
}

+ (BOOL)isNullOrEmpty:(NSString *)string
{
    return string == nil || [string isEqual:[NSNull null]] || [string compare:NSStringEmpty] == NSOrderedSame;
}

+ (BOOL)isNullOrWhitespace:(NSString *)string
{
    return [NSString isNullOrEmpty:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
}

- (BOOL)isCaseInsensitiveEqualToString:(NSString *)string
{
    return [self caseInsensitiveCompare:string] == NSOrderedSame;
}

@end
#pragma clang diagnostic pop
