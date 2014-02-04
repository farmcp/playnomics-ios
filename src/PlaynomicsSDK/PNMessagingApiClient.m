//
//  PNMessagingApiClient.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/6/13.
//
//

#import "PNEventApiClient.h"
#import "PNMessagingApiClient.h"
#import <AdSupport/AdSupport.h>

@implementation PNMessagingApiClient{
    PNSession *_session;
    NSMutableDictionary *_requestsByUrl;
}

@synthesize idfa;
@synthesize limitAdvertising;

-(id) initWithSession:(PNSession *) session{
    self = [super init];
    if(self){
        _session = session;
        _requestsByUrl = [[NSMutableDictionary alloc] init];
    }
    
    if(NSClassFromString(@"ASIdentifierManager")){
        ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
        self.idfa = [manager.advertisingIdentifier UUIDString];
        self.limitAdvertising = manager.isAdvertisingTrackingEnabled;
    }
    
    // If we ever want to cache the IDFA, uncomment this code
    /*
     UIPasteboard *playnomicsPasteboard = [UIPasteboard pasteboardWithName:PNPasteboardName create:YES];
     playnomicsPasteboard = YES;
     if([[playnomicsPasteboard items] count] > 0){
     NSDictionary *data = [[playnomicsPasteboard items] objectAtIndex:0];
     self.idfa = [self deserializeStringFromData:data key:PNPasteboardLastIDFA];
     
     self.limitAdvertising = [PNUtil stringAsBool: [self deserializeStringFromData:data key:PNPasteboardLastLimitAdvertising]];
     }
     */
    // If we ever want to write to the cache, uncomment this code
    /*
     if(_idfaChanged || _limitAdvertisingChanged){
     UIPasteboard *playnomicsPasteboard = [self getPlaynomicsPasteboard];
     NSMutableDictionary *pasteboardData = ([[playnomicsPasteboard items] count] == 1) ?
     [[playnomicsPasteboard items] objectAtIndex:0] :
     [[NSMutableDictionary new] autorelease];
     
     
     [pasteboardData setValue:self.idfa forKey:PNPasteboardLastIDFA];
     [pasteboardData setValue:[PNUtil boolAsString: self.limitAdvertising] forKey: PNPasteboardLastLimitAdvertising];
     
     playnomicsPasteboard.items = [[[NSArray alloc] initWithObjects:pasteboardData, nil] autorelease];
     }
     */
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
    
    if(_session.cache.getIdfv){
        [params setObject:_session.cache.getIdfv forKey:@"idfv"];
    }
    if(self.idfa){
        [params setObject:self.idfa forKey:@"idfa"];
    }
    [params setObject:[PNUtil boolAsString:!self.limitAdvertising] forKey:@"allowTracking"];
    
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
