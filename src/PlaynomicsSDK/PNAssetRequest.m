//
//  PNAssetRequest.m
//  iosapi
//
//  Created by Jared Jenkins on 9/6/13.
//
//

#import "PNAssetRequest.h"
@implementation PNAssetRequest{
    NSMutableData* _responseData;
    NSURLConnection* _connection;
    id<PNAssetRequestDelegate> _delegate;
}


+(id) loadDataForUrl: (NSString *)urlString
              delegate: (id<PNAssetRequestDelegate>) delegate
          useHttpCache: (BOOL) useHttpCache
{
    return [[PNAssetRequest alloc] initWithUrl:urlString delegate:delegate useHttpCache:useHttpCache];
}

- (id) initWithUrl: (NSString *)urlString
          delegate: (id<PNAssetRequestDelegate>) delegate
      useHttpCache: (BOOL) useHttpCache{
    if((self = [super init])){
        _delegate = delegate;
    
        const double timeOut = 3 * 60;
        NSURL *url = [NSURL URLWithString: urlString];
        
        NSURLRequest *request = [NSURLRequest requestWithURL: url
                                                 cachePolicy: useHttpCache ? NSURLCacheStorageAllowed : NSURLCacheStorageNotAllowed
                                             timeoutInterval: timeOut];
        
        _connection = [[NSURLConnection alloc] initWithRequest:request
                                                      delegate:self
                                              startImmediately:NO];
    }
    return self;
}

- (void) dealloc{
    [_connection release];
    [_responseData release];
    
    [super dealloc];
}

- (void) start{
    [_connection start];
    if(_connection){
        _responseData = [[NSMutableData data] retain];
    } else {
        [_delegate connectionDidFail];
    }
}

-(void) cancel {
    if(_connection){
        [_connection cancel];
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_responseData appendData:data];
}

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

    if([httpResponse statusCode] != 200){
        [connection cancel];
        [_delegate requestDidFailWithStatusCode: (int)[httpResponse statusCode]];
    }
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *)error{
    [_delegate requestDidFailWithError:error];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection{
    NSData *data = [[[NSData alloc] initWithData:_responseData] autorelease];
    [_delegate requestDidCompleteWithData: data];
}
@end
