//
//  PNUserInfo.m
//  iosapi
//
//  Created by Shiraz Khan on 8/6/13.
//
//

#import "PNDeviceInfo.h"
#import "PNDeviceInfo+Private.h"
#import "PNCache.h"
#import <AdSupport/AdSupport.h>


@implementation PNDeviceInfo{
    PNCache *_cache;
}

- (id) initWithCache: (PNCache *) cache {
    if ((self = [super init])) {
        _cache = cache;
    }
    return self;
}

- (BOOL) syncDeviceSettingsWithCache {    
    if(![_cache getBreadcrumbID]){
        [_cache updateBreadcrumbID: [self generateBreadcrumbId]];
    }
    
    if (NSClassFromString(@"ASIdentifierManager")) {
        [_cache updateLimitAdvertising: ![self isAdvertisingTrackingEnabledFromDevice]];
        [_cache updateIdfa:[[self getAdvertisingIdentifierFromDevice] UUIDString]];
    } else {
        [PNLogger log:PNLogLevelWarning format: @"No Advertising Information available so this must be a pre-iOS 6 device"];
    }

    UIDevice* currentDevice = [UIDevice currentDevice];
                                        
    if ([currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        [_cache updateIdfv: [[self getVendorIdentifierFromDevice] UUIDString]];
    }
    return _cache.breadcrumbIDChanged || _cache.idfaChanged || _cache.idfvChanged || _cache.limitAdvertisingChanged;
}

- (NSString *) generateBreadcrumbId {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *breadcrumb = [(NSString *) CFUUIDCreateString(NULL, uuidRef) autorelease];
    CFRelease(uuidRef);
    return breadcrumb;
}

- (BOOL) isAdvertisingTrackingEnabledFromDevice {
    ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
    return manager.isAdvertisingTrackingEnabled;
}

- (NSUUID *) getAdvertisingIdentifierFromDevice {
    ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
    return manager.advertisingIdentifier;
}

- (NSUUID *) getVendorIdentifierFromDevice {
    return [[UIDevice currentDevice] identifierForVendor];
}

@end