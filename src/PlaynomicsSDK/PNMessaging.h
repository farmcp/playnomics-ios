//
// Created by jmistral on 10/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "Playnomics.h"
#import "PNSession.h"

@interface PNMessaging : NSObject

- (id) initWithSession:(PNSession *) session;

- (void) fetchDataForFrame:(NSString *) frameId;

- (void) showFrame:(NSString *) frameId
            inView:(UIView *) parentView
      withDelegate:(id<PlaynomicsBasePlacementDelegate>) delegate;

-(void) hideFrame:(NSString *) frameId;

@end
