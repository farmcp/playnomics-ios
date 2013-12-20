//
// Created by jmistral on 10/3/12.
//
// To change the template use AppCode | Preferences | File Templates.
//
#import "PNFrame.h"
#import "PNUtil.h"
#import "PNWebView.h"
#import "PNSession.h"
#import "PNNativeImageView.h"
#import "PNFrameResponse.h"

@implementation PNFrame {
@private
    UIInterfaceOrientation _currentOrientation;
    id<PlaynomicsBasePlacementDelegate> _frameDelegate;
    
    BOOL _shouldRenderFrame;
    PNSession *_session;
    PNFrameResponse *_response;
    PNMessaging *_messaging;
    BOOL _statusBar;
}

@synthesize parentView = _parentView;
@synthesize adView = _adView;
@synthesize state;

#pragma mark - Lifecycle/Memory management
- (id) initWithFrameId: (NSString *) frameId
               session: (PNSession *) session
             messaging: (PNMessaging *) messaging{
    
    if ((self = [super init])) {
        self.state = PNFrameStateNotLoaded;
        _session = session;
        _messaging = messaging;
        _shouldRenderFrame = NO;
        _frameId = [frameId retain];
        
    }
    return self;
}

- (void) dealloc {
    [_frameId release];
    
    _parentView = nil;
    _frameDelegate = nil;
    _session = nil;
    [super dealloc];
}

-(void) updateFrameResponse:(PNFrameResponse *)frameResponse{
    if(_adView){
        [_adView release];
    }

    if(_response){
        [_response release];
    }
    _response = [frameResponse retain];

    if(_response.ad){
        if([_response.ad isKindOfClass:[PNHtmlAd class]]){
            PNHtmlAd *ad = (PNHtmlAd *)_response.ad;
            
            if(_response.closeButton && [_response.closeButton isKindOfClass:[PNHtmlCloseButton class]]){
                _adView = [[PNWebView alloc] initWithAd:ad
                                        htmlCloseButton:_response.closeButton
                                               delegate:self];
            } else if(_response.closeButton && [_response.closeButton isKindOfClass:[PNNativeCloseButton class]]) {
                _adView = [[PNWebView alloc] initWithAd:ad
                                      nativeCloseButton:_response.closeButton
                                               delegate:self];
            }
        } else if([_response.ad isKindOfClass:[PNNativeImageAd class]]){
             PNNativeImageAd *ad = (PNNativeImageAd *)_response.ad;
            
            if(_response.closeButton && [_response.closeButton isKindOfClass:[PNNativeCloseButton class]]){
                _adView = [[PNNativeImageView alloc] initWithAd:ad
                                           background:_response.background
                                          closeButton:_response.closeButton
                                             delegate:self];
            } else {
                _adView = [[PNNativeImageView alloc] initWithAd:ad
                                           background:_response.background
                                             delegate:self];
            }
        }
        
        [self _initOrientationChangeObservers];
    }
}

#pragma mark - Orientation handlers
-(void) _initOrientationChangeObservers {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object: nil];
    
}

-(void) destroyOrientationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

-(void) deviceOrientationDidChange: (NSNotification *)notification {
    UIInterfaceOrientation orientation = [PNUtil getCurrentOrientation];
    if (_currentOrientation == orientation) {
        return;
    }
    _currentOrientation = orientation;
    [PNLogger log:PNLogLevelDebug format: @"Orientation changed to: %i", orientation];
    [_adView rotate];
}

-(void) render {
    [_session pingUrlForCallback: _response.ad.impressionUrl];
    [_adView renderAdInView:_parentView];
    
    _statusBar = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden : YES];
    if(_frameDelegate && [_frameDelegate respondsToSelector:@selector(onShow:)]){
        if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementDelegate)]){
            id<PlaynomicsPlacementDelegate> delegate = (id<PlaynomicsPlacementDelegate>) _frameDelegate;
            [delegate onShow: _response.ad.targetData];
        } else if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementRawDelegate)]){
            id<PlaynomicsPlacementRawDelegate> rawDelegate = (id<PlaynomicsPlacementRawDelegate>) _frameDelegate;
            [rawDelegate onShow: _response.ad.rawTargetData];
        }
    }
}

-(void) reloadFrame{
    _shouldRenderFrame = NO;
    [_messaging fetchDataForFrame:_frameId];
}

#pragma mark - Ad component click handlers
-(void) didLoad {
    self.state = PNFrameStateLoadingComplete;
    if(_shouldRenderFrame) {
        [self render];
    }
}

-(void) didFailToLoad{
    [PNLogger log: PNLogLevelWarning format:@"Frame failed to load."];
    [self handleFailure];
}

-(void) didFailToLoadWithError: (NSError *) error {
    [PNLogger log: PNLogLevelWarning error:error format:@"Frame failed to load due to error."];
    [self handleFailure];
}

-(void) didFailToLoadWithException: (NSException *) exception {
    [PNLogger log: PNLogLevelWarning exception:exception format:@"Frame failed to load due to exception."];
    [self handleFailure];
}

-(void) handleFailure{
    self.state = PNFrameStateLoadingFailed;
    if(_frameDelegate && [_frameDelegate respondsToSelector:@selector(onDidFailToRender)]){
        [_frameDelegate onDidFailToRender];
    }
}

-(void) adClosed:(BOOL) closedByUser {
    if(closedByUser){
        [_session pingUrlForCallback: _response.ad.closeUrl];
        
        if(_frameDelegate && [_frameDelegate respondsToSelector:@selector(onClose:)]){
            //notify the delegate
            if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementDelegate)]){
                id<PlaynomicsPlacementDelegate> delegate = (id<PlaynomicsPlacementDelegate>) _frameDelegate;
                [delegate onClose: _response.ad.targetData];
            } else if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementRawDelegate)]){
                id<PlaynomicsPlacementRawDelegate> rawDelegate = (id<PlaynomicsPlacementRawDelegate>) _frameDelegate;
                [rawDelegate onClose: _response.ad.rawTargetData];
            }
        }
    }
    
    [self destroyOrientationObservers];
    [[UIApplication sharedApplication] setStatusBarHidden : _statusBar];
    //refresh the frame when the ad has been closed
    [self reloadFrame];
}

-(void) adClicked {
    if(_response.ad.clickUrl){
        [_session pingUrlForCallback:_response.ad.clickUrl];
    }
    
    if(_response.ad.targetType == AdTargetUrl && _response.ad.targetUrl){
        //url-based target
        NSURL *url = [NSURL URLWithString:_response.ad.targetUrl];
        if([[UIApplication sharedApplication] canOpenURL:url]){
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    //always notify the delegate that there was a touch event
    if(_frameDelegate && [_frameDelegate respondsToSelector:@selector(onTouch:)]){
        if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementDelegate)]){
            id<PlaynomicsPlacementDelegate> delegate = (id<PlaynomicsPlacementDelegate>) _frameDelegate;
            [delegate onTouch: _response.ad.targetData];
        } else if([_frameDelegate conformsToProtocol:@protocol(PlaynomicsPlacementRawDelegate)]){
            id<PlaynomicsPlacementRawDelegate> rawDelegate = (id<PlaynomicsPlacementRawDelegate>) _frameDelegate;
            [rawDelegate onTouch: _response.ad.rawTargetData];
        }
        
    }
    //refresh the frame when the ad has been clicked
    
    [[UIApplication sharedApplication] setStatusBarHidden : _statusBar];
    [self reloadFrame];
}

#pragma mark - Public Interface
-(void) showInView:(UIView *) parentView
      withDelegate:(id<PlaynomicsPlacementDelegate>) delegate {
    
    _frameDelegate = delegate;
    _shouldRenderFrame = YES;
    _parentView = parentView;
    
    if(self.state == PNFrameStateLoadingFailed && _frameDelegate){
        [_frameDelegate onDidFailToRender];
    } else if (self.state == PNFrameStateLoadingComplete) {
        [self render];
    }
}

- (void) hide{
    [_adView hide];
}
@end
