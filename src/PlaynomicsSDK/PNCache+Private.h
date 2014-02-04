//
//  PNCache+Testing.h
//  iosapi
//
//  Created by Jared Jenkins on 8/27/13.
//
//

@interface PNCache()
@property (copy) NSString *idfv;
@property (retain) PNGeneratedHexId *lastSessionId;
@property (copy) NSString *lastUserId;
@property (assign) NSTimeInterval lastEventTime;
@property (copy) NSString* deviceToken;
@end