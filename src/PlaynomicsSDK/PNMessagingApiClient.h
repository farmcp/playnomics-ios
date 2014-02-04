//
//  PNMessagingApiClient.h
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/6/13.
//
//

#import <Foundation/Foundation.h>
#import "PNSession.h"
#import "PNFrame.h"
#import "PNFrameRequest.h"

@interface PNMessagingApiClient : NSObject<PNFrameRequestDelegate>

@property (copy) NSString *idfa;
@property (assign) BOOL limitAdvertising;

-(id) initWithSession:(PNSession *) session;
-(void) loadDataForFrame:(PNFrame *) frame;

@end
