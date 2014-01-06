//
//  PNEventQueueTest.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 12/20/13.
//
//

#import <XCTest/XCTest.h>
#import "Nocilla.h"
#import "PNEventApiClient.h"
#import "PNEventMilestone.h"
#import "PNGameSessionInfo.h"

@interface PNEventQueueTest : XCTestCase

@end

@implementation PNEventQueueTest{
    @private
    PNSession *_session;
    PNEventApiClient *_client;
    PNGameSessionInfo *_sessionInfo;
    PNGeneratedHexId *_generatedHexId;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[LSNocilla sharedInstance] start];
    _session = [[PNSession alloc] init];
    _client = [[PNEventApiClient alloc] initWithSession:_session];
    _generatedHexId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    _sessionInfo = [[PNGameSessionInfo alloc] initWithApplicationId:1L userId:@"user-id" idfa:@"idfa" idfv:@"idfv" sessionId:_generatedHexId];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[LSNocilla sharedInstance] clearStubs];
    [[LSNocilla sharedInstance] stop];
    
    [_session release];
    [_generatedHexId release];
    [_client release];
    [_sessionInfo release];
    
    [super tearDown];
}

- (void)testEventIsDequeuedWhenSuccessful {
    PNEventMilestone *event = [[PNEventMilestone alloc] initWithSessionInfo:_sessionInfo];
    //get this for the stub
    NSString *eventUrl = [PNEventApiClient buildUrlWithBase:[_session getEventsUrl] withPath:event.baseUrlPath withParams:event.eventParameters];
    stubRequest(@"GET", eventUrl).andReturn(200);
    
    [_client enqueueEventUrl:eventUrl];
    
    [_client start];
    [_client stop];
    
    XCTAssertTrue(_client.queueIsEmpty, @"Event queue should be empty");
}

- (void)testEventIsRequeuedWhen404 {
    PNEventMilestone *event = [[PNEventMilestone alloc] initWithSessionInfo:_sessionInfo];
    //get this for the stub
    NSString *eventUrl = [PNEventApiClient buildUrlWithBase:[_session getEventsUrl] withPath:event.baseUrlPath withParams:event.eventParameters];
    stubRequest(@"GET", eventUrl).andReturn(404);
    
    [_client enqueueEventUrl:eventUrl];
    
    [_client start];
    [_client stop];
    
    XCTAssertFalse(_client.queueIsEmpty, @"Event queue should not be empty");
}

- (void)testEventIsRequeuedWhen500 {
    PNEventMilestone *event = [[PNEventMilestone alloc] initWithSessionInfo:_sessionInfo];
    //get this for the stub
    NSString *eventUrl = [PNEventApiClient buildUrlWithBase:[_session getEventsUrl] withPath:event.baseUrlPath withParams:event.eventParameters];
    stubRequest(@"GET", eventUrl).andReturn(500);
    
    [_client enqueueEventUrl:eventUrl];
    
    [_client start];
    [_client stop];
    
    XCTAssertFalse(_client.queueIsEmpty, @"Event queue should not be empty");
}

@end
