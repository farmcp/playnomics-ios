//
// Created by jmistral on 10/3/12.
//

#import "PNMessaging.h"
#import "PNSession.h"
#import "PNMessagingApiClient.h"

@implementation PNMessaging{
    PNSession *_session;
    PNMessagingApiClient *_apiClient;
    NSMutableDictionary *_framesById;
}

- (id) initWithSession: (PNSession *) session {
    if((self = [super init])){
        _session = session;
        _apiClient = [[PNMessagingApiClient alloc] initWithSession: session];
        
        _framesById = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    _session = nil;
    [_framesById release];
    [_apiClient release];
    [super dealloc];
}

- (void) fetchDataForFrame:(NSString *) frameId{
    PNFrame *frame = [self getOrAddFrame:frameId];
    [_apiClient loadDataForFrame:frame];
}

- (void) showFrame:(NSString *) frameId
            inView:(UIView *) parentView
      withDelegate:(id<PlaynomicsBasePlacementDelegate>) delegate{
    
    PNFrame *frame = [self getOrAddFrame: frameId];
    if(!(frame.state == PNFrameStateLoadingComplete || frame.state == PNFrameStateLoadingStarted)){
        [_apiClient loadDataForFrame:frame];
    }
    [frame showInView:parentView withDelegate:delegate];
}

- (id) getOrAddFrame: (NSString *) frameId{
    PNFrame *frame = [_framesById valueForKey:frameId];
    if(!frame){
        frame = [[[PNFrame alloc] initWithFrameId:frameId session:_session messaging:self] autorelease];
        [_framesById setValue:frame forKey:frameId];
    }
    return frame;
}

-(void) hideFrame: (NSString *) frameId{
    PNFrame *frame = [_framesById valueForKey:frameId];
    if(!frame){
        [frame hide];
    }
}


@end