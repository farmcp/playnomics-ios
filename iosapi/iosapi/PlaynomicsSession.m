//
//  PlaynomicsSession.m
//  iosapi
//
//  Created by Douglas Kadlecek on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlaynomicsSession.h"
#import "PNConfig.h"
#import "PNConstants.h"
#import "PNRandomGenerator.h"
#import "PNEventSender.h"
#import "PlaynomicsCallback.h"
#import "PNBasicEvent.h"
#import "PNUserInfoEvent.h"
#import "PNTransactionEvent.h"
#import "PNMilestoneEvent.h"
#import "PNAPSNotificationEvent.h"
#import "PNErrorEvent.h"
#import "PlaynomicsSession+Exposed.h"
#import "PlaynomicsMessaging+Exposed.h"
#import "PNUserInfo.h"
#import "PNLogger.h"

@implementation PlaynomicsSession {
@private
    PNSessionState _sessionState;
    int _collectMode;
	int _sequence;
    
    NSTimer* _eventTimer;
    NSMutableArray* _playnomicsEventList;
    NSString *_instanceId;
    NSString* _testEventsUrl;
    NSString* _prodEventsUrl;
    NSString* _testMessagingUrl;
    NSString* _prodMessagingUrl;
    
    NSTimeInterval _sessionStartTime;
	NSTimeInterval _pauseTime;
    
    PlaynomicsCallback* _callback;
    PNEventSender* _eventSender;
    
    int _timeZoneOffset;
	int _clicks;
	int _totalClicks;
	int _keys;
	int _totalKeys;
}

@synthesize applicationId=_applicationId;
@synthesize userId=_userId;
@synthesize cookieId=_cookieId;
@synthesize sessionId=_sessionId;
@synthesize sessionState=_sessionState;

@synthesize testMode=_testMode;
@synthesize overrideEventsUrl=_overrideEventsUrl;
@synthesize overrideMessagingUrl=_overrideMessagingUrl;

@synthesize sdkVersion=_sdkVersion;

//Singleton
+ (PlaynomicsSession *)sharedInstance{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id) init {
    if ((self = [super init])) {
        _collectMode = PNSettingCollectionMode;
        _sequence = 0;
        //does setting this to empty, make any sense?
        _userId = @"";
        //does setting this to empty, make any sense?
        _sessionId = @"";
        _playnomicsEventList = [[NSMutableArray alloc] init];
        _eventSender = [[PNEventSender alloc] init];
        
        _testEventsUrl = PNPropertyBaseTestUrl;
        _prodEventsUrl = PNPropertyBaseProdUrl;
        
        _testMessagingUrl = PNPropertyMessagingTestUrl;
        _prodMessagingUrl = PNPropertyMessagingProdUrl;
        
        _callback = [[PlaynomicsCallback alloc] init];
    
        _sdkVersion = PNPropertyVersion;
    }
    
    return self;
}

- (void) dealloc {
    [_eventSender release];
	[_playnomicsEventList release];
    [_callback release];

    /** Tracking values */
    [_userId release];
	[_cookieId release];
	[_sessionId release];
	[_instanceId release];
    
    [_overrideEventsUrl release];
    [_overrideMessagingUrl release];
    [_sdkVersion release];
    [super dealloc];
}

#pragma mark - URLs
-(NSString*) getEventsUrl{
    if(_overrideEventsUrl != nil){
        return _overrideEventsUrl;
    }
    if(_testMode){
        return _testEventsUrl;
    }
    return _prodEventsUrl;
}

-(NSString*) getMessagingUrl{
    if(_overrideMessagingUrl != nil){
        return _overrideMessagingUrl;
    }
    if(_testMode){
        return _testMessagingUrl;
    }
    return _prodMessagingUrl;
}

#pragma mark - Session Control Methods
- (bool) startWithApplicationId:(signed long long) applicationId userId: (NSString *) userId {
    _userId = [userId retain];
    return [self startWithApplicationId:applicationId];
}

- (bool) startWithApplicationId:(signed long long) applicationId {
    @try {
        if (_sessionState == PNSessionStateStarted) {
            return YES;
        }
        
        // If paused, resume and get out of here
        if (_sessionState == PNSessionStatePaused) {
            [self resume];
            return YES;
        }
        
        _applicationId = applicationId;
        
        [self startSession];
        [self startEventTimer];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self selector: @selector(onKeyPressed:) name: UITextFieldTextDidChangeNotification object: nil];
        [defaultCenter addObserver: self selector: @selector(onKeyPressed:) name: UITextViewTextDidChangeNotification object: nil];
        
        [defaultCenter addObserver: self selector: @selector(onApplicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object: nil];
        [defaultCenter addObserver: self selector: @selector(onApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object: nil];
        [defaultCenter addObserver: self selector: @selector(onApplicationWillTerminate:) name: UIApplicationWillTerminateNotification object: nil];
        [defaultCenter addObserver: self selector: @selector(onApplicationDidLaunch:) name: UIApplicationDidFinishLaunchingNotification object: nil];
        
        // Retrieve stored Event List
        NSArray *storedEvents = (NSArray *) [NSKeyedUnarchiver unarchiveObjectWithFile:PNFileEventArchive];
        if ([storedEvents count] > 0) {
            [_playnomicsEventList addObjectsFromArray:storedEvents];
            
            // Remove archive so as not to pick up bad events when starting up next time.
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm removeItemAtPath:PNFileEventArchive error:nil];
        }
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Could not start the PlayRM SDK.");
        NSLog( @"Exception Name: %@", exception.name);
        NSLog( @"Exception Reason: %@", exception.reason );
        return NO;
    }
}

- (void) startSession{
    NSLog(@"startSessionWithApplicationId");
    
    /** Setting Session variables */
    
    _sessionState = PNSessionStateStarted;
    
    PNUserInfo *userInfo = [[PNUserInfo alloc] init:self];
    _cookieId = [userInfo breadcrumbId];
    
    // Set userId to cookieId if it isn't present
    if ([_userId length] == 0) {
        _userId = [_cookieId retain];
    }
    
    _collectMode = PNSettingCollectionMode;
    
    _timeZoneOffset = [[NSTimeZone localTimeZone] secondsFromGMT] / -60;
    _sequence = 1;
    _clicks = 0;
    _totalClicks = 0;
    _keys = 0;
    _totalKeys = 0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastUserId = [userDefaults stringForKey:PNUserDefaultsLastUserID];
    NSTimeInterval lastSessionStartTime = [userDefaults doubleForKey:PNUserDefaultsLastSessionStartTime];
    
    PNEventType eventType;
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    // Send an appStart if it has been > 3 min since the last session or a different user
    // otherwise send an appPage
    if ((currentTime - lastSessionStartTime > PNSessionTimeout)
        || ![_userId isEqualToString:lastUserId]) {
        _sessionId = [[PNRandomGenerator createRandomHex] retain];
        _instanceId = [_sessionId retain];
        _sessionStartTime = currentTime;
        
        eventType = PNEventAppStart;
        
        [userDefaults setObject:_sessionId forKey:PNUserDefaultsLastSessionID];
        [userDefaults setDouble:_sessionStartTime forKey:PNUserDefaultsLastSessionStartTime];
        [userDefaults setObject:_userId forKey:PNUserDefaultsLastUserID];
        [userDefaults synchronize];
    } else {
        _sessionId = [userDefaults objectForKey:PNUserDefaultsLastSessionID];
        // Always create a new Instance Id
        _instanceId = [[PNRandomGenerator createRandomHex] retain];
        _sessionStartTime = [userDefaults doubleForKey:PNUserDefaultsLastSessionStartTime];
        
        eventType = PNEventAppPage;
    }
    
    /** Send appStart or appPage event */
    PNBasicEvent *ev = [[PNBasicEvent alloc] init: eventType
                                    applicationId:_applicationId
                                           userId:_userId
                                         cookieId:_cookieId
                                internalSessionId:_sessionId
                                       instanceId:_instanceId
                                   timeZoneOffset:_timeZoneOffset];
    
    // Try to send and queue if unsuccessful
    [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
    [ev release];
}




/**
 * Pause.
 */
- (void) pause {
    @try {
        NSLog(@"pause called");
        
        if (_sessionState == PNSessionStatePaused)
            return;
        
        _sessionState = PNSessionStatePaused;
        
        [self stopEventTimer];
        
        PNBasicEvent *ev = [[[PNBasicEvent alloc] init:PNEventAppPause applicationId:_applicationId userId:_userId cookieId:_cookieId internalSessionId:_sessionId instanceId:_instanceId sessionStartTime:_sessionStartTime sequence:_sequence clicks:_clicks totalClicks:_totalClicks keys:_keys totalKeys:_totalKeys collectMode:_collectMode] autorelease];
        
        _pauseTime = [[NSDate date] timeIntervalSince1970];
        
        _sequence += 1;
        
        [ev setSequence:_sequence];
        [ev setSessionStartTime:_sessionStartTime];
        
        // Try to send and queue if unsuccessful
        [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}

/**
 * Resume
 */
- (void) resume {
    @try {
        NSLog(@"resume called");
        
        if (_sessionState == PNSessionStateStarted) {
            return;
        }
        
        [self startEventTimer];
        
        _sessionState = PNSessionStateStarted;
        
        PNBasicEvent *ev = [[[PNBasicEvent alloc] init:PNEventAppResume applicationId:_applicationId userId:_userId cookieId:_cookieId internalSessionId:_sessionId instanceId:_instanceId sessionStartTime:_sessionStartTime sequence:_sequence clicks:_clicks totalClicks:_totalClicks keys:_keys totalKeys:_totalKeys collectMode:_collectMode] autorelease];
        
        [ev setPauseTime:_pauseTime];
        [ev setSessionStartTime:_sessionStartTime];
        [ev setSequence:_sequence];
    
        // Try to send and queue if unsuccessful
        [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}

/**
 * Stop.
 *
 * @return the API Result
 */
- (void) stop {
    @try {
        NSLog(@"stop called");
        
        if (_sessionState == PNSessionStateStopped) {
            return;
        }
        
        // Currently Session is only stopped when the application quits.
        _sessionState = PNSessionStateStopped;
        
        [self stopEventTimer];
        
        [[NSNotificationCenter defaultCenter] removeObserver: self];
        
        // Store Event List
        if (![NSKeyedArchiver archiveRootObject: _playnomicsEventList toFile:PNFileEventArchive]) {
            NSLog(@"Playnomics: Could not save event list");
        }
        
        return;
    }
    @catch (NSException *exception) {
        NSLog(@"stop error: %@", exception.description);
        return;
    }
}

#pragma mark - Timed Event Sending
- (void) startEventTimer {
    @try {
        [self stopEventTimer];
        
        _eventTimer = [[NSTimer scheduledTimerWithTimeInterval:PNUpdateTimeInterval target:self selector:@selector(consumeQueue) userInfo:nil repeats:YES] retain];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
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
        NSLog(@"error: %@", exception.description);
    }
}

- (void) consumeQueue {
    @try {
        NSLog(@"consumeQueue");
        if (_sessionState == PNSessionStateStarted) {
            _sequence++;
            
            PNBasicEvent *ev = [[[PNBasicEvent alloc] init:PNEventAppRunning
                                             applicationId:_applicationId
                                                    userId:_userId
                                                  cookieId:_cookieId
                                         internalSessionId:_sessionId
                                                instanceId:_instanceId
                                          sessionStartTime:_sessionStartTime
                                                  sequence:_sequence
                                                    clicks:_clicks
                                               totalClicks:_totalClicks
                                                      keys:_keys
                                                 totalKeys:_totalKeys
                                               collectMode:_collectMode] autorelease];
            [_playnomicsEventList addObject:ev];
            
            NSLog(@"ev:%@", ev);
            NSLog(@"self.playnomicsEventList:%@", _playnomicsEventList);
            
            // Reset keys/clicks
            _keys = 0;
            _clicks = 0;
        }
        
        for (PNEvent *ev in _playnomicsEventList) {
            [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}



- (void) sendOrQueueEvent:(PNEvent *)pe {
    if (_sessionState != PNSessionStateStarted) {
        //add the event to our queue if we are here
        if(pe != nil){
            [_playnomicsEventList addObject:pe];
        }
    }
    
    // Try to send and queue if unsuccessful
    [_eventSender sendEventToServer:pe withEventQueue:_playnomicsEventList];
}

#pragma mark - Application Event Handlers
- (void) onKeyPressed: (NSNotification *) notification {
    _keys += 1;
    _totalKeys += 1;
}

- (void) onTouchDown: (UIEvent *) event {
    _clicks += 1;
    _totalClicks += 1;
}

- (void) onApplicationWillResignActive: (NSNotification *) notification {
    [self pause];
}

- (void) onApplicationDidBecomeActive: (NSNotification *) notification {
    [self resume];
}

- (void) onApplicationWillTerminate: (NSNotification *) notification {
    [self stop];
}

-(void) onApplicationDidLaunch: (NSNotification *) note{
    
    //if the application was not running we can  capture the notification here
    // otherwise, we are dependent on the developer impplementing pushNotificationsWithPayload in the app delegate
    if ([note userInfo] != nil && [note.userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey] != nil) {
        NSDictionary *push = [note.userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        NSLog(@"sending impression from onApplicationDidLaunch\r\n---> %@", push);
        [[PlaynomicsSession sharedInstance] pushNotificationsWithPayload:push];
    }
}

#pragma mark - API request methods

- (void)  transactionWithUSDPrice: (NSNumber*) priceInUSD quantity: (NSInteger) quantity  {
    @try {
        if(![self assertSessionHasStarted]){
            return;
        }
        
        int transactionId = arc4random();
        
        NSArray *currencyTypes = [NSArray arrayWithObject: [NSNumber numberWithInt: PNCurrencyUSD]];
        NSArray *currencyValues = [NSArray arrayWithObject: priceInUSD];
        NSArray *currencyCategories = [NSArray arrayWithObject: [NSNumber numberWithInt:PNCurrencyCategoryReal]];
        
        NSString* itemId = @"PNUSDSpent";
        
        PNTransactionEvent* ev = [[[PNTransactionEvent alloc] init:PNEventTransaction applicationId: self.applicationId userId: self.userId cookieId: self.cookieId transactionId: transactionId itemId: itemId quantity: quantity type: PNTransactionBuyItem otherUserId: nil currencyTypes: currencyTypes currencyValues: currencyValues currencyCategories: currencyCategories] autorelease];
        
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        [self sendOrQueueEvent:ev];
    }
    @catch (NSException* exception) {
        [PNLogger logException:exception withMessage:@"Could not send transaction."];
    }
}

- (void) milestone: (PNMilestoneType) milestoneType {
    @try {
        if(![self assertSessionHasStarted]){
            return;
        }
        
        //generate a random number for now
        int milestoneId = arc4random();
        PNMilestoneEvent* ev = [[[PNMilestoneEvent alloc] init:PNEventMilestone
                                                 applicationId:[self applicationId]
                                                        userId:[self userId]
                                                      cookieId:[self cookieId]
                                                   milestoneId:milestoneId
                                                 milestoneType:milestoneType] autorelease];
        ev.internalSessionId = [self sessionId];
        [self sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        [PNLogger logException:exception withMessage:@"Could not send milestone."];
    }
}


- (void) enablePushNotificationsWithToken:(NSData*)deviceToken {
    @try {
        if(![self assertSessionHasStarted]){
            return;
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *oldToken = [userDefaults stringForKey:PNUserDefaultsLastDeviceToken];
        NSString *newToken = [self stringForTrimmedDeviceToken:deviceToken];
        
        if (![newToken isEqualToString:oldToken]) {
            [userDefaults setObject:newToken forKey:PNUserDefaultsLastDeviceToken];
            [userDefaults synchronize];
            NSLog(@"Updating device token from %@ to %@", oldToken, newToken);
            
            PNAPSNotificationEvent *ev = [[PNAPSNotificationEvent alloc] init:PNEventPushNotificationToken
                                                                applicationId:[self applicationId]
                                                                       userId:[self userId]
                                                                     cookieId:[self cookieId]
                                                                  deviceToken:deviceToken];
            ev.internalSessionId = self.sessionId;
            [self sendOrQueueEvent: ev];
        }
    }
    @catch (NSException *exception) {
       [PNLogger logException:exception withMessage:@"Could not send milestone."];
    }
}

- (void) pushNotificationsWithPayload:(NSDictionary *)payload {
    @try {
        if(![self assertSessionHasStarted]){
            return;
        }
        
        if ([payload valueForKeyPath:PushResponse_InteractionUrl]!=nil) {
            NSString *lastDeviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:PNUserDefaultsLastDeviceToken];
            
            NSString *callbackurl = [payload valueForKeyPath:PushResponse_InteractionUrl];
            // append required parameters to the interaction tracking url
            NSString *trackedCallback = [callbackurl stringByAppendingFormat:@"&%@=%lld&%@=%@&%@=%@&%@=%@",
                                         PushInteractionUrl_AppIdParam, self.applicationId,
                                         PushInteractionUrl_UserIdParam, self.userId,
                                         PushInteractionUrl_BreadcrumbIdParam, self.cookieId,
                                         PushInteractionUrl_PushTokenParam, lastDeviceToken];
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            // only append the flag "pushIgnored" if the app is in Active state and either
            // the game developer doesn't pass us the flag "pushIgnored" in the dictionary or they do pass the flag and set it to YES
            if (state == UIApplicationStateActive && !([payload objectForKey:PushInteractionUrl_IgnoredParam] && [[payload objectForKey:PushInteractionUrl_IgnoredParam] isEqual:[NSNumber numberWithBool:NO]])) {
                trackedCallback = [trackedCallback stringByAppendingFormat:@"&%@",PushInteractionUrl_IgnoredParam];
            }
            
            [_callback submitRequestToServer: trackedCallback];
        }
    }
    @catch (NSException *exception) {
        [PNLogger logException:exception withMessage:@"Could not send process push notification data."];
    }   
}

- (void) errorReport:(PNErrorDetail*)errorDetails
{
    @try {
        PNErrorEvent *ev = [[[PNErrorEvent alloc] init:PNEventError applicationId: self.applicationId userId: self.userId cookieId: self.cookieId errorDetails:errorDetails] autorelease];
        
        ev.internalSessionId = [self sessionId];
        [self sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}


-(NSString*) stringForTrimmedDeviceToken:(NSData*)deviceToken{
    NSString *adeviceToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    adeviceToken = [adeviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    return adeviceToken;
}

- (void)performActionOnIdsChangedWithBreadcrumbId: (NSString*) breadcrumbId andLimitAdvertising: (NSString*) limitAdvertising andIDFA: (NSString*) idfa andIDFV: (NSString*) idfv {
    
    NSLog(@"User Info was modified so sending a userInfo update");
    PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
    PNUserInfoEvent *userInfoEvent = [[PNUserInfoEvent alloc] initWithAdvertisingInfo:s.applicationId userId:[s.userId length] == 0 ? breadcrumbId : s.userId cookieId:breadcrumbId type:PNUserInfoTypeUpdate limitAdvertising:limitAdvertising idfa:idfa idfv:idfv];
    
    userInfoEvent.internalSessionId = s.sessionId;
    [self sendOrQueueEvent:userInfoEvent];
}

-(BOOL) assertSessionHasStarted{
    if(_sessionState != PNSessionStateStarted){
        [PNLogger logMessage:@"PlayRM session could not be started! Can't send data to Playnomics API."];
        return NO;
    }
    return YES;
}
@end

