//
//  PNWebView.m
//  iosapi
//
//  Created by Shiraz Khan on 8/26/13.
//
//

#import "PNWebView.h"

@implementation PNWebView {
@private
    CGRect _backgroundDimensions;
    PNViewComponent *_closeButton;
    id<PNFrameDelegate> _delegate;
    PNFrameResponse *_response;
}

@synthesize status = _status;

#pragma mark - Lifecycle/Memory management
-(id) initWithResponse:(PNFrameResponse *) response delegate:(id<PNFrameDelegate>) delegate {
    if (self = [super init]) {
        [self setUserInteractionEnabled: YES];
        [self setExclusiveTouch: YES];
        _response = [response retain];
        _delegate = delegate;
        
        [super setDelegate:self];
        
        if(_response.htmlContent != nil && _response.htmlContent != (id)[NSNull null]){
            _status = AdComponentStatusPending;
            
            if (_response.fullscreen && [_response.fullscreen boolValue] == YES) {
                [super setFrame:[PNUtil getScreenDimensionsInView]];
            } else {
                [super setFrame:_backgroundDimensions];
            }
            
            // Close button should only be non-nil for 3rd party ads
            if(_response.closeButtonType == CloseButtonNative && _response.closeButtonImageUrl != nil){
                CGRect dimensions = [self getFrameForCloseButton];
                _closeButton = [[PNViewComponent alloc] initWithDimensions:dimensions delegate:self image:_response.closeButtonImageUrl];
                if(_closeButton !=  nil){
                    [self addSubview:_closeButton];
                }
            }
            
            self.scrollView.scrollEnabled = NO;
            self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self loadHTMLString:_response.htmlContent baseURL:nil];
        }
    }
    
    return self;
}

-(CGRect) getFrameForCloseButton{
    //always place the close button in the top right of the web view
    [PNLogger log:PNLogLevelDebug format:@"Frame width %f height %f x %f y %f", [super frame].size.width, [super frame].size.height,
     [super frame].origin.x, [super frame].origin.y];
    
    float padding = 5.0;
    return CGRectMake([super frame].size.width - (_response.closeButtonDimensions.size.width + padding), padding,
                      _response.closeButtonDimensions.size.width,
                      _response.closeButtonDimensions.size.height);
}

-(void) renderAdInView:(UIView *)parentView {
    [super setFrame:[PNUtil getScreenDimensionsInView]];
    
    if(_closeButton){
        _closeButton.frame = [self getFrameForCloseButton];
    }
    
    int lastDisplayIndex = parentView.subviews.count;
    [parentView insertSubview:self atIndex:lastDisplayIndex+1];
    //[super setFrame: parentView.bounds];
}

-(void) hide{
    [self removeFromSuperview];
    [_delegate adClosed:NO];
}

-(void) rotate{
    [super setFrame:[PNUtil getScreenDimensionsInView]];
    if(_closeButton){
        _closeButton.frame = [self getFrameForCloseButton];
    }
}

-(void)dealloc{
    _delegate = nil;
    [_response release];
    [_closeButton release];
    [super dealloc];
}

#pragma mark "Helper Methods"
// Returns TRUE if all instantiated components are done loading. FALSE otherwise
- (BOOL) _allComponentsLoaded {
    return _status == AdComponentStatusCompleted && _closeButton.status == AdComponentStatusCompleted;
}

-(void) _closeAd {
    [self removeFromSuperview];
    [_delegate adClosed:YES];
}

#pragma mark "Delegate Handlers"
-(BOOL) webView:(UIWebView*) webView shouldStartLoadWithRequest:(NSURLRequest *) request
 navigationType:(UIWebViewNavigationType) navigationType {
    NSURL *url = [request URL];
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [self removeFromSuperview];
        if (_response.closeButtonLink &&  [_response.closeButtonLink isEqualToString: url.absoluteString]){
            [PNLogger log:PNLogLevelDebug format:@"PN Web View Close button was clicked"];
            [_delegate adClosed:YES];
        } else if (_response.clickLink && [_response.clickLink isEqualToString:url.absoluteString]){
            [PNLogger log:PNLogLevelDebug format:@"PN Web View Ad was clicked"];
            [_delegate adClicked];
        } else {
            [PNLogger log:PNLogLevelDebug format:@"Web View was clicked"];
            
            if([[UIApplication sharedApplication] canOpenURL:url]){
                [[UIApplication sharedApplication] openURL:url];
            }
            [_delegate adClicked];
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _status = AdComponentStatusCompleted;
    if(_closeButton){
        //third party ad, use a native opacity
        [self setBackgroundColor:[UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:.40f]];
        [self setOpaque:NO];
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
    }
    [_delegate didLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    _status = AdComponentStatusError;
    [PNLogger log:PNLogLevelWarning error:error format:@"Could not load the webview for HTML Content %@", _response.htmlContent];
    [_delegate didFailToLoadWithError:error];
}
// Only notify the delegate if all the components have been loaded successfully
- (void) componentDidLoad {
    if([self _allComponentsLoaded]){
        [_delegate didLoad];
    }
}

- (void)componentDidFailToLoad{
    [self removeFromSuperview];
    [_delegate didFailToLoad];
}

// Close the ad in case of an error and notify the delegate
-(void) componentDidFailToLoadWithError: (NSError*) error {
    [self removeFromSuperview];
    [_delegate didFailToLoadWithError:error];
}

// Close the ad in case of an exception and notify the delegate
-(void) componentDidFailToLoadWithException: (NSException*) exception {
    [self removeFromSuperview];
    [_delegate didFailToLoadWithException:exception];
}

// If the close button component was clicked, close the ad and notify the delegate
// If the ad was clicked, also close the ad and notify the delegate
-(void) component: (id) component didReceiveTouch: (UITouch*) touch {
    if (component == _closeButton) {
        [PNLogger log: PNLogLevelDebug format: @"Close button was pressed..."];
        [self _closeAd];
    }
}

@end
