//
//  Util.h
//  iosapi
//
//  Created by Martin Harkins on 6/21/12.
//  Copyright (c 2012 Grio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLConstants.h"


@interface PLUtil : NSObject

+(PLEventType) PLEventTypeValueOf: (NSString *) text;
+(NSString *) PLEventTypeDescription:  (PLEventType) value;

+(PLResponseType) PLResponseTypeValueOf: (NSString *) text;
+(NSString *) PLResponseTypeDescription: (PLResponseType) value;

+(PLTransactionType) PLTransactionTypeValueOf: (NSString *) text;
+(NSString *) PLTransactionTypeDescription: (PLTransactionType) value;

+(PLCurrencyCategory) PLCurrencyCategoryValueOf: (NSString *) text;
+(NSString *) PLCurrencyCategoryDescription: (PLCurrencyCategory) value;

+(PLUserInfoSex) PLUserInfoSexValueOf: (NSString *) text;
+(NSString *) PLUserInfoSexDescription: (PLUserInfoSex) value;

+(PLUserInfoSource) PLUserInfoSourceValueOf: (NSString *) text;
+(NSString *) PLUserInfoSourceDescription: (PLUserInfoSource) value;

@end

