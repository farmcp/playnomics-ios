
//
//  PNPlayerSessionInfo.m
//  iosapi
//
//  Created by Jared Jenkins on 8/28/13.
//
//

#import "PNGameSessionInfo.h"

@implementation PNGameSessionInfo

@synthesize applicationId = _applicationId;
@synthesize userId = _userId;
@synthesize idfv = _idfv;
@synthesize sessionId = _sessionId;

-(id) initWithApplicationId:(unsigned long long)applicationId
                     userId:(NSString *) userId
                       idfv:(NSString *) idfv
                  sessionId:(PNGeneratedHexId *)sessionId{
    if((self = [super init])){
        _applicationId = [NSNumber numberWithUnsignedLongLong: applicationId];
        _userId = [userId copy];
        if(idfv) {
            _idfv = [idfv copy];
        }
        _sessionId = [sessionId retain];
     }
    return self;
}
@end
