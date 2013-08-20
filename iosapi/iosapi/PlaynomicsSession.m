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
#import "PNSocialEvent.h"
#import "PNTransactionEvent.h"
#import "PNMilestoneEvent.h"
#import "PNAPSNotificationEvent.h"
#import "PNErrorEvent.h"
#import "PlaynomicsSession+Exposed.h"
#import "PlaynomicsMessaging+Exposed.h"
#import "PNUserInfo.h"

@interface PlaynomicsSession(){
    
    PNSessionState _sessionState;
    
    NSTimer *_eventTimer;
    PNEventSender *_eventSender;
    NSMutableArray *_playnomicsEventList;
    
    bool _testMode;
    
    /** Tracking values */
    int _collectMode;
	int _sequence;
    signed long long _applicationId;
    NSString *_userId;
	NSString *_cookieId; // TODO: Doc says this should be a 64 bit number
	NSString *_sessionId;
	NSString *_instanceId;
	
    NSString* _testEventsUrl;
    NSString* _prodEventsUrl;
    NSString* _overrideEventsUrl;
    
    NSString* _testMessagingUrl;
    NSString* _prodMessagingUrl;
    NSString* _overrideMessagingUrl;
    
    NSTimeInterval _sessionStartTime;
	NSTimeInterval _pauseTime;
    
	int _timeZoneOffset;
	int _clicks;
	int _totalClicks;
	int _keys;
	int _totalKeys;
}
@property (atomic, readonly) PNEventSender * eventSender;
@property (atomic, readonly) NSMutableArray * playnomicsEventList;
@property (nonatomic, retain) PlaynomicsCallback *callback;
- (PNAPIResult) startWithApplicationId:(signed long long) applicationId;
- (PNAPIResult) startWithApplicationId:(signed long long) applicationId userId: (NSString *) userId;
- (PNAPIResult) sendOrQueueEvent: (PNEvent *) pe;

- (PNAPIResult) stop;
- (void) pause;
- (void) resume;
- (PNAPIResult) startSessionWithApplicationId: (signed long long) applicationId;

- (void) startEventTimer;
- (void) stopEventTimer;
- (void) consumeQueue;

@end

@implementation PlaynomicsSession
@synthesize applicationId=_applicationId;
@synthesize userId=_userId;
@synthesize cookieId=_cookieId;
@synthesize sessionId=_sessionId;
@synthesize sessionState=_sessionState;
@synthesize testMode=_testMode;
@synthesize eventSender=_eventSender;
@synthesize playnomicsEventList=_playnomicsEventList;
@synthesize overrideEventsUrl=_overrideEventsUrl;
@synthesize overrideMessagingUrl=_overrideMessagingUrl;

//Singleton
+ (PlaynomicsSession *)sharedInstance{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

+ (void) setTestMode: (bool) testMode {
    @try {
        [[PlaynomicsSession sharedInstance] setTestMode: testMode];
    }
    @catch (NSException *exception) {
        NSLog(@"setTestMode error: %@", exception.description);
    }
}

+ (bool) getTestMode{
    return [[PlaynomicsSession sharedInstance] testMode];
}

+(void) setOverrideEventsUrl:(NSString *)url{
    [[PlaynomicsSession sharedInstance] setOverrideEventsUrl: url];
}

+(NSString*) getOverrideEventsUrl{
    return [[PlaynomicsSession sharedInstance] overrideEventsUrl];
}

+(void) setOverrideMessagingUrl:(NSString *)url{
    [[PlaynomicsSession sharedInstance] setOverrideMessagingUrl: url];
}
            
+(NSString*) getOverrideMessagingUrl{
    return [[PlaynomicsSession sharedInstance] overrideEventsUrl];
}

+(NSString*) getSDKVersion{
    return PNPropertyVersion;
}

+ (PNAPIResult) startWithApplicationId:(signed long long) applicationId userId: (NSString *) userId {
    @try {
        return [[PlaynomicsSession sharedInstance] startWithApplicationId:applicationId userId:userId];
    }
    @catch (NSException *exception) {
        NSLog(@"startWithApplicationId error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) startWithApplicationId:(signed long long) applicationId {
    @try {
        return [[PlaynomicsSession sharedInstance] startWithApplicationId:applicationId];
    }
    @catch (NSException *exception) {
        NSLog(@"startWithApplicationId error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}



+ (PNAPIResult) stop {
    @try {
        return [[PlaynomicsSession sharedInstance] stop];
    }
    @catch (NSException *exception) {
        NSLog(@"stop error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
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
        
        self.callback = [[[PlaynomicsCallback alloc] init] autorelease];
    }
    
    return self;
}

- (void) dealloc {
    [_eventSender release];
	[_playnomicsEventList release];
    
    /** Tracking values */
    [_userId release];
	[_cookieId release];
	[_sessionId release];
	[_instanceId release];
    
    [_overrideEventsUrl release];
    [_overrideMessagingUrl release];
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
- (PNAPIResult) startWithApplicationId:(signed long long) applicationId userId: (NSString *) userId {
    _userId = [userId retain];
    return [self startWithApplicationId:applicationId];
}

- (PNAPIResult) startWithApplicationId:(signed long long) applicationId {
    NSLog(@"startWithApplicationId");
    
    if (_sessionState == PNSessionStateStarted) {
        return PNAPIResultAlreadyStarted;
    }
    
    // If paused, resume and get out of here
    if (_sessionState == PNSessionStatePaused) {
        [self resume];
        return PNAPIResultSessionResumed;
    }
    
    _applicationId = applicationId;
    
    PNAPIResult resval = [self startSessionWithApplicationId: applicationId];
    
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
        [self.playnomicsEventList addObjectsFromArray:storedEvents];
        
        // Remove archive so as not to pick up bad events when starting up next time.
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:PNFileEventArchive error:nil];
    }
    
    return resval;
}

- (PNAPIResult) startSessionWithApplicationId: (signed long long) applicationId {
    NSLog(@"startSessionWithApplicationId");
    
    /** Setting Session variables */
    
    _sessionState = PNSessionStateStarted;
    _applicationId = applicationId;
    
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
    PNBasicEvent *ev = [[PNBasicEvent alloc] init:eventType
                                    applicationId:_applicationId
                                           userId:_userId
                                         cookieId:_cookieId
                                internalSessionId:_sessionId
                                       instanceId:_instanceId
                                   timeZoneOffset:_timeZoneOffset];
    
    // Try to send and queue if unsuccessful
    [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
    [ev release];
    
    return PNAPIResultSent;
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
        
        PNBasicEvent *ev = [[[PNBasicEvent alloc] init:PNEventAppPause
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
        
        PNBasicEvent *ev = [[[PNBasicEvent alloc] init:PNEventAppResume
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
- (PNAPIResult) stop {
    @try {
        NSLog(@"stop called");
        
        if (_sessionState == PNSessionStateStopped) {
            return PNAPIResultAlreadyStopped;
        }
        
        // Currently Session is only stopped when the application quits.
        _sessionState = PNSessionStateStopped;
        
        [self stopEventTimer];
        
        [[NSNotificationCenter defaultCenter] removeObserver: self];
        
        // Store Event List
        if (![NSKeyedArchiver archiveRootObject:self.playnomicsEventList toFile:PNFileEventArchive]) {
            NSLog(@"Playnomics: Could not save event list");
        }
        
        return PNAPIResultStopped;
    }
    @catch (NSException *exception) {
        NSLog(@"stop error: %@", exception.description);
        return PNAPIResultFailUnkown;
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
            [self.playnomicsEventList addObject:ev];
            
            NSLog(@"ev:%@", ev);
            NSLog(@"self.playnomicsEventList:%@", self.playnomicsEventList);
            
            // Reset keys/clicks
            _keys = 0;
            _clicks = 0;
        }
        
        for (PNEvent *ev in self.playnomicsEventList) {
            [_eventSender sendEventToServer:ev withEventQueue:_playnomicsEventList];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
    }
}



- (PNAPIResult) sendOrQueueEvent:(PNEvent *)pe {
    if (_sessionState != PNSessionStateStarted) {
        //add the event to our queue if we are here
        if(pe!=nil)
            [self.playnomicsEventList addObject:pe];
        
        return PNAPIResultStartNotCalled;
    }
    
    // Try to send and queue if unsuccessful
    [_eventSender sendEventToServer:pe withEventQueue:_playnomicsEventList];
    return PNAPIResultSent;
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
-(void) onApplicationDidLaunch: (NSNotification *) note
{
    
    //if the application was not running we can  capture the notification here
    // otherwise, we are dependent on the developer impplementing pushNotificationsWithPayload in the app delegate
    if ([note userInfo] != nil && [note.userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey] != nil) {
        NSDictionary *push = [note.userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        NSLog(@"sending impression from onApplicationDidLaunch\r\n---> %@", push);
        [PlaynomicsSession pushNotificationsWithPayload:push];
    }
}



#pragma mark - API request methods
+ (PNAPIResult) userInfoForType: (PNUserInfoType) type
                        country: (NSString *) country
                    subdivision: (NSString *) subdivision
                            sex: (PNUserInfoSex) sex
                       birthday: (NSDate *) birthday
                         source: (PNUserInfoSource) source
                 sourceCampaign: (NSString *) sourceCampaign
                    installTime: (NSDate *) installTime {
    @try {
        return [PlaynomicsSession userInfoForType:type
                                          country:country
                                      subdivision:subdivision
                                              sex:sex
                                         birthday:birthday
                                   sourceAsString:[PNUtil PNUserInfoSourceDescription:source]
                                   sourceCampaign:sourceCampaign
                                      installTime:installTime];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) userInfoForType: (PNUserInfoType) type
                        country: (NSString *) country
                    subdivision: (NSString *) subdivision
                            sex: (PNUserInfoSex) sex
                       birthday: (NSDate *) birthday
                 sourceAsString: (NSString *) source
                 sourceCampaign: (NSString *) sourceCampaign
                    installTime: (NSDate *) installTime {
    @try {
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNUserInfoEvent *ev = [[[PNUserInfoEvent alloc] init:s.applicationId
                                                      userId:s.userId
                                                    cookieId:s.cookieId
                                                        type:type
                                                     country:country
                                                 subdivision:subdivision
                                                         sex:sex
                                                    birthday:[birthday timeIntervalSince1970]
                                                      source:source
                                              sourceCampaign:sourceCampaign
                                                 installTime:[installTime timeIntervalSince1970]] autorelease];
        
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) transactionWithId: (signed long long) transactionId
                           itemId: (NSString *) itemId
                         quantity: (double) quantity
                             type: (PNTransactionType) type
                      otherUserId: (NSString *) otherUserId
                     currencyType: (PNCurrencyType) currencyType
                    currencyValue: (double) currencyValue
                 currencyCategory: (PNCurrencyCategory) currencyCategory {
    @try {
        NSArray *currencyTypes = [NSArray arrayWithObject: [NSNumber numberWithInt: currencyType]];
        NSArray *currencyValues = [NSArray arrayWithObject:[NSNumber numberWithDouble:currencyValue]];
        NSArray *currencyCategories = [NSArray arrayWithObject: [NSNumber numberWithInt:currencyCategory]];
        
        return [PlaynomicsSession transactionWithId:transactionId
                                             itemId:itemId
                                           quantity:quantity
                                               type:type
                                        otherUserId:otherUserId
                                      currencyTypes:currencyTypes
                                     currencyValues:currencyValues
                                 currencyCategories:currencyCategories];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) transactionWithId: (signed long long) transactionId
                           itemId: (NSString *) itemId
                         quantity: (double) quantity
                             type: (PNTransactionType) type
                      otherUserId: (NSString *) otherUserId
             currencyTypeAsString: (NSString *) currencyType
                    currencyValue: (double) currencyValue
                 currencyCategory: (PNCurrencyCategory) currencyCategory {
    @try {
        NSArray *currencyTypes = [NSArray arrayWithObject: currencyType];
        NSArray *currencyValues = [NSArray arrayWithObject:[NSNumber numberWithDouble:currencyValue]];
        NSArray *currencyCategories = [NSArray arrayWithObject: [NSNumber numberWithInt:currencyCategory]];
        
        return [PlaynomicsSession transactionWithId:transactionId
                                             itemId:itemId
                                           quantity:quantity
                                               type:type
                                        otherUserId:otherUserId
                                      currencyTypes:currencyTypes
                                     currencyValues:currencyValues
                                 currencyCategories:currencyCategories];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}


+ (PNAPIResult) transactionWithId:(signed long long) transactionId
                           itemId: (NSString *) itemId
                         quantity: (double) quantity
                             type: (PNTransactionType) type
                      otherUserId: (NSString *) otherUserId
                    currencyTypes: (NSArray *) currencyTypes
                   currencyValues: (NSArray *) currencyValues
               currencyCategories: (NSArray *) currencyCategories {
    @try {
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNTransactionEvent *ev = [[[PNTransactionEvent alloc] init:PNEventTransaction
                                                     applicationId:s.applicationId
                                                            userId:s.userId
                                                          cookieId:s.cookieId
                                                     transactionId:transactionId
                                                            itemId:itemId
                                                          quantity:quantity
                                                              type:type
                                                       otherUserId:otherUserId
                                                     currencyTypes:currencyTypes
                                                    currencyValues:currencyValues
                                                currencyCategories:currencyCategories] autorelease];
        
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) invitationSentWithId: (signed long long) invitationId
                     recipientUserId: (NSString *) recipientUserId
                    recipientAddress: (NSString *) recipientAddress
                              method: (NSString *) method {
    @try {
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNSocialEvent *ev = [[[PNSocialEvent alloc] init:PNEventInvitationSent
                                           applicationId:s.applicationId
                                                  userId:s.userId
                                                cookieId:s.cookieId
                                            invitationId:invitationId
                                         recipientUserId:recipientUserId
                                        recipientAddress:recipientAddress
                                                  method:method
                                                response:0] autorelease];
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) invitationResponseWithId: (signed long long) invitationId
                         recipientUserId: (NSString *) recipientUserId
                            responseType: (PNResponseType) responseType {
    @try {
        // TODO: recipientUserId should not be nil
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNSocialEvent *ev = [[[PNSocialEvent alloc] init:PNEventInvitationResponse
                                           applicationId:s.applicationId
                                                  userId:s.userId
                                                cookieId:s.cookieId
                                            invitationId:invitationId
                                         recipientUserId:recipientUserId
                                        recipientAddress:nil
                                                  method:nil
                                                response:responseType] autorelease];
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (PNAPIResult) milestoneWithId: (signed long long) milestoneId
                        andName: (NSString *) milestoneName {
    @try {
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNMilestoneEvent *ev = [[[PNMilestoneEvent alloc] init:PNEventMilestone
                                                 applicationId:s.applicationId
                                                        userId:s.userId
                                                      cookieId:s.cookieId
                                                   milestoneId:milestoneId
                                                 milestoneName:milestoneName] autorelease];
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}


+ (PNAPIResult) enablePushNotificationsWithToken:(NSData*)deviceToken {
    @try {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *oldToken = [userDefaults stringForKey:PNUserDefaultsLastDeviceToken];
        NSString *newToken = [PlaynomicsSession stringForTrimmedDeviceToken:deviceToken];
        
        if (![newToken isEqualToString:oldToken]) {
            [userDefaults setObject:newToken forKey:PNUserDefaultsLastDeviceToken];
            [userDefaults synchronize];
            NSLog(@"Updating device token from %@ to %@", oldToken, newToken);
            PlaynomicsSession *s =[PlaynomicsSession sharedInstance];
            PNAPSNotificationEvent *ev = [[PNAPSNotificationEvent alloc] init:PNEventPushNotificationToken
                                                                applicationId:s.applicationId
                                                                       userId:s.userId
                                                                     cookieId:s.cookieId
                                                                  deviceToken:deviceToken];
            ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
            return [s sendOrQueueEvent:ev];
        }
        
        // device token has not changed so no need to make a call
        return PNAPIResultNotSent;
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
}

+ (void) pushNotificationsWithPayload:(NSDictionary*)payload {
    PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
    
    if ([payload valueForKeyPath:PushResponse_InteractionUrl]!=nil) {
        NSString *lastDeviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:PNUserDefaultsLastDeviceToken];
        
        NSString *callbackurl = [payload valueForKeyPath:PushResponse_InteractionUrl];
        // append required parameters to the interaction tracking url
        NSString *trackedCallback = [callbackurl stringByAppendingFormat:@"&%@=%lld&%@=%@&%@=%@&%@=%@",
                                     PushInteractionUrl_AppIdParam, [s applicationId],
                                     PushInteractionUrl_UserIdParam, [s userId],
                                     PushInteractionUrl_BreadcrumbIdParam, [s cookieId],
                                     PushInteractionUrl_PushTokenParam, lastDeviceToken];
        
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        // only append the flag "pushIgnored" if the app is in Active state and either
        // the game developer doesn't pass us the flag "pushIgnored" in the dictionary or they do pass the flag and set it to YES
        if (state == UIApplicationStateActive && !([payload objectForKey:PushInteractionUrl_IgnoredParam] && [[payload objectForKey:PushInteractionUrl_IgnoredParam] isEqual:[NSNumber numberWithBool:NO]])) {
            trackedCallback = [trackedCallback stringByAppendingFormat:@"&%@",PushInteractionUrl_IgnoredParam];
        }
        
        [s.callback submitRequestToServer: trackedCallback];
    }
}

+ (PNAPIResult) errorReport:(PNErrorDetail*)errorDetails
{
    @try {
        PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
        
        PNErrorEvent *ev = [[[PNErrorEvent alloc] init:PNEventError
                                         applicationId:s.applicationId
                                                userId:s.userId
                                              cookieId:s.cookieId
                                          errorDetails:errorDetails] autorelease];
        
        ev.internalSessionId = [[PlaynomicsSession sharedInstance] sessionId];
        return [s sendOrQueueEvent:ev];
    }
    @catch (NSException *exception) {
        NSLog(@"error: %@", exception.description);
        return PNAPIResultFailUnkown;
    }
    return PNAPIResultFailUnkown;
}

+(NSString*)stringForTrimmedDeviceToken:(NSData*)deviceToken
{
    NSString *adeviceToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    adeviceToken = [adeviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    return adeviceToken;
}

+(void) onTouchDown:(UIEvent *)event{
    [[PlaynomicsSession sharedInstance] onTouchDown:event];
}

- (void)performActionOnIdsChangedWithBreadcrumbId: (NSString*) breadcrumbId
                              andLimitAdvertising: (NSString*) limitAdvertising
                                          andIDFA: (NSString*) idfa
                                          andIDFV: (NSString*) idfv {
    NSLog(@"User Info was modified so sending a userInfo update");
    PlaynomicsSession * s =[PlaynomicsSession sharedInstance];
    PNUserInfoEvent *userInfoEvent = [[PNUserInfoEvent alloc] initWithAdvertisingInfo:s.applicationId
                                                                               userId:[s.userId length] == 0 ? breadcrumbId : s.userId
                                                                              cookieId:breadcrumbId
                                                                                  type:PNUserInfoTypeUpdate
                                                                      limitAdvertising:limitAdvertising
                                                                                  idfa:idfa
                                                                                  idfv:idfv];
    userInfoEvent.internalSessionId = s.sessionId;
    [self sendOrQueueEvent:userInfoEvent];
}

@end

