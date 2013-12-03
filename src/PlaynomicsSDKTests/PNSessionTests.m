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

-(id) mockCurrentDeviceInfo:(PNDeviceManager*) deviceInfo idfa: (NSString *) currentIdfa limitAdvertising : (BOOL) limitAdvertising idfv: (NSString *) currentIdfv {
    
    id mock = [OCMockObject partialMockForObject:deviceInfo];
    
    BOOL isAdvertisingEnabled = !limitAdvertising;
    [[[mock stub] andReturnValue: OCMOCK_VALUE(isAdvertisingEnabled)] isAdvertisingTrackingEnabledFromDevice];
    [[[mock stub] andReturn: currentIdfa] getAdvertisingIdentifierFromDevice];
    [[[mock stub] andReturn: currentIdfv] getVendorIdentifierFromDevice];
    
    return mock;
}


//runs app start with no initial device data, expects 2 events: appStart and userInfo
-(void) testAppStartNewDevice{
    NSString *idfa = nil;
    BOOL limitAdvertising = NO;
    NSString *idfv = nil;
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    NSString *currentIdfa = [[[NSUUID alloc] init] UUIDString];
    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];
    BOOL currentLimit = NO;
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: currentIdfa limitAdvertising:currentLimit idfv:currentIdfv];
    
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
    NSString *idfa = nil;
    BOOL limitAdvertising = NO;
    NSString *idfv = nil;

    NSString *lastUserId = @"lastUserId";
    
    NSTimeInterval tenMinutesAgo = NSTimeIntervalSince1970 - 10 * 60;
    PNGeneratedHexId *sessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising lastEventTime:tenMinutesAgo lastUserId:lastUserId lastSessionId:sessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    //assume IDFA is not available
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfa];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];

    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];

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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    NSTimeInterval now = [[NSDate new] timeIntervalSinceNow];
    NSTimeInterval tenMinutesAgo = now - 60 * 10;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising lastEventTime: tenMinutesAgo lastUserId: nil lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    _session.applicationId = 1;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, [[_cache getMockCache] getIdfa], @"User ID should be same as IDFA");
    
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart generated after session has lapsed");

    XCTAssertTrue(lastSessionId.generatedId != _session.sessionId.generatedId, @"Session ID should be new.");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//runs session start with initial device data, and lapsed previous session, expects 1 event: appStart
-(void) testAppStartSwappedUser {
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    NSString *lastUserId = @"old-user-id";
    
    NSTimeInterval now = [[NSDate new] timeIntervalSinceNow];
    NSTimeInterval aMinuteAgo = now - 60 * 1;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising lastEventTime: aMinuteAgo lastUserId: lastUserId lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    _session.applicationId = 1;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, [[_cache getMockCache] getIdfa], @"User ID should be same as IDFA");

    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is generated when a new user appears");
    
    XCTAssertTrue(lastSessionId.generatedId != _session.sessionId.generatedId, @"Session ID should be new.");
    XCTAssertTrue(_session.sessionId.generatedId == _session.instanceId.generatedId, @"Instance ID and Session ID should be equal.");
}

//runs session start with initial device data, a previous startTime, expects 2 events: appPage
-(void) testAppPauseNoDeviceChanges{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];

    NSString *lastUserId = idfa;
    NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
    NSTimeInterval aMinuteAgo = now - 60;
    
    PNGeneratedHexId *lastSessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising lastEventTime: aMinuteAgo lastUserId: lastUserId lastSessionId: lastSessionId];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    _session.applicationId = 1;
    [_session start];
    
    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, [[_cache getMockCache] getIdfa], @"User ID should be same as IDFA");
    XCTAssertTrue([_stubApiClient.events count] == 1, @"1 event should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppPage class]], @"appPage is the first event");
    XCTAssertTrue(lastSessionId.generatedId == _session.sessionId.generatedId, @"Session ID should be loaded from cache.");
    XCTAssertTrue(_session.sessionId.generatedId != _session.instanceId.generatedId, @"Instance ID and Session ID should be different.");
}

//runs the start, and then milestone. expects 2 events: appStart and milestone
-(void) testMilestone{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    [_session milestone:PNMilestoneCustom1];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"No events should be queued");
}

//runs start, and then transaction. expects 2 events: appStart and milestone
-(void) testTransaction{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    [_session transactionWithUSDPrice:[NSNumber numberWithDouble:0.99] quantity:1];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"No events should be queued");
}

//runs start, and then enablePushNotifications, expects 2 events: appStart and enable push notifications
-(void) testEnabledPush{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];

    //token gets updated
    StubDeviceToken *newToken = [[StubDeviceToken alloc] initWithToken:@"<9876 54321>" cleanToken:@"987654321"];
    [_session enablePushNotificationsWithToken: newToken];

    XCTAssertTrue([_stubApiClient.events count] == 0, @"0 events should be queued");
}

//runs enablePushTokens but the token has not changed. expects 1 event: appStart
-(void) testEnabledPushNoTokenChange{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
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
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubDeviceToken *oldToken = [[StubDeviceToken alloc] initWithToken:@"<12345 6789>" cleanToken:@"123456789"];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising deviceToken:oldToken];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    NSString *source=  @"source";
    NSString *campaign=  @"campaign";
    NSDate *installDate = [NSDate date];
    [_session attributeInstallToSource:source withCampaign:campaign onInstallDate:installDate];
    
    XCTAssertTrue([_stubApiClient.events count] == 0, @"0 events should be queued");
}

-(void) testApplicationLifeCycle{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    _cache = [[StubPNCache alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    _session.cache = [_cache getMockCache];
    _session.deviceManager = [[PNDeviceManager alloc] initWithCache: _session.cache];
    
    [self mockCurrentDeviceInfo: _session.deviceManager idfa: idfa limitAdvertising:limitAdvertising idfv:idfv];
    
    _session.applicationId = 1;
    _session.userId = @"test-user";
    
    [_session start];
    [_session pause];
    [_session resume];

    XCTAssertTrue(_session.applicationId == 1L, @"Application should be set");
    XCTAssertEqualObjects(_session.userId, @"test-user", @"User ID should be set");
    
    XCTAssertTrue([_stubApiClient.events count] == 3, @"3 events should be queued");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appStart is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appPause is the first event");
    XCTAssertTrue([[_stubApiClient.events objectAtIndex:0] isKindOfClass:[PNEventAppStart class]], @"appResume is the first event");
}
@end
