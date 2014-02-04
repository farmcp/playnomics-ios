#import "PNEvent.h"
#import "PNUtil.h"

@implementation PNEvent
@synthesize eventParameters=_eventParameters;
@synthesize eventTime=_eventTime;

- (id) initWithSessionInfo: (PNGameSessionInfo *) info{
    if((self = [super init])){
        _eventTime = [[NSDate date] timeIntervalSince1970];
        _eventParameters = [[NSMutableDictionary alloc] init];
        
        [_eventParameters setValue: [NSNumber numberWithLongLong: (_eventTime * 1000)] forKey: PNEventParameterTimeStamp];
        [_eventParameters setValue: info.applicationId forKey: PNEventParameterApplicationId];
        [_eventParameters setValue: info.userId forKey: PNEventParameterUserId];
        
        if(info.idfv) {
            [_eventParameters setValue: info.idfv forKey: PNEventParameterIdfv];
        }
        
        [_eventParameters setValue: @"ios" forKey: PNEventParameterSdkName];
        [_eventParameters setValue: PNPropertyVersion forKey: PNEventParameterSdkVersion];
        
        [_eventParameters setValue:[info.sessionId toHex] forKey: [self sessionKey]];
    }
    return self;
}

- (id) initWithSessionInfo: (PNGameSessionInfo *) info instanceId: (PNGeneratedHexId *) instanceId{
    self = [self initWithSessionInfo:info];
    [self appendParameter:[instanceId toHex] forKey:@"i"];
    return self;
}

- (void) appendParameter: (id) value  forKey:(NSString *) key{
    if(value && key){
        //only append parameters when the key and value are both not nil
        [_eventParameters setValue: value forKey: key];
    }
}

- (NSString*) sessionKey{
    @throw ([NSException exceptionWithName:@"UnimplementedMethodException" reason:@"This method is abstract and should be overridden by a subclass of PNEvent" userInfo:nil]);
}

- (NSString *) baseUrlPath{
   @throw ([NSException exceptionWithName:@"UnimplementedMethodException" reason:@"This method is abstract and should be overridden by a subclass of PNEvent" userInfo:nil]);
}

- (void) dealloc {
    [_eventParameters release];
    [super dealloc];
}
@end