//
//  PNAssetRequest.h
//  iosapi
//
//  Created by Jared Jenkins on 9/6/13.
//
//

#import <Foundation/Foundation.h>


@protocol PNAssetRequestDelegate <NSObject>


@required
-(void) connectionDidFail;
-(void) requestDidFailWithError: (NSError *) error;
-(void) requestDidFailtWithStatusCode: (int) statusCode;
-(void) requestDidCompleteWithData: (NSData *) data;
@end

@interface PNAssetRequest : NSObject<NSURLConnectionDataDelegate>
- (id) initWithUrl: (NSString *)urlString delegate:(id<PNAssetRequestDelegate>) delegate useHttpCache:(BOOL) useHttpCache;
-(void) start;
@end
