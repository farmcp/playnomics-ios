//
// Created by jmistral on 10/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "PlaynomicsFrame+Exposed.h"
#import "Playnomics.h"

@interface PlaynomicsMessaging : NSObject
- (PlaynomicsFrame *) createFrameWithId:(NSString*)frameId frameDelegate: (id<PNFrameDelegate>)frameDelegate;
- (PlaynomicsFrame *) createFrameWithId:(NSString*) frameId;
@end