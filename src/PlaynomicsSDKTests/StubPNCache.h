//
//  MockPNCache.h
//  iosapi
//
//  Created by Jared Jenkins on 8/27/13.
//
//

#import "PNGeneratedHexId.h"
#import "StubDeviceToken.h"


@interface StubPNCache : NSObject

-(id) initWithIdfv: (NSString *) idfv;

-(id) initWithIdfv: (NSString *) idfv
     lastEventTime: (NSTimeInterval) lastEventTime
        lastUserId: (NSString *)lastUserId
     lastSessionId: (PNGeneratedHexId *) sessionId;

-(id) initWithIdfv: (NSString *) idfv
       deviceToken:(StubDeviceToken *) token;

-(void) loadDataFromCache;
-(void) writeDataToCache;
-(id) getMockCache;
@end
