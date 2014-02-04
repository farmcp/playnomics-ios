//
//  PNCache.h
//  iosapi
//
//  Created by Jared Jenkins on 8/26/13.
//
//

#import <Foundation/Foundation.h>
#import "PNGeneratedHexId.h"

@interface PNCache : NSObject

@property (readonly) BOOL  idfvChanged;

- (NSString *) getIdfv;
- (void) updateIdfv : (NSString *) value;

- (PNGeneratedHexId *) getLastSessionId;
- (void) updateLastSessionId: (PNGeneratedHexId *) value;

- (NSString *) getLastUserId;
- (void) updateLastUserId: (NSString *) value;

- (NSTimeInterval) getLastEventTime;
- (void) updateLastEventTimeToNow;

- (NSString *) getDeviceToken;
- (void) updateDeviceToken: (NSString *) value;

// I/O cache methods
- (void) loadDataFromCache;
- (void) writeDataToCache;
@end
