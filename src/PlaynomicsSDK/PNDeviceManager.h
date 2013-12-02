//
//  PNUserInfo.h
//  iosapi
//
//  Created by Shiraz Khan on 8/6/13.
//
//

#import <Foundation/Foundation.h>
#import "PNCache.h"
@interface PNDeviceManager : NSObject
- (id) initWithCache: (PNCache *) cache;
- (BOOL) syncDeviceSettingsWithCache;
- (NSString *) generateUserId;
@end
