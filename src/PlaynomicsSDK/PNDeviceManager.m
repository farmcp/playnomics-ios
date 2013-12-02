//
//  PNDeviceManager.m
//  iosapi
//
//  Created by Shiraz Khan on 8/6/13.
//
//
#import "PNDeviceManager.h"
#import "PNDeviceManager+Private.h"
#import "PNCache.h"
#import <AdSupport/AdSupport.h>

@implementation PNDeviceManager{
    PNCache *_cache;
}

- (id) initWithCache: (PNCache *) cache {
    if ((self = [super init])) {
        _cache = [cache retain];
    }
    return self;
}

- (void) dealloc {
    [_cache release];
    [super dealloc];
}

- (BOOL) syncDeviceSettingsWithCache {
    if (NSClassFromString(@"ASIdentifierManager")) {
        [_cache updateLimitAdvertising: ![self isAdvertisingTrackingEnabledFromDevice]];
        [_cache updateIdfa:[self getAdvertisingIdentifierFromDevice]];
    } else {
        [PNLogger log:PNLogLevelWarning format: @"No Advertising Information available so this must be a pre-iOS 6 device"];
    }

    UIDevice* currentDevice = [UIDevice currentDevice];
    if ([currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        [_cache updateIdfv: [self getVendorIdentifierFromDevice]];
    }
    return _cache.idfaChanged || _cache.idfvChanged || _cache.limitAdvertisingChanged;
}

- (NSString *) generateUserId {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *userId = [(NSString *) CFUUIDCreateString(NULL, uuidRef) autorelease];
    CFRelease(uuidRef);
    return userId;
}

- (BOOL) isAdvertisingTrackingEnabledFromDevice {
    ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
    return manager.isAdvertisingTrackingEnabled;
}

- (NSString *) getAdvertisingIdentifierFromDevice {
    if(NSClassFromString(@"ASIdentifierManager")){
        ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
        return [manager.advertisingIdentifier UUIDString];
    }
    return nil;
}

- (NSString *) getVendorIdentifierFromDevice {
    if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]){
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return nil;
}

@end