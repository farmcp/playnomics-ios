//
//  PlaynomicsSession+Exposed.h
//  iosapi
//
//  Created by Martin Harkins on 6/27/12.
//  Copyright (c) 2012 Grio. All rights reserved.
//

#ifndef iosapi_PlaynomicsSession_Exposed_h
#define iosapi_PlaynomicsSession_Exposed_h
#import "PNUserInfo.h"
#import "PNErrorEvent.h"

/**
 *  Only use this within the Static Lib.
 */

@interface PlaynomicsSession () <PNUserInfoChangeActionHandler>

@property (nonatomic, assign) bool testMode;
@property (nonatomic, copy) NSString* overrideEventsUrl;
@property (nonatomic, copy) NSString* overrideMessagingUrl;
@property (nonatomic, readonly) NSString* sdkVersion;
@property (nonatomic, readonly) signed long long applicationId;
@property (nonatomic, readonly) NSString * userId;
@property (nonatomic, readonly) NSString * cookieId;
@property (nonatomic, readonly) NSString * sessionId;
@property (nonatomic, readonly) PNSessionState sessionState;

+ (PlaynomicsSession *)sharedInstance;
+ (void) errorReport:(PNErrorDetail*)errorDetails;

- (void) onKeyPressed: (NSNotification *) notification;
- (void) onTouchDown: (UIEvent *) event;
- (void) onApplicationWillResignActive: (NSNotification *) notification;
- (void) onApplicationDidBecomeActive: (NSNotification *) notification;
- (void) onApplicationWillTerminate: (NSNotification *) notification;

- (NSString*) getMessagingUrl;
- (NSString*) getEventsUrl;
@end

#endif
