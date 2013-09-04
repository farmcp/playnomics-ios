//
//  PNEventRequestOperation.h
//  iosapi
//
//  Created by Jared Jenkins on 8/29/13.
//
//

#import <Foundation/Foundation.h>
#import "PNUrlProcessorDelegate.h"

@interface PNEventRequestOperation : NSOperation<NSURLConnectionDataDelegate>

@property (readonly) NSString *urlPath;
@property (readonly) BOOL successful;

- (id) initWithUrl : (NSString *) urlPath delegate : (id<PNUrlProcessorDelegate>) delegate;
@end
