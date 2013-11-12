//  Playnomics PlayRM SDK
//  PlaynomicsSession.h
//  Copyright (c) 2012 Playnomics. All rights reserved.
//  Please see http://integration.playnomics.com for instructions.
//  Please contact support@playnomics.com for assistance.

#import <UIKit/UIKit.h>
#import "Playnomics.h"
#import "PNGeneratedHexId.h"
#import "PNCache.h"
#import "PNDeviceManager.h"

typedef enum {
    PNSessionStateUnkown,
    PNSessionStateStarted,
    PNSessionStatePaused,
    PNSessionStateStopped
} PNSessionState;


@interface PNSession : NSObject

@property (atomic, assign) bool testMode;
@property (atomic, copy) NSString *overrideEventsUrl;
@property (atomic, copy) NSString *overrideMessagingUrl;

@property (atomic, readonly) NSString *sdkVersion;

@property (atomic, assign) signed long long applicationId;
@property (atomic, copy) NSString *userId;

@property (nonatomic, readonly) NSString *cookieId;
@property (nonatomic, readonly) PNGeneratedHexId *sessionId;
@property (nonatomic, readonly) PNGeneratedHexId *instanceId;
@property (nonatomic, readonly) PNSessionState state;

@property (retain) PNCache *cache;


+ (PNSession *) sharedInstance;

- (NSString *) getMessagingUrl;
- (NSString *) getEventsUrl;

//Application Lifecycle
- (void) start;
- (void) pause;
- (void) resume;
- (void) stop;
//Explicit Events
- (void) milestone: (PNMilestoneType) milestoneType;

- (void) transactionWithUSDPrice:(NSNumber *) priceInUSD
                        quantity:(NSInteger) quantity;

- (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString*) campaign
                    onInstallDate:(NSDate *) installDate;

- (void) pingUrlForCallback:(NSString *) url;
//push notifications
- (void) enablePushNotificationsWithToken:(NSData *) deviceToken;
- (void) pushNotificationsWithPayload:(NSDictionary *) payload;
//UI Events/Users/jaredjenkins/Projects/mobile/playnomics-ios/iosapi/iosapi/PNSession.m
- (void) onUIEventReceived:(UIEvent *) event;
//Messaging
- (void) preloadFramesWithIds:(NSSet *) frameIDs;

- (void) showFrameWithId:(NSString *) frameId;
- (void) showFrameWithId:(NSString *) frameId
                delegate:(id<PlaynomicsPlacementDelegate>) delegate;
- (void) hideFrameWithID:(NSString *) frameId;
- (void) setFrameParentView:(UIView *) parentView;
@end

