//
//  PNEventRequestOperation.m
//  iosapi
//
//  Created by Jared Jenkins on 8/29/13.
//
//

#import "PNEventRequestOperation.h"

@implementation PNEventRequestOperation{
    BOOL _executing;
    BOOL _finished;
    id<PNUrlProcessorDelegate> _delegate;
}

@synthesize urlPath=_urlPath;
@synthesize successful=_successful;

- (id) initWithUrl : (NSString *) urlPath delegate : (id<PNUrlProcessorDelegate>) delegate {
    if((self = [super init])){
        _urlPath = [urlPath retain];
        _finished = NO;
        _delegate = delegate;
    }
    return self;
}

- (BOOL) isFinished {
    return _finished;
}

-(void) setIsFinished:(BOOL) value{
    @synchronized(self){
        _finished = value;
    }
}

- (void) start {
    //check for cancellation before launching the task.
    if ([self isCancelled]){
        [PNLogger log:PNLogLevelDebug format:@"Request has been cancelled %@", _urlPath];
        
        //move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        [self setIsFinished: YES];
        [_delegate onDidFailToProcessUrl:_urlPath tryAgain:NO];
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    NSURL *url = [[[NSURL alloc] initWithString: self.urlPath] autorelease];
    NSURLRequest *request = [[[NSURLRequest alloc]
                              initWithURL:url
                              cachePolicy:NSURLCacheStorageNotAllowed
                              timeoutInterval:PNPropertyConnectionTimeout] autorelease];
    
    NSURLResponse *response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];
    if(error){
        [PNLogger log:PNLogLevelDebug
               format:@"Request for %@ completed with error %@", _urlPath, error.description];
        [_delegate onDidFailToProcessUrl:_urlPath tryAgain:YES];
        
        if([error code] == NSURLErrorNotConnectedToInternet ||
           [error code] == NSURLErrorCannotConnectToHost ||
           [error code] == NSURLErrorNetworkConnectionLost){
            [_delegate onConnectionUnavailable];
        }
    } else {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;
        
        int statusCode = [httpResponse statusCode];
        [PNLogger log:PNLogLevelDebug
               format:@"Request for %@ completed with status code %d", _urlPath, statusCode];
        
        BOOL serverSideError = statusCode >= 500;
        if(statusCode == 200){
            [_delegate onDidProcessUrl: _urlPath];
        } else {
            //only retry requests where we have a server side error
            [_delegate onDidFailToProcessUrl:_urlPath tryAgain:serverSideError];
        }
    }
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self setIsFinished: YES];
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end
