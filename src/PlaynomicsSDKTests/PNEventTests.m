//
//  PNEventTests.m
//  iosapi
//  Created by Jared Jenkins on 8/30/13.
//
//

#import "PNEventAppPage.h"
#import "PNEventAppStart.h"
#import "PNEventAppPause.h"
#import "PNEventAppResume.h"
#import "PNEventAppRunning.h"
#import "PNEventMilestone.h"
#import "PNEventTransaction.h"
#import "PNGeneratedHexId.h"
#import "PNEventUserInfo.h"
#import "PNConstants.h"
#import "PNConfig.h"
#import "PNUtil.h"

#import <XCTest/XCTest.h>

@interface PNEventTests : XCTestCase
@end

@implementation PNEventTests{
    PNGameSessionInfo *_info;
    PNGeneratedHexId *_instanceId;
}

-(void) setUp{
    _info = [[self getGameSessionInfo] retain];
    _instanceId = [[PNGeneratedHexId alloc] initAndGenerateValue];
}

-(void) tearDown {
    [_info release];
}

- (PNGameSessionInfo *) getGameSessionInfo{
    PNGameSessionInfo *info = [[PNGameSessionInfo alloc] initWithApplicationId:1
                                                                        userId:@"user-name"
                                                                          idfv:@"idfv"
                                                                     sessionId:[[PNGeneratedHexId alloc] initAndGenerateValue]];
    return [info autorelease];
}

-(void) assertCommonInfoIsAvailable: (PNEvent*) event sessionInfo: (PNGameSessionInfo *) session {
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"a"], session.applicationId, @"Application ID is set");
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"u"], session.userId, @"User ID is set");
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"idfv"], session.idfv, @"IDFV is set");
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"t"], [NSNumber numberWithLongLong: event.eventTime * 1000], @"Event time is set");
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"ever"], PNPropertyVersion, @"SDK Version is set");
    XCTAssertEqualObjects([event.eventParameters valueForKey:@"esrc"], @"ios", @"SDK Name is set");
    
    if([event isKindOfClass:[PNImplicitEvent class]]){
        XCTAssertEqualObjects([event sessionKey], @"s", @"Session key is set correctly");
    } else {
        XCTAssertEqualObjects([event sessionKey], @"jsh", @"Session key is set correctly");
    }
    
    XCTAssertEqualObjects([event.eventParameters valueForKey:[event sessionKey]], [session.sessionId toHex], @"Session ID is set");
    
    if([event isKindOfClass:[PNEventAppStart class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"appStart", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventAppPage class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"appPage", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventAppResume class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"appResume", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventAppPause class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"appPause", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventAppRunning class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"appRunning", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventTransaction class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"transaction", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventMilestone class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"milestone", @"Has correct URL Path");
    } else if([event isKindOfClass:[PNEventUserInfo class]]){
        XCTAssertEqualObjects([event baseUrlPath], @"userInfo", @"Has correct URL Path");
    }
}

- (void) testAppRunning{
    int touches = 1;
    int totalTouches = 10;
    int sequence = 2;

    int keyPressed = 0;
    int totalKeysPressed = 0;
    
    NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
    
    PNEventAppRunning *running = [[PNEventAppRunning alloc] initWithSessionInfo:_info instanceId:_instanceId sessionStartTime:startTime sequenceNumber:sequence touches:touches totalTouches:totalTouches];
    
    [self assertCommonInfoIsAvailable:running sessionInfo:_info];
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"i"], [_instanceId toHex], @"Instance ID is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"c"], [NSNumber numberWithInt:touches], @"Touch events is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"e"], [NSNumber numberWithInt:totalTouches], @"Total touch events is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"q"], [NSNumber numberWithInt:sequence], @"Sequence is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"k"], [NSNumber numberWithInt:keyPressed], @"Keys pressed is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"l"], [NSNumber numberWithInt:totalKeysPressed], @"Total keys pressed is set");
    XCTAssertEqualObjects([running.eventParameters valueForKey:@"r"], [NSNumber numberWithLongLong:startTime * 1000], @"Session start time is set");
}

- (void) testAppPause{
    int touches = 1;
    int totalTouches = 10;
    int sequence = 2;
    
    int keyPressed = 0;
    int totalKeysPressed = 0;
    
    NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
    
    PNEventAppPause *pause = [[PNEventAppPause alloc] initWithSessionInfo:_info instanceId:_instanceId sessionStartTime:startTime sequenceNumber:sequence touches:touches totalTouches:totalTouches];
    
    [self assertCommonInfoIsAvailable:pause sessionInfo:_info];
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"i"], [_instanceId toHex], @"Instance ID is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"c"], [NSNumber numberWithInt:touches], @"Touch events is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"e"], [NSNumber numberWithInt:totalTouches], @"Total touch events is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"q"], [NSNumber numberWithInt:sequence], @"Sequence is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"k"], [NSNumber numberWithInt:keyPressed], @"Keys pressed is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"l"], [NSNumber numberWithInt:totalKeysPressed], @"Total keys pressed is set");
    XCTAssertEqualObjects([pause.eventParameters valueForKey:@"r"], [NSNumber numberWithLongLong:startTime * 1000], @"Session start time is set");
}

- (void) testAppResume{
    NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970] - 5 * 60;
    NSTimeInterval pauseTime = [[NSDate new] timeIntervalSince1970];
    int sequence = 3;
    PNEventAppResume *resume = [[PNEventAppResume alloc] initWithSessionInfo:_info instanceId:_instanceId sessionPauseTime:pauseTime sessionStartTime:startTime sequenceNumber:sequence];
    [self assertCommonInfoIsAvailable:resume sessionInfo:_info];
    
    XCTAssertEqualObjects([resume.eventParameters valueForKey:@"i"], [_instanceId toHex], @"Instance ID is set");
    XCTAssertEqualObjects([resume.eventParameters valueForKey:@"q"], [NSNumber numberWithInt:sequence], @"Sequence is set");
    XCTAssertEqualObjects([resume.eventParameters valueForKey:@"p"], [NSNumber numberWithLongLong: pauseTime * 1000], @"Pause time is set");
}

- (void) testAppStart{
    PNEventAppStart *start = [[PNEventAppStart alloc] initWithSessionInfo:_info instanceId:_instanceId];
    [self assertCommonInfoIsAvailable:start sessionInfo:_info];
    XCTAssertEqualObjects([start.eventParameters valueForKey:@"i"], [_instanceId toHex], @"Instance ID is set");
    XCTAssertEqualObjects([start.eventParameters valueForKey:@"z"], [NSNumber numberWithInt:[PNUtil timezoneOffet]], @"Time zone is set");
}

-(void) testAppPage{
    PNEventAppPage *page = [[PNEventAppPage alloc] initWithSessionInfo:_info instanceId:_instanceId];
    [self assertCommonInfoIsAvailable:page sessionInfo:_info];
    XCTAssertEqualObjects([page.eventParameters valueForKey:@"i"], [_instanceId toHex], @"Instance ID is set");
    XCTAssertEqualObjects([page.eventParameters valueForKey:@"z"], [NSNumber numberWithInt:[PNUtil timezoneOffet]], @"Instance ID is set");
}

- (void) testTransaction{
    
    NSNumber * quantity = [NSNumber numberWithInt: 1];
    NSNumber * price = [NSNumber numberWithInt: 10];
    
    NSArray *currencyTypes = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:PNCurrencyUSD], nil];
    NSArray *currencyValues = [[NSArray alloc] initWithObjects:price, nil];
    NSArray *currencyCategories = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:PNCurrencyCategoryReal], nil];
    
    PNEventTransaction *trans = [[PNEventTransaction alloc] initWithSessionInfo:_info itemId:@"item" quantity: [quantity intValue] type:PNTransactionBuyItem currencyTypes:currencyTypes currencyValues:currencyValues currencyCategories:currencyCategories];

    [self assertCommonInfoIsAvailable:trans sessionInfo:_info];
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"tc0"], @"USD", @"Currency type is set");
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"tv0"], [NSNumber numberWithInt:10], @"Currency value is set");
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"ta0"], @"r", @"Currency category is set");
    
    XCTAssertNotNil([trans.eventParameters valueForKey:@"r"], @"Transaction ID is set");
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"tt"], @"BuyItem", @"Transaction Type is set");
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"tq"], quantity, @"Quantity is set");
    XCTAssertEqualObjects([trans.eventParameters valueForKey:@"i"], @"item", @"Item is set");
}

- (void) testMilestone{
    PNEventMilestone *milestone = [[PNEventMilestone alloc] initWithSessionInfo:_info milestoneType:PNMilestoneCustom9];
    
    [self assertCommonInfoIsAvailable:milestone sessionInfo:_info];
    XCTAssertEqualObjects([milestone.eventParameters valueForKey:@"mn"], @"CUSTOM9", @"Milestone 9 is set");
}

- (void) testCustomEvent{
    PNEventMilestone *customEvent = [[PNEventMilestone alloc] initWithSessionInfo:_info customEventName:@"eventName"];
    
    [self assertCommonInfoIsAvailable:customEvent sessionInfo:_info];
    XCTAssertEqualObjects([customEvent.eventParameters valueForKey:@"mn"], @"eventName", @"Custom event name set");
}

- (void) testUserInfoAttribution{
    NSString *source = @"source";
    NSString *campaign = @"campaign";
    NSDate* date = [NSDate date];
    NSNumber* unixTimeNum = [NSNumber numberWithInt:[date timeIntervalSince1970]];
    
    PNEventUserInfo *userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:_info
                                                                      source:source
                                                                    campaign:campaign
                                                                 installDate:date];
    [self assertCommonInfoIsAvailable:userInfo sessionInfo:_info];
    
    XCTAssertEqualObjects([userInfo.eventParameters valueForKey:@"po"], source, @"Source is set");
    XCTAssertEqualObjects([userInfo.eventParameters valueForKey:@"pi"], unixTimeNum, @"Install time is set");
    XCTAssertEqualObjects([userInfo.eventParameters valueForKey:@"pm"], campaign, @"Campaign is set");
    
    
    userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:_info
                                                                      source:source
                                                                    campaign:nil
                                                                 installDate:nil];
    [self assertCommonInfoIsAvailable:userInfo sessionInfo:_info];
    
    XCTAssertEqualObjects([userInfo.eventParameters valueForKey:@"po"], source, @"Source is set");
    XCTAssertNil([userInfo.eventParameters valueForKey:@"pi"], @"Install time is not set");
    XCTAssertNil([userInfo.eventParameters valueForKey:@"pm"], @"Campaign is not set");
}

-(void) testUserInfoDevicePushToken{
    
    NSString *pushToken = @"token";
    PNEventUserInfo *userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:_info
                                                                   pushToken:pushToken];
    
    [self assertCommonInfoIsAvailable:userInfo sessionInfo:_info];
    XCTAssertEqualObjects([userInfo.eventParameters valueForKey:@"pushTok"], pushToken, @"Push token is set");
}

-(void) testUserInfoDeviceSettings{
    PNEventUserInfo *userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:_info];
    
    [self assertCommonInfoIsAvailable:userInfo sessionInfo:_info];
}

@end
