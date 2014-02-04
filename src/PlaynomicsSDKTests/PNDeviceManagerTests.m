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

-(id) mockCurrentDeviceInfo:(PNDeviceManager*) deviceInfo idfv: (NSString *) currentIdfv {
    id mock = [OCMockObject partialMockForObject:deviceInfo];
    
    [[[mock stub] andReturn: currentIdfv] getVendorIdentifierFromDevice];
    
    return mock;
}


- (void) testGetDeviceInfoFromDevice {
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfv:idfv];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];

    //the device settings have not changed
    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    info = [self mockCurrentDeviceInfo: info idfv: idfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertFalse(dataChanged, @"No data should have changed");
    
    //use isEqualToString for string comparison
    XCTAssertTrue([[mockCache getIdfv] isEqual: idfv], @"IDFV should be loaded from cache");
    XCTAssertFalse([mockCache idfvChanged], @"IDFA should not have changed.");
}

- (void) testDeviceInfoWithNewDevice{
    NSString *idfv = nil;
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfv:idfv];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];

    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];

    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    info = [self mockCurrentDeviceInfo: info idfv: currentIdfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertTrue(dataChanged, @"Cached device data should have changed");
    
    //use isEqualToString for string comparison
    XCTAssertTrue([[mockCache getIdfv] isEqual: currentIdfv], @"IDFV should be set from device.");
    XCTAssertTrue([mockCache idfvChanged], @"IDFA should have changed.");
}

-(void) testDeviceInfoUpdatesStaleValues{
    NSString *idfv = [[[NSUUID alloc] init] UUIDString];
    
    StubPNCache *cache = [[StubPNCache  alloc] initWithIdfv:idfv];
    id mockCache = [cache getMockCache];
    [cache loadDataFromCache];
    
    NSString *currentIdfv = [[[NSUUID alloc] init] UUIDString];
    
    PNDeviceManager *info = [[PNDeviceManager alloc] initWithCache: mockCache];
    
    info = [self mockCurrentDeviceInfo: info idfv: currentIdfv];
    
    BOOL dataChanged = [info syncDeviceSettingsWithCache];
    //Verify no data has changed
    XCTAssertTrue(dataChanged, @"Cached device data should have changed");
    
    XCTAssertTrue([[mockCache getIdfv] isEqual: currentIdfv], @"IDFV should be updated.");
    XCTAssertTrue([mockCache idfvChanged], @"IDFA should be updated.");
}


@end
