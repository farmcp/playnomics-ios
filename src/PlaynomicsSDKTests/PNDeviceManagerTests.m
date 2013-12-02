//
//  PlaynomicsSDKTests.m
//  PlaynomicsSDKTests
//
//  Created by Jared Jenkins on 8/22/13.
//
//


#import "StubPNCache.h"

#import <AdSupport/AdSupport.h>

#import "PNConstants.h"
#import "PNDeviceManager.h"
#import "PNDeviceManager+Private.h"

#import <XCTest/XCTest.h>
@interface PNDeviceManagerTests : XCTestCase
@end

@implementation PNDeviceManagerTests

-(void) setUp
{
    [super setUp];
}

-(void) tearDown
{
    // Tear-down code here.
    [super tearDown];
}

-(id) mockCurrentDeviceInfo:(PNDeviceManager*) deviceInfo idfa: (NSString *) currentIdfa limitAdvertising : (BOOL) limitAdvertising idfv: (NSString *) currentIdfv {
    
    id mock = [OCMockObject partialMockForObject:deviceInfo];
    
    BOOL isAdvertisingEnabled = !limitAdvertising;
    [[[mock stub] andReturnValue: OCMOCK_VALUE(isAdvertisingEnabled)] isAdvertisingTrackingEnabledFromDevice];
    [[[mock stub] andReturn: currentIdfa] getAdvertisingIdentifierFromDevice];
    [[[mock stub] andReturn: currentIdfv] getVendorIdentifierFromDevice];
    
    return mock;
}


- (void) testGetDeviceInfoFromDevice {
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];

    //the device settings have not changed
    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    info = [self mockCurrentDeviceInfo: info idfa: idfa limitAdvertising: limitAdvertising idfv: idfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertFalse(dataChanged, @"No data should have changed");
    
    //use isEqualToString for string comparison
    XCTAssertTrue([[mockCache getIdfa] isEqual: idfa], @"IDFA should be loaded from cache");
    XCTAssertFalse([mockCache idfaChanged], @"IDFA should not have changed.");

    XCTAssertTrue([[mockCache getIdfv] isEqual: idfv], @"IDFV should be loaded from cache");
    XCTAssertFalse([mockCache idfvChanged], @"IDFA should not have changed.");

    XCTAssertEqual([mockCache getLimitAdvertising], limitAdvertising, @"Limit advertising should be loaded from cache");
    XCTAssertFalse([mockCache limitAdvertisingChanged], @"Limit advertising should not have changed.");
}

- (void) testDeviceInfoWithNewDevice{
    NSString *idfa = nil;
    BOOL limitAdvertising = NO;
    NSString *idfv = nil;
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];

    NSString *currentIdfa = [[[NSUUID alloc] init] UUIDString];
    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];
    BOOL newlimitAdvertising  = YES;

    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    info = [self mockCurrentDeviceInfo: info idfa: currentIdfa limitAdvertising: newlimitAdvertising idfv: currentIdfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertTrue(dataChanged, @"Cached device data should have changed");
    
    //use isEqualToString for string comparison
    XCTAssertTrue([[mockCache getIdfa] isEqual: currentIdfa], @"IDFA should be set from device.");
    XCTAssertTrue([mockCache idfaChanged], @"IDFA should have changed.");
    
    XCTAssertTrue([[mockCache getIdfv] isEqual: currentIdfv], @"IDFV should be set from device.");
    XCTAssertTrue([mockCache idfvChanged], @"IDFA should have changed.");
    
    XCTAssertEqual([mockCache getLimitAdvertising], newlimitAdvertising, @"Limit advertising should be set from device.");
    XCTAssertTrue([mockCache idfvChanged], @"Limit advertising should have changed.");
}

-(void) testDeviceInfoUpdatesStaleValues{
    NSString *idfa = [[[NSUUID alloc] init] UUIDString];
    BOOL limitAdvertising = NO;
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfa:idfa idfv:idfv limitAdvertising:limitAdvertising];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];
    
    NSString *currentIdfa = [[[NSUUID alloc] init] UUIDString];
    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];
    BOOL newlimitAdvertising  = YES;
    
    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    
    info = [self mockCurrentDeviceInfo: info idfa: currentIdfa limitAdvertising: newlimitAdvertising idfv: currentIdfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertTrue(dataChanged, @"Cached device data should have changed");
    
    XCTAssertTrue([[mockCache getIdfa] isEqual: currentIdfa], @"IDFA should be updated.");
    XCTAssertTrue([mockCache idfaChanged], @"IDFA should be updated.");
    
    XCTAssertTrue([[mockCache getIdfv] isEqual: currentIdfv], @"IDFV should be updated.");
    XCTAssertTrue([mockCache idfvChanged], @"IDFA should be updated.");
    
    XCTAssertEqual([mockCache getLimitAdvertising], newlimitAdvertising, @"Limit advertising should be updated.");
    XCTAssertTrue([mockCache limitAdvertisingChanged], @"Limit advertising should be updated.");
}


@end
