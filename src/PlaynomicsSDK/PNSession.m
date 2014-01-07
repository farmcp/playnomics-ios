//
//  PlaynomicsSession.m
//  iosapi
//
//  Created by Douglas Kadlecek on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "PNSession.h"
#import "PNSession+Private.h"

#import "PNEventApiClient.h"
#import "PNEventUserInfo.h"
#import "PNEventTransaction.h"
#import "PNEventMilestone.h"
#import "PNDeviceManager.h"
#import "PNMessaging.h"

#import <libkern/OSAtomic.h>

//events
#import "PNEventAppPage.h"
#import "PNEventAppStart.h"
#import "PNEventAppPause.h"
#import "PNEventAppResume.h"
#import "PNEventAppRunning.h"
#import "PNEvent.h"
#import "PNEventTransaction.h"
#import "PNEventMilestone.h"
#import "PNEventUserInfo.h"

@implementation PNSession {
@private
    int _sequence;
    NSTimer *_eventTimer;
    
    NSString *_testEventsUrl;
    NSString *_prodEventsUrl;
    NSString *_testMessagingUrl;
    NSString *_prodMessagingUrl;
    
    NSTimeInterval _sessionStartTime;
	NSTimeInterval _pauseTime;
    
    PNEventApiClient *_apiClient;
    PNMessaging *_messaging;
    
    volatile int _clicks;
    volatile int _totalClicks;
    
    NSMutableArray *_observers;
    NSObject *_syncLock;
    UIView *_parentView;
}


@synthesize applicationId=_applicationId;
@synthesize userId=_userId;
@synthesize sessionId=_sessionId;
@synthesize instanceId=_instanceId;
@synthesize state=_state;

@synthesize cache=_cache;

@synthesize overrideEventsUrl=_overrideEventsUrl;
@synthesize overrideMessagingUrl=_overrideMessagingUrl;

@synthesize sdkVersion=_sdkVersion;

@synthesize apiClient=_apiClient;
@synthesize deviceManager=_deviceManager;

//Singleton
+ (PNSession *)sharedInstance{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id) init {
    if ((self = [super init])) {
        _sequence = 0;
        
        _apiClient = [[PNEventApiClient alloc] initWithSession: self];
        
        _testEventsUrl = PNPropertyBaseTestUrl;
        _prodEventsUrl = PNPropertyBaseProdUrl;
        _testMessagingUrl = PNPropertyMessagingTestUrl;
        _prodMessagingUrl = PNPropertyMessagingProdUrl;
        
        _sdkVersion = PNPropertyVersion;
        
        _cache = [[PNCache alloc] init];
        _deviceManager = [[PNDeviceManager alloc] initWithCache:_cache];
        
        _observers = [NSMutableArray new];
        
        _messaging = [[PNMessaging alloc] initWithSession: self];
        
        _syncLock = [[NSObject alloc] init];
    }
    return self;
}

- (void) dealloc {
    [_apiClient release];
    [_cache release];
    
    /** Tracking values */
    [_userId release];
	[_sessionId release];
	[_instanceId release];
    
    [_overrideEventsUrl release];
    [_overrideMessagingUrl release];
    [_sdkVersion release];
    
    [_deviceManager release];
    
    [_syncLock release];
    [_parentView release];
    
    [super dealloc];
}

#pragma mark - URLs
-(NSString*) getEventsUrl{
    if(_overrideEventsUrl){
        return _overrideEventsUrl;
    }
    return _prodEventsUrl;
}

-(NSString *) getMessagingUrl{
    if(_overrideMessagingUrl){
        return _overrideMessagingUrl;
    }
    return _prodMessagingUrl;
}

#pragma mark - Session Control Methods
-(PNGameSessionInfo *) getGameSessionInfo{
    PNGameSessionInfo * info =  [[PNGameSessionInfo alloc] initWithApplicationId:self.applicationId userId:self.userId idfa:[_cache getIdfa] idfv:[_cache getIdfv] sessionId: self.sessionId];
    [info autorelease];
    return info;
}

-(void) assertSessionHasStarted{
    NSAssert(_state == PNSessionStateStarted || _state == PNSessionStatePaused,
             @"PlayRM session could not be started! Can't send data to Playnomics API.");
}

-(void) start {
    @try {
        if (_state == PNSessionStateStarted) {
            return;
        }
        
        if (_state == PNSessionStatePaused) {
        
            // If paused, resume and get out of here
            // this should never really occurr
            [self resume];
            return;
        }
        
        [self startSession];
        [self startEventTimer];
    
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        
        void (^applicationPaused)(NSNotification *notif) = ^(NSNotification *notif){
            [self pause];
        };
        void (^applicationResumed)(NSNotification *notif) = ^(NSNotification *notif){
            [self resume];
        };
        void (^applicationTerminating)(NSNotification *notif) = ^(NSNotification *notif){
            [self stop];
        };
        
        [_observers addObject: [center addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:mainQueue usingBlock:applicationPaused]];
        [_observers addObject: [center addObserverForName:UIApplicationWillTerminateNotification
                                                   object:nil
                                                    queue:mainQueue
                                               usingBlock:applicationTerminating]];
        
        [_observers addObject: [center addObserverForName:UIApplicationDidBecomeActiveNotification
                                                   object:nil
                                                    queue:mainQueue
                                               usingBlock:applicationResumed]];
        
        // Retrieve stored Event List
        NSSet *storedEvents = (NSSet *) [NSKeyedUnarchiver unarchiveObjectWithFile:PNFileEventArchive];
        if (storedEvents) {
            for(NSString *eventUrl in storedEvents){
                [_apiClient enqueueEventUrl: eventUrl];
            }
            // Remove archive so as not to pick up bad events when starting up next time.
            [[NSFileManager defaultManager] removeItemAtPath:PNFileEventArchive error:nil];
        }
        return;
    }
    @catch (NSException *exception) {
        [PNLogger log:PNLogLevelError exception:exception format: @"Could not start the PlayRM SDK."];
    }
}

- (void) startSession{
    /** Setting Session variables */
    [_cache loadDataFromCache];
    
    BOOL settingsChanged = [_deviceManager syncDeviceSettingsWithCache];

    _state = PNSessionStateStarted;
    
    NSString *lastUserId = [_cache getLastUserId];
    
    // Set userId to cookieId if it isn't present
    if (!(_userId && [_userId length] > 0)) {
        if ([_cache getIdfa]) {
            _userId = [[_cache getIdfa] retain];
        } else if (lastUserId) {
            //use the previous user ID
            _userId = [lastUserId retain] ;
        } else {
            //autogenerate the user ID
            _userId = [[_deviceManager generateUserId] retain];
        }
    }
    
    _sequence = 1;
    _clicks = 0;
    _totalClicks = 0;
    
    
    NSTimeInterval lastSessionStartTime = [_cache getLastEventTime];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    //per our events specification, the sessionStart is always when the session start call is made,
    //regardless of whether is an appPage or appStart
    bool sessionLapsed = (currentTime - lastSessionStartTime > PNSessionTimeout) || ![_userId isEqualToString:lastUserId];
    // Send an appStart if it has been > 3 min since the last session or a different user
    // otherwise send an appPage
    if (sessionLapsed) {
        _sessionId = [[PNGeneratedHexId alloc] initAndGenerateValue];
        _instanceId = [_sessionId retain];
        [_cache updateLastSessionId: _sessionId];
        [_cache updateLastUserId: _userId];
        [_cache updateLastEventTimeToNow];
    } else {
        _sessionId = [_cache getLastSessionId];
        // Always create a new Instance Id
        _instanceId = [[PNGeneratedHexId alloc] initAndGenerateValue];
    }
    
    /** Send appStart or appPage event */
    PNEvent *ev = sessionLapsed ? [[PNEventAppStart alloc] initWithSessionInfo: [self getGameSessionInfo] instanceId: _instanceId]
            : [[PNEventAppPage alloc] initWithSessionInfo: [self getGameSessionInfo] instanceId: _instanceId];
    [ev autorelease];
    _sessionStartTime = ev.eventTime;
    // Try to send and queue if unsuccessful
    [_apiClient enqueueEvent:ev];
    [_apiClient start];
    
    if(settingsChanged){
        [self onDeviceInfoChanged];
    }
    
    [_cache writeDataToCache];
}

- (void) pause {
    @try {
        [PNLogger log:PNLogLevelDebug format:@"Session paused."];
        if (_state == PNSessionStatePaused){ return;}
        
        _state = PNSessionStatePaused;
        
        [self stopEventTimer];
        
        PNEventAppPause *ev = [[PNEventAppPause alloc] initWithSessionInfo:[self getGameSessionInfo] instanceId:_instanceId sessionStartTime:_sessionStartTime sequenceNumber:_sequence touches:(int)_clicks totalTouches:(int)_totalClicks];
        [ev autorelease];
        _pauseTime = ev.eventTime;
        _sequence += 1;
        
        // Try to send and queue if unsuccessful
        
        [_apiClient pause];
        [_apiClient enqueueEvent:ev];
        
    }
    @catch (NSException *exception) {
        [PNLogger log: PNLogLevelError exception: exception format:@"Could not pause the Playnomics Session"];
    }
}

/**
 * Resume
 */
- (void) resume {
    @try {
        [PNLogger log:PNLogLevelDebug format:@"Session resumed."];
        if (_state == PNSessionStateStarted) { return; }
        
        [self startEventTimer];
        
        _state = PNSessionStateStarted;
        
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        bool sessionLapsed = (currentTime - _pauseTime > PNSessionRestartTimeout);
        
        if (sessionLapsed) {
            [self startSession];
        } else {
            PNEventAppResume *ev  = [[PNEventAppResume alloc] initWithSessionInfo: [self getGameSessionInfo] instanceId: _instanceId sessionPauseTime:_pauseTime sessionStartTime:_sessionStartTime sequenceNumber:_sequence];
            [ev autorelease];
            [_apiClient enqueueEvent: ev];
            [_apiClient start];
        }
    }
    @catch (NSException *exception) {
        [PNLogger log: PNLogLevelError exception: exception format:@"Could not resume the Playnomics Session"];
    }
}

/**
 * Stop.
 *
 * @return the API Result
 */
- (void) stop {
    @try {
        [PNLogger log:PNLogLevelDebug format:@"Session stopped."];
        if (_state == PNSessionStateStopped) {
            return;
        }
        
        // Currently Session is only stopped when the application quits.
        _state = PNSessionStateStopped;
        [self stopEventTimer];
        
        for(id observer in _observers){
            //remove all observers
            [[NSNotificationCenter defaultCenter] removeObserver: observer];
        }
        
        [_cache writeDataToCache];
        
        [_apiClient stop];
        NSSet *unprocessedEvents = [_apiClient getAllUnprocessedUrls];
        // Store Event List
        if (![NSKeyedArchiver archiveRootObject: unprocessedEvents toFile:PNFileEventArchive]) {
            [PNLogger log: PNLogLevelWarning format: @"Playnomics: Could not save event list"];
        }
    }
    @catch (NSException *exception) {
        [PNLogger log: PNLogLevelError exception: exception];
    }
}

#pragma mark - Timed Event Sending
- (void) startEventTimer {
    @try {
        [self stopEventTimer];
        _eventTimer = [[NSTimer scheduledTimerWithTimeInterval:PNUpdateTimeInterval target:self selector:@selector(consumeQueue) userInfo:nil repeats:YES] retain];
    }
    @catch (NSException *exception) {
        [PNLogger log: PNLogLevelError exception: exception];
    }
}

- (void) stopEventTimer {
    @try {
        if ([_eventTimer isValid]) {
            [_eventTimer invalidate];
        }
        [_eventTimer release];
        _eventTimer = nil;
    }
    @catch (NSException *exception) {
        [PNLogger log: PNLogLevelError exception: exception];
    }
}

- (void) consumeQueue {
    @try {
        if (_state == PNSessionStateStarted) {
            _sequence++;
            
            PNEventAppRunning *ev = [[PNEventAppRunning alloc] initWithSessionInfo: [self getGameSessionInfo] instanceId: _instanceId sessionStartTime: _sessionStartTime sequenceNumber: _sequence touches:(int)_clicks totalTouches: (int)_totalClicks];
            [ev autorelease];
         
            [_apiClient enqueueEvent:ev];
            
            // Reset keys/clicks
            [self resetTouchEvents];
        }
    }
    @catch (NSException *exception) {
        [PNLogger log:PNLogLevelWarning exception: exception];
    }
}

#pragma mark - Application Event Handlers
- (void) onUIEventReceived: (UIEvent *) event {
    if (event.type == UIEventTypeTouches) {
        UITouch *touch = [event allTouches].anyObject;
        if (touch.phase == UITouchPhaseBegan) {
            [self incrementTouchEvents];
        }
    }
}

-(void) incrementTouchEvents{
    OSAtomicIncrement32Barrier(&_clicks);
    OSAtomicIncrement32Barrier(&_totalClicks);
}

-(void) resetTouchEvents{
    @synchronized(_syncLock){
        _clicks = 0;
    }
}

#pragma mark - Device Identifiers

-(void)onDeviceInfoChanged{
    PNEventUserInfo *userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:[self getGameSessionInfo] limitAdvertising:[_cache getLimitAdvertising]];
    [userInfo autorelease];
    [_apiClient enqueueEvent:userInfo];
}

#pragma mark - Explicit Events

- (void) transactionWithUSDPrice:(NSNumber *) priceInUSD
                        quantity:(NSInteger) quantity  {
    @try {
        [self assertSessionHasStarted];
        
        NSArray *currencyTypes = [NSArray arrayWithObject: [NSNumber numberWithInt: PNCurrencyUSD]];
        NSArray *currencyValues = [NSArray arrayWithObject: priceInUSD];
        NSArray *currencyCategories = [NSArray arrayWithObject: [NSNumber numberWithInt:PNCurrencyCategoryReal]];
        
        NSString *itemId = @"monetized";
        
        PNEventTransaction *ev = [[PNEventTransaction alloc] initWithSessionInfo:[self getGameSessionInfo] itemId:itemId quantity:(int)quantity type:PNTransactionBuyItem currencyTypes:currencyTypes currencyValues:currencyValues currencyCategories:currencyCategories];
        [ev autorelease];
        [_apiClient enqueueEvent:ev];
    }
    @catch (NSException* exception) {
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send transaction."];
    }
}

- (void) milestone: (PNMilestoneType) milestoneType {
    @try {
        [self assertSessionHasStarted];
        
        PNEventMilestone *ev = [[PNEventMilestone alloc] initWithSessionInfo:[self getGameSessionInfo] milestoneType:milestoneType];
        [ev autorelease];
        [_apiClient enqueueEvent:ev];
    }
    @catch (NSException *exception) {
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send milestone."];
    }
}

- (void) customEventWithName: (NSString *)customEventName{
    @try {
        [self assertSessionHasStarted];
        
        PNEventMilestone *ev = [[PNEventMilestone alloc] initWithSessionInfo:[self getGameSessionInfo] customEventName: customEventName];
        [ev autorelease];
        [_apiClient enqueueEvent:ev];
    }
    @catch (NSException *exception) {
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send milestone."];
    }

}

- (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString *) campaign
                    onInstallDate:(NSDate *) installDate{
    @try{
        [self assertSessionHasStarted];
        
        PNEventUserInfo *userInfo = [[PNEventUserInfo alloc] initWithSessionInfo:[self getGameSessionInfo] source: source campaign:campaign installDate:installDate];
        [userInfo autorelease];
        [_apiClient enqueueEvent:userInfo];
    } @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send attribution event."];

    }
}

- (void) pingUrlForCallback:(NSString *) url{
    [_apiClient enqueueEventUrl: url];
}

#pragma mark "Push Notifications"

- (void) enablePushNotificationsWithToken:(NSData *)deviceToken {
    @try {
        [self assertSessionHasStarted];
        NSString *oldToken = [_cache getDeviceToken];
        NSString *newToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (!(oldToken && [newToken isEqualToString:oldToken])) {
            [_cache updateDeviceToken: newToken];
            [_cache writeDataToCache];
            
            PNEventUserInfo *ev = [[PNEventUserInfo alloc] initWithSessionInfo:[self getGameSessionInfo] pushToken: newToken];
            [ev autorelease];
            [_apiClient enqueueEvent: ev];
        }
    }
    @catch (NSException *exception) {
       [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send device token."];
    }
}

- (void) pushNotificationsWithPayload:(NSDictionary *)payload {
    @try {
        [self assertSessionHasStarted];
        
        if ([payload valueForKeyPath:PushResponse_InteractionUrl] != nil) {
            NSString *lastDeviceToken = [_cache getDeviceToken];
            
            NSString *callbackurl = [payload valueForKeyPath:PushResponse_InteractionUrl];
            // append required parameters to the interaction tracking url
            NSString *trackedCallback = [callbackurl stringByAppendingFormat:@"&%@=%lld&%@=%@&%@=%@",
                                         PushInteractionUrl_AppIdParam, self.applicationId,
                                         PushInteractionUrl_UserIdParam, self.userId,
                                         PushInteractionUrl_PushTokenParam, lastDeviceToken];
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            // only append the flag "pushIgnored" if the app is in Active state and either
            // the game developer doesn't pass us the flag "pushIgnored" in the dictionary or they do pass the flag and set it to YES
            if (state == UIApplicationStateActive && !([payload objectForKey:PushInteractionUrl_IgnoredParam] && [[payload objectForKey:PushInteractionUrl_IgnoredParam] isEqual:[NSNumber numberWithBool:NO]])) {
                trackedCallback = [trackedCallback stringByAppendingFormat:@"&%@",PushInteractionUrl_IgnoredParam];
            }
            [self pingUrlForCallback: trackedCallback];
        }
    }
    @catch (NSException *exception) {
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not send process push notification data."];
    }   
}


#pragma mark "Messaging"
//all of this code needs to be moved inside of PlaynomicsMessaging
- (void) preloadFramesWithIds: (NSSet *)frameIDs{
    @try{
        [self assertSessionHasStarted];
        for(NSString* frameID in frameIDs){
            [_messaging fetchDataForFrame:frameID];
        }
    }
    @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not preload frames."];
    }
}

- (void) showFrameWithId:(NSString *) frameId{
    @try{
        [self assertSessionHasStarted];
        [_messaging showFrame:frameId inView:[self getViewForFrame] withDelegate:nil];
    }
    @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not show frame."];
    }
}


- (void) showFrameWithId:(NSString *) frameId delegate:(id<PlaynomicsPlacementDelegate>) delegate{
    @try{
        [self assertSessionHasStarted];
        [_messaging showFrame:frameId inView:[self getViewForFrame] withDelegate:delegate];
    }
    @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not show frame."];
    }
}

-(UIView *) getViewForFrame
{
    if(_parentView){
        return _parentView;
    }
    UIView* parentView = [[[[UIApplication sharedApplication] delegate] window] rootViewController].view;
    NSAssert(parentView != nil, @"The root view controller must be set if you do not explicitly provide a view to render frames in.");
    return parentView;
}

- (void) hideFrameWithID:(NSString *) frameId{
    @try{
        [self assertSessionHasStarted];
        [_messaging hideFrame:frameId];
    }
    @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not hide frame."];
    }

}

- (void) setFrameParentView:(UIView *) parentView{
    @try{
        if(_parentView){
            [_parentView release];
        }
        _parentView = [parentView retain];
    } @catch(NSException *exception){
        [PNLogger log:PNLogLevelWarning exception:exception format: @"Could not set parent view."];
    }
}
@end



