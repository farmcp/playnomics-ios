#import <Foundation/Foundation.h>

#import "PNEvent.h"
#import "PNSession.h"
#import "PNUrlProcessorDelegate.h"

@interface PNEventApiClient : NSObject<PNUrlProcessorDelegate>

@property (readonly, getter = isEmpty) BOOL queueIsEmpty;

- (id) initWithSession: (PNSession *) session;
- (void) enqueueEvent: (PNEvent *) event;
- (void) enqueueEventUrl: (NSString *) url;

+ (NSString *) buildUrlWithBase: (NSString *) base
                       withPath: (NSString *) path
                     withParams: (NSDictionary *) params;

- (NSSet *) getAllUnprocessedUrls;
//queue processing
- (void) start;
- (void) pause;
- (void) stop;
@end
