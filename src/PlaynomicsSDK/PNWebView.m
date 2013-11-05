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
    PNNativeViewComponent *_closeButtonView;
    id<PNFrameDelegate> _delegate;
    id _closeButton;
    PNHtmlAd *_htmlAd;
}

@synthesize status = _status;

#pragma mark - Lifecycle/Memory management

-(id)     initWithAd:(PNHtmlAd *) ad
     htmlCloseButton:(PNHtmlCloseButton *) htmlCloseButton
            delegate:(id<PNFrameDelegate>) delegate
{
    if ((self = [super init])) {
        _status = AdComponentStatusPending;
        _closeButton = [htmlCloseButton retain];
        [self setViewData:ad delegate:delegate];
    }
    return self;
}

-(id)  initWithAd:(PNHtmlAd *) ad
nativeCloseButton:(PNNativeCloseButton *)nativeCloseButton
         delegate:(id<PNFrameDelegate>)delegate{
    
    if ((self = [super init])) {
        _status = AdComponentStatusPending;
        [self setViewData:ad delegate:delegate];
        _closeButton = [nativeCloseButton retain];
        
        _closeButtonView = [[PNNativeViewComponent alloc] initWithDimensions:nativeCloseButton.dimensions
                                                          delegate:self
                                                             image:nativeCloseButton.imageUrl];
        [self addSubview:_closeButtonView];
    }
    return self;
}

-(void) setViewData:(PNHtmlAd *) htmlAd delegate:(id<PNFrameDelegate>) delegate{
    _htmlAd = [htmlAd retain];
    
    //will need to be refactored to handle the framed webview use-case
    [super setFrame:[PNUtil getScreenDimensionsInView]];
    
    [super setDelegate:self];
    [self setUserInteractionEnabled: YES];
    [self setExclusiveTouch: YES];
    
    self.scrollView.scrollEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self loadHTMLString:_htmlAd.htmlContent baseURL:nil];
    
    _delegate = delegate;
}

-(void) tryPlaceCloseButtonInTopRight{
    if(_closeButtonView){
        float margin = 5.0;
        
        CGFloat height = _closeButtonView.frame.size.height;
        CGFloat width = _closeButtonView.frame.size.width;
        
        CGFloat x = [super frame].size.width - (width + margin);
        CGFloat y = margin;
        
        _closeButtonView.frame = CGRectMake(x, y, width, height);
    }
}

-(void) renderAdInView:(UIView *)parentView {
    [super setFrame:[PNUtil getScreenDimensionsInView]];
    [self tryPlaceCloseButtonInTopRight];
    int lastDisplayIndex = (int) parentView.subviews.count;
    [parentView insertSubview:self atIndex:lastDisplayIndex+1];
    //[super setFrame: parentView.bounds];
}

-(void) hide{
    [self removeFromSuperview];
    [_delegate adClosed:NO];
}

-(void) rotate{
    [super setFrame:[PNUtil getScreenDimensionsInView]];
    [self tryPlaceCloseButtonInTopRight];
}

-(void)dealloc{
    _delegate = nil;
    [_htmlAd release];
    [_closeButtonView release];
    [_closeButton release];
    [super dealloc];
}

#pragma mark "Helper Methods"
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
        
        if([_closeButton isKindOfClass:[PNHtmlCloseButton class]]){
            PNHtmlCloseButton *htmlCloseButton = (PNHtmlCloseButton *) _closeButton;
            
            if (htmlCloseButton.closeButtonLink &&
                [htmlCloseButton.closeButtonLink isEqualToString: url.absoluteString]){
                
                [PNLogger log:PNLogLevelDebug format:@"PN Web View Close button was clicked"];
                [_delegate adClosed:YES];
                
                return NO;
            }
        }
        
        if (_htmlAd.clickLink && [_htmlAd.clickLink isEqualToString:url.absoluteString]){
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
    if(_closeButtonView){
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
    [PNLogger log:PNLogLevelWarning error:error format:@"Could not load the webview for HTML Content %@",
        _htmlAd.htmlContent];
    [_delegate didFailToLoadWithError:error];
}
// Only notify the delegate if all the components have been loaded successfully
- (void) componentDidLoad {
    if(_status == AdComponentStatusCompleted && _closeButtonView.status == AdComponentStatusCompleted){
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
    if (component == _closeButtonView) {
        [PNLogger log: PNLogLevelDebug format: @"Close button was pressed..."];
        [self _closeAd];
    }
}

@end
