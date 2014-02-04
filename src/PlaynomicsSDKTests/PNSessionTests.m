//
//  PNEventTests.m
//  iosapi
//
//  Created by Jared Jenkins on 8/29/13.
//
//

#import "PNSession.h"
#import "PNSession+Private.h"

#import "PNDeviceManager.h"
#import "PNDeviceManager+Private.h"

#import "StubPNEventApiClient.h"
#import "StubPNCache.h"

#import "PNEventAppPage.h"
#import "PNEventAppPause.h"
#import "PNEventAppResume.h"
#import "PNEventAppStart.h"
#import "PNEventUserInfo.h"
#import "PNEventMilestone.h"
#import "PNEventTransaction.h"
#import <XCTest/XCTest.h>

@interface PNSessionTests : XCTestCase
@end

@implementation PNSessionTests{
    PNSession *_session;
    StubPNEventApiClient *_stubApiClient;
    StubPNCache *_cache;
}

-(void) setUp{
    _session = [[PNSession alloc] init];
    _stubApiClient = [[StubPNEventApiClient alloc] init];
    _session.apiClient = [_stubApiClient getMockClient];
}

-(void) tearDown{
    [_cache release];
    [_stubApiClient release];
    [_session release];
}

-(id) mockCurrentDeviceInfo:(PNDeviceManager*) deviceInfo
                       idfv: (NSString *) currentIdfv {
    
    id mock = [OCMockObject partialMockForObject:deviceInfo];
    [[[mock stub] andReturn: currentIdfv] getVendorIdentifierFromDevice];
    
    return mock;
}


//runs app start with no initial device data, expects 2 events: appStart and userInfo
-(void) testAppStartNewDevice{
    NSString *idfv = nil;
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:currentIdfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId,  @"test-user", @"User ID should be set");
    
    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventUserInfo class]], @"userInfo is the second event");
    
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//ios5 tests
-(void) testAppStartPreviousUserId{
    NSString *idfv = nil;
    NSString *lastUserId = @"lastUserId";
    
    NSTimeInterval tenMinutesAgo = NSTimeIntervalSince1970 - 10 * 60;
    PNGeneratedHexId *sessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv lastEventTime:tenMinutesAgo lastUserId:lastUserId lastSessionId:sessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    //assume IDFA is not available
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId,  lastUserId, @"User ID should be loaded from cache");
    
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 event should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
    
}


//runs app start with initial device data, expects 1 event: appStart
-(void) testAppStartNoDeviceChanges{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];

    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];

    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId,  @"test-user", @"User ID should be set");
    
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 events should be queued");
    PNEventAppStart *appStart = [_stubApiClient.events objectAtIndex:0];
    XCTAssertNotNil(appStart, @"appStart is the first event");

    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//runs session start with initial device data, and lapsed previous session, expects 1 event: appStart
-(void) testAppStartLapsedSession {
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    NSTimeInterval now = [[NSDate new] timeIntervalSinceNow];
    NSTimeInterval tenMinutesAgo = now - 60 * 10;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv lastEventTime: tenMinutesAgo lastUserId: nil lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, [[_cache getMockCache] getIdfv], @"User ID should be same as IDFV");
    
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart generated after session has lapsed");

    XCTAssertTrue(lastSessionId.generatedId != _session.sessionId.generatedId, @"Session ID should be new.");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//runs session start with initial device data, and lapsed previous session, expects 1 event: appStart
-(void) testAppStartSwappedUser {
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    NSString *lastUserId = @"old-user-id";
    NSString *newUserId = @"new-user-id";
    
    NSTimeInterval now = [[NSDate new] timeIntervalSinceNow];
    NSTimeInterval aMinuteAgo = now - 60 * 1;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv lastEventTime: aMinuteAgo lastUserId: lastUserId lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = newUserId;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, lastUserId, @"User ID should be same as the last used user id");

    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is generated when a new user appears");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventUserInfo class]], @"userInfo is generated when a new user appears");
    
    XCTAssertEqualObjects([[[_stubApiClient.events objectAtIndex:1] eventParameters] objectForKey:PNEventParameterUserInfoAltUserId], newUserId, @"User Id should be passed as an extra parameter in a user info call");
    
    XCTAssertTrue(lastSessionId.generatedId != _session.sessionId.generatedId, @"Session ID should be new.");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//runs session start with initial device data, a previous startTime, expects 2 events: appPage
-(void) testAppPauseNoDeviceChanges{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    NSString *lastUserId = idfv;
    NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
    NSTimeInterval aMinuteAgo = now - 60;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv lastEventTime: aMinuteAgo lastUserId: lastUserId lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, [[_cache getMockCache] getIdfv], @"User ID should be same as IDFV");
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 event should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppPage class]], @"appPage is the first event");
    XCTAssertTrue(lastSessionId.generatedId == _session.sessionId.generatedId, @"Session ID should be loaded from cache.");
    XCTAssertTrue(_session.sessionId.generatedId != _session.instanceId.generatedId, @"Instance ID and Session ID should be different.");
}

//runs the start, and then milestone. expects 2 events: appStart and milestone
-(void) testMilestone{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    [_session milestone:PNMilestoneCustom1];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventMilestone class]], @"milestone is the second event");
}

//runs the milestone without calling start first. expects 0 events
-(void) testMilestoneNoStart{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    [_session milestone:PNMilestoneCustom1];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"No events should be queued");
}

//runs start, and then transaction. expects 2 events: appStart and milestone
-(void) testTransaction{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    [_session transactionWithUSDPrice:[NSNumber numberWithDouble:0.99] quantity:1];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventTransaction class]], @"transaction is the second event");

}
//runs  transaction without calling start first. expects 0 events
-(void) testTransactionNoStart{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    [_session transactionWithUSDPrice:[NSNumber numberWithDouble:0.99] quantity:1];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"No events should be queued");
}

//runs start, and then enablePushNotifications, expects 2 events: appStart and enable push notifications
-(void) testEnabledPush{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    //token gets updated
    StubDeviceToken *newToken = [[StubDeviceToken alloc] initWithToken:@"<9876 54321>" cleanToken:@"987654321"];
    [_session enablePushNotificationsWithToken: newToken];
    
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventUserInfo class]], @"userInfo is the second event");
}

//runs enablePushNotifications without calling start first. expects 0 events
-(void) testEnabledPushNoStart{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];

    //token gets updated
    StubDeviceToken *newToken = [[StubDeviceToken alloc] initWithToken:@"<9876 54321>" cleanToken:@"987654321"];
    [_session enablePushNotificationsWithToken: newToken];

    XCTAssertTrue([_stubApiClient.events count] == 0, @"0 events should be queued");
}

//runs enablePushTokens but the token has not changed. expects 1 event: appStart
-(void) testEnabledPushNoTokenChange{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    //token does not change
    [_session enablePushNotificationsWithToken: oldToken];

    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 event should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
}


-(void) testAttribution{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";

    [_session start];
    
    NSString *source=  @"source";
    NSString *campaign=  @"campaign";
    NSDate *installDate = [NSDate date];
    [_session attributeInstallToSource:source withCampaign:campaign onInstallDate:installDate];

    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    XCTAssertTrue([_stubApiClient.events count] == 2, @"2 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventUserInfo class]], @"userInfo is the second event");

}

-(void) testAttributionNoStart{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    NSString *source=  @"source";
    NSString *campaign=  @"campaign";
    NSDate *installDate = [NSDate date];
    [_session attributeInstallToSource:source withCampaign:campaign onInstallDate:installDate];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"0 events should be queued");
}

-(void) testApplicationLifeCycle{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    [_session pause];
    [_session resume];

    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    
    XCTAssertTrue([_stubApiClient.events count] == 3, @"3 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:1] isKindOfClass:[PNEventAppPause class]], @"appPause is the second event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:2] isKindOfClass:[PNEventAppResume class]], @"appResume is the third event");
}

-(void) testApplicationRestartLifeCycle{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    [_session pause];
    
    PNGeneratedHexId *lastSessionId = _session.sessionId;
    NSString *lastUserId = _session.userId;
    
    NSTimeInterval now = [[NSDate new] timeIntervalSinceNow];
    NSTimeInterval thirtyMinutesAgo = now - 60 * 30;
    _session.pauseTime = thirtyMinutesAgo;
    
    _cache = [[StubPNCache alloc] initWithIdfv:idfv lastEventTime: thirtyMinutesAgo lastUserId: lastUserId lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfv:idfv];
    
    [_session resume];
    
    XCTAssertTrue([_stubApiClient.events count] == 3, @"3 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:2] isKindOfClass:[PNEventAppStart class]], @"appStart is the third event");
    XCTAssertTrue(lastSessionId.generatedId != _session.sessionId.generatedId, @"Session ID should be new.");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

@end
