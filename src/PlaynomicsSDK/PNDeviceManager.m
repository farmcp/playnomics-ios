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
    UIDevice* currentDevice = [UIDevice currentDevice];
    if ([currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        [_cache updateIdfv: [self getVendorIdentifierFromDevice]];
    }
    return _cache.idfvChanged;
}

- (NSString *) generateUserId {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *userId = [(NSString *) CFUUIDCreateString(NULL, uuidRef) autorelease];
    CFRelease(uuidRef);
    return userId;
}

- (NSString *) getVendorIdentifierFromDevice {
    if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]){
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return nil;
}

@end