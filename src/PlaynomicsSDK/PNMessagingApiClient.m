//
//  PNMessagingApiClient.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/6/13.
//
//

#import "PNEventApiClient.h"
#import "PNMessagingApiClient.h"

@implementation PNMessagingApiClient{
    PNSession *_session;
    NSMutableDictionary *_requestsByUrl;
}

-(id) initWithSession:(PNSession *) session{
    self = [super init];
    if(self){
        _session = session;
        _requestsByUrl = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void) loadDataForFrame:(PNFrame *) frame{
    CGRect screenRect = [PNUtil getScreenDimensions];
    
    long long timeInMilliseconds = ([[NSDate date] timeIntervalSince1970] * 1000);
    
    NSNumber *requestTime = [NSNumber numberWithLongLong: timeInMilliseconds];
    
    NSNumber * applicationId = [NSNumber numberWithUnsignedLongLong:_session.applicationId];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:applicationId  forKey:@"a"];
    [params setObject:_session.userId forKey:@"u"];
    [params setObject:requestTime forKey:@"t"];
    [params setObject:@"ios" forKey:@"esrc"];
    [params setObject:_session.sdkVersion forKey:@"ever"];
    [params setObject:frame.frameId forKey:@"f"];
    [params setObject:[NSNumber numberWithInt: screenRect.size.height] forKey:@"c"];
    [params setObject:[NSNumber numberWithInt: screenRect.size.width] forKey:@"d"];
    
    if(_session.cache.getIdfa){
        [params setObject:_session.cache.getIdfa forKey:@"idfa"];
    }
    if(_session.cache.getIdfv){
        [params setObject:_session.cache.getIdfv forKey:@"idfv"];
    }
    [params setObject:[PNUtil boolAsString:!_session.cache.getLimitAdvertising] forKey:@"allowTracking"];
    
    NSString *language = [PNUtil getLanguage];
    if (language) {
        [params setObject:language forKey:@"lang"];
    }
    
    NSString *url = [PNEventApiClient buildUrlWithBase:[_session getMessagingUrl]
                                     withPath:@"ads"
                                    withParams:params];
    
    PNFrameRequest *request = [[PNFrameRequest alloc] initWithFrame:frame url:url delegate:self];
    [request fetchFrameData];
    [_requestsByUrl setValue:request forKey:url];
    [request autorelease];
    [params autorelease];
}

-(void) onFrameUrlCompleted:(NSString *)url{
    [_requestsByUrl removeObjectForKey:url];
}
@end
