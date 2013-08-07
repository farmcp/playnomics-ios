//
// Created by jmistral on 10/3/12.
//
// To change the template use AppCode | Preferences | File Templates.
//
#import "PlaynomicsFrame+Exposed.h"
#import "PlaynomicsMessaging+Exposed.h"
#import "FSNConnection.h"
#import "BaseAdComponent.h"
#import "PNErrorEvent.h"
#import "PlaynomicsCallback.h"
#import "PNUtil.h"
#pragma mark - PlaynomicsFrame

typedef enum {
    AdColony,
    AdUnknown
} AdType;

@interface PlaynomicsFrame()
@property (nonatomic,retain)PlaynomicsCallback *callbackUtil;
@property (nonatomic,retain)NSString *videoViewUrl;
@end

@implementation PlaynomicsFrame {
@private
    NSTimer *_expirationTimer;
    NSDictionary *_properties;
    BaseAdComponent *_background;
    BaseAdComponent *_adArea;
    BaseAdComponent *_closeButton;
    int _expirationSeconds;
    UIInterfaceOrientation _currentOrientation;
    id<PNFrameRefreshHandler> _delegate;
    AdType _adType;
    id<PNFrameDelegate> _frameDelegate;
}

@synthesize frameId = _frameId;

#pragma mark - Lifecycle/Memory management
- (id) initWithProperties: (NSDictionary *)properties
            forFrameId:(NSString *)frameId
            andDelegate: (id<PNFrameRefreshHandler>) delegate
            frameDelegate: (id<PNFrameDelegate>) frameDelegate {
    
    if (self = [super init]) {
        _frameId = [frameId retain];
        _properties = [properties retain];
        _delegate = delegate;

        if ([properties objectForKey:FrameResponseAd_AdType] && [[properties objectForKey:FrameResponseAd_AdType] isEqualToString:@"AdColony"]) {
            _adType = AdColony;
            self.videoViewUrl = [properties objectForKey:FrameResponseAd_VideoViewUrl];
        } else {
            _adType = AdUnknown;
        }

        _frameDelegate = frameDelegate;
        
        self.callbackUtil = [[[PlaynomicsCallback alloc] init] autorelease];
        
        [self _initOrientationChangeObservers];
        [self _initAdComponents];
    }
    return self;
}

- (void) dealloc {
    [_properties release];
    [_background release];
    [_adArea release];
    [_closeButton release];
    [_frameId release];
    [super dealloc];
}

- (void) _initAdComponents {
    _background = [[BaseAdComponent alloc] initWithProperties:[_properties objectForKey:FrameResponseBackgroundInfo]
                                                     forFrame:self
                                             withTouchHandler:nil
                                                  andDelegate:self];
    
    _adArea = [[BaseAdComponent alloc] initWithProperties:[self _mergeAdInfoProperties]
                                                 forFrame:self
                                         withTouchHandler:[[self _mergeAdInfoProperties] valueForKey:FrameResponseAd_ClickTarget] != nil && [[self _mergeAdInfoProperties] valueForKey:FrameResponseAd_ClickTarget] != [NSNull null] ? @selector(_adClicked:) : nil
                                              andDelegate:self];
    
    _closeButton = [[BaseAdComponent alloc] initWithProperties:[_properties objectForKey:FrameResponseCloseButtonInfo]
                                                      forFrame:self
                                              withTouchHandler:@selector(_stop)
                                                   andDelegate:self];
    
    NSNumber *expNum = [_properties objectForKey:FrameResponseExpiration];
    _expirationSeconds = [expNum intValue];
    
    [_background layoutComponent];
    [_adArea layoutComponent];
    [_closeButton layoutComponent];
    
    [_background addSubComponent:_adArea];
    [_background addSubComponent:_closeButton];
    _background.imageUI.hidden = YES;
}

- (BOOL) _allComponentsLoaded {
    
    id displayNameTypeValue = _background.imageUrl;
    
    if (displayNameTypeValue != [NSNull null]){
        if(_background.imageUrl == NULL || [_background.imageUrl isEqualToString:@"null"]){
            [_background setStatus:AdComponentStatusCompleted];
        }
    } else {
        [_background setStatus:AdComponentStatusCompleted];
    }
    
    displayNameTypeValue = _closeButton.imageUrl;
    
    if (displayNameTypeValue != [NSNull null]){
        if(_closeButton.imageUrl == NULL || [_closeButton.imageUrl isEqualToString:@"null"]){
            [_closeButton setStatus:AdComponentStatusCompleted];
        }
    } else {
        [_closeButton setStatus:AdComponentStatusCompleted];
    }
    
    return (_background.status == AdComponentStatusCompleted
            && _adArea.status == AdComponentStatusCompleted
            && _closeButton.status == AdComponentStatusCompleted);
}

- (void) componentDidLoad: (id) component {
    _background.imageUI.hidden = ![self _allComponentsLoaded];
}

- (NSDictionary *) _mergeAdInfoProperties {
    NSDictionary *adInfo = [self _determineAdInfoToUse];
    NSDictionary *adLocationInfo = [_properties objectForKey:FrameResponseAdLocationInfo];
    
    NSMutableDictionary *mergedDict = [NSMutableDictionary dictionaryWithDictionary:adInfo];
    [mergedDict addEntriesFromDictionary:adLocationInfo];
    return mergedDict;
}

- (NSDictionary *) _determineAdInfoToUse {
    NSArray *adFrameResponse = [_properties objectForKey:FrameResponseAds];
    if (adFrameResponse==nil || adFrameResponse.count==0){
        return nil;
    }
    return [adFrameResponse objectAtIndex:0];
}


#pragma mark - Orientation handlers
- (void) _initOrientationChangeObservers {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object: nil];
}

- (void) _destroyOrientationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void) _deviceOrientationDidChange: (NSNotification *)notification {
    UIInterfaceOrientation orientation = [PNUtil getCurrentOrientation];
    if (_currentOrientation == orientation) {
        return;
    }
    _currentOrientation = orientation;
    
    NSLog(@"Orientation changed to: %i", orientation);
    [_background layoutComponent];
}

#pragma mark - Ad component click handlers
- (void) _stop {
    NSLog(@"Close button was pressed...");
    [self _closeAd];
    NSString *callback = [_adArea.properties objectForKey:FrameResponseAd_CloseUrl];
    [self.callbackUtil submitRequestToServer:callback];
}

- (void) _adClicked: (UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:_adArea.imageUI];
    int x = location.x;
    int y = location.y;
    
    NSString* coordParams = [NSString stringWithFormat:@"&x=%d&y=%d", x, y];
    NSString* targetTypeString = [_adArea.properties objectForKey : FrameResponseAd_TargetType];
    AdTarget targetType = [PNUtil toAdTarget : targetTypeString];
    
    if(targetType == AdTargetUrl) {
        //url-based target
        NSString* clickTarget = [_adArea.properties objectForKey:FrameResponseAd_ClickTarget];
        AdAction actionType = [PNUtil toAdAction : clickTarget];
        
        if (actionType == AdActionHTTP) {
            //just redirect to the ad
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:clickTarget]];
        } else if (actionType == AdActionDefinedAction || actionType == AdActionExecuteCode) {
            NSString* preExecuteUrl = [[_adArea.properties objectForKey:FrameResponseAd_PreExecuteUrl] stringByAppendingString:coordParams];
            NSString* postExecuteUrl =  [_adArea.properties objectForKey:FrameResponseAd_PostExecuteUrl];
            
            NSString* actionLabel = [self adActionMethodForURLPath:clickTarget];
            NSInteger responseCode;
            NSString* exception;
            
            if (actionType == AdActionDefinedAction) {
                [self.callbackUtil submitRequestToServer: preExecuteUrl];
                @try {
                    [[PlaynomicsMessaging sharedInstance] performActionForLabel:actionLabel];
                    responseCode = 2;
                    exception = @"";
                }
                @catch (NSException *e) {
                    responseCode = -6;
                    exception = [NSString stringWithFormat:@"%@+%@", e.name, e.reason];
                }
                [self.callbackUtil submitRequestToServer: postExecuteUrl];
            } else {
                [self.callbackUtil submitRequestToServer: preExecuteUrl];
                @try {
                    [[PlaynomicsMessaging sharedInstance] executeActionOnDelegate:actionLabel];
                    responseCode = 1;
                    exception = @"";
                }
                @catch (NSException *e) {
                    responseCode = -4;
                    exception = [NSString stringWithFormat:@"%@+%@", e.name, e.reason];
                }
                NSString *post = [NSString stringWithFormat:@"%@&c=%d&e=%@", postExecuteUrl, responseCode, exception];
                [self.callbackUtil submitRequestToServer: post];
            }
        }
    } else if (targetType == AdTargetData) {
        //handle rich data
        NSString* preExecuteUrl = [[_adArea.properties objectForKey:FrameResponseAd_PreExecuteUrl] stringByAppendingString:coordParams];
        NSString* postExecuteUrl =  [_adArea.properties objectForKey:FrameResponseAd_PostExecuteUrl];

        NSInteger responseCode;
        NSString* exception;
        
        NSString* targetData = [_adArea.properties objectForKey:FrameResponseAd_TargetData];
        [self.callbackUtil submitRequestToServer: preExecuteUrl];
        
        @try {
            if(_frameDelegate == nil || ![_frameDelegate respondsToSelector:@selector(onClick:)]){
                exception = @"Received a click but could not send the data to the frameDelegate";
                responseCode = -4;
                NSLog(@"%@", exception);
            } else {
                NSDictionary* jsonData = [PNUtil deserializeJsonData: (NSData*)targetData];
                [_frameDelegate onClick: jsonData];
                responseCode = 1;
            }
        }
        @catch (NSException *e) {
            exception = [NSString stringWithFormat:@"%@+%@", e.name, e.reason];
            responseCode = -4;
        }
        NSString *post = [NSString stringWithFormat:@"%@&c=%d&e=%@", postExecuteUrl, responseCode, exception];
        [self.callbackUtil submitRequestToServer: post];
    }
    [self _closeAd];
}

- (void) _closeAd {
    [_background hide];
    [self _destroyOrientationObservers];
    [self _stopExpiryTimer];
}

- (NSString*) adActionMethodForURLPath: (NSString*)urlPath{
    NSArray *comps = [urlPath componentsSeparatedByString:@"://"];
    NSString *resource = [comps objectAtIndex:1];
    return [resource stringByReplacingOccurrencesOfString:@"//" withString:@""];
}

#pragma mark - Public Interface
- (DisplayResult) start {
    NSString *frameResponseURL =[_adArea.properties objectForKey:FrameResponseAd_ImpressionUrl];
    if (frameResponseURL==nil)
    {
        //this may happen due to broken JSON
        return DisplayResultFailUnknown;
    }
    
    if (_adType == AdColony) {
        [self.callbackUtil submitAdImpressionToServer:frameResponseURL];
        return DisplayAdColony;
    }
    
    [_background display];
    [self _startExpiryTimer];
    
    [self.callbackUtil submitRequestToServer:frameResponseURL];
    
    if ([self _allComponentsLoaded]) {
        return DisplayResultDisplayed;
    } else {
        return DisplayResultDisplayPending;
    }
}


- (void) _startExpiryTimer {
    @try {
        [self _stopExpiryTimer];
        
        _expirationTimer = [[NSTimer scheduledTimerWithTimeInterval:_expirationSeconds target:self selector:@selector(_notifyDelegate) userInfo:nil repeats:NO] retain];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
    
}

- (void) _stopExpiryTimer {
    
    @try {
        
        if ([_expirationTimer isValid]) {
            [_expirationTimer invalidate];
        }
        
        [_expirationTimer release];
        _expirationTimer = nil;
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}

- (void) _notifyDelegate {
    [_delegate refreshFrameWithId:_frameId];
}

- (void) refreshProperties: (NSDictionary *)properties {
    
    // TODO: should we reset all properties, or just the images?
    NSLog(@"refreshProperties called fro frameId: %@", _frameId);
    [self _closeAd];
    [_properties release];
    [_background release];
    [_adArea release];
    [_closeButton release];
    _properties = [properties retain];
    
    [self _initOrientationChangeObservers];
    [self _initAdComponents];
    [self start];
}

- (void)sendVideoView {
    if (self.videoViewUrl!=nil) {
        [self.callbackUtil submitAdImpressionToServer:self.videoViewUrl];
    }
}

@end
