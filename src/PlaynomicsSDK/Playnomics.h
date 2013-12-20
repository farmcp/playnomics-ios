//
//  Playnomics.h
//
//  Created by Jared Jenkins on 8/23/13.
//
//

#import <Foundation/Foundation.h>
#import "PNLogger.h"
#include <AvailabilityMacros.h>

//this is available in iOS 6 and above, add this in for iOS 5 and below
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

typedef NS_ENUM(int, PNMilestoneType){
    PNMilestoneCustom1 = 1,
    PNMilestoneCustom2 = 2,
    PNMilestoneCustom3 = 3,
    PNMilestoneCustom4 = 4,
    PNMilestoneCustom5 = 5,
    PNMilestoneCustom6 = 6,
    PNMilestoneCustom7 = 7,
    PNMilestoneCustom8 = 8,
    PNMilestoneCustom9 = 9,
    PNMilestoneCustom10 = 10,
    PNMilestoneCustom11 = 11,
    PNMilestoneCustom12 = 12,
    PNMilestoneCustom13 = 13,
    PNMilestoneCustom14 = 14,
    PNMilestoneCustom15 = 15,
    PNMilestoneCustom16 = 16,
    PNMilestoneCustom17 = 17,
    PNMilestoneCustom18 = 18,
    PNMilestoneCustom19 = 19,
    PNMilestoneCustom20 = 20,
    PNMilestoneCustom21 = 21,
    PNMilestoneCustom22 = 22,
    PNMilestoneCustom23 = 23,
    PNMilestoneCustom24 = 24,
    PNMilestoneCustom25 = 25
};

@protocol PlaynomicsBasePlacementDelegate <NSObject>
@optional
-(void) onDidFailToRender;
@end

@protocol PlaynomicsPlacementDelegate <PlaynomicsBasePlacementDelegate>
@optional
-(void) onTouch:(NSDictionary *) jsonData;
-(void) onClose:(NSDictionary *) jsonData;
-(void) onShow:(NSDictionary *) jsonData;
@end

@protocol PlaynomicsPlacementRawDelegate <PlaynomicsBasePlacementDelegate>
@optional
-(void) onTouch:(NSString *) rawJson;
-(void) onClose:(NSString *) rawJson;
-(void) onShow:(NSString *) rawJson;
@end

//this is strictly for backwards compatibility
@protocol PlaynomicsFrameDelegate <PlaynomicsPlacementDelegate>
@optional
@end

@interface Playnomics : NSObject
+ (void) setTestMode : (BOOL) testMode DEPRECATED_ATTRIBUTE;
+ (void) setLoggingLevel:(PNLoggingLevel) level;
+ (void) overrideMessagingURL:(NSString *) messagingUrl;
+ (void) overrideEventsURL:(NSString *) messagingUrl;
//Engagement
+ (BOOL) startWithApplicationId:(unsigned long long) applicationId;

+ (BOOL) startWithApplicationId:(unsigned long long) applicationId
                      andUserId:(NSString*) userId;

+ (void) onUIEventReceived: (UIEvent *) event;
//Explicit Events
+ (void) milestone:(PNMilestoneType) milestoneType DEPRECATED_ATTRIBUTE;
+ (void) customEventWithName:(NSString *) customEventName;

+ (void) transactionWithUSDPrice:(NSNumber *) priceInUSD
                        quantity:(NSInteger) quantity;

+ (void) attributeInstallToSource:(NSString *) source;

+ (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString *) campaign;

+ (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString *) campaign
                    onInstallDate:(NSDate *) installDate;


//Push Notifications
+ (void) enablePushNotificationsWithToken:(NSData *)deviceToken;

+ (void) pushNotificationsWithPayload:(NSDictionary *)payload;
//Messaging
+ (void) preloadFramesWithIds:(NSString *) firstFrameId, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_ATTRIBUTE;
+ (void) preloadPlacementsWithNames:(NSString *) firstPlacementName, ... NS_REQUIRES_NIL_TERMINATION;

+ (void) showFrameWithId:(NSString *) frameId DEPRECATED_ATTRIBUTE;
+ (void) showPlacementWithName:(NSString *) placementName;

+ (void) showFrameWithId:(NSString *) frameId
                delegate:(id<PlaynomicsPlacementDelegate>) delegate DEPRECATED_ATTRIBUTE;

+ (void) showPlacementWithName:(NSString *) placementName
                      delegate:(id<PlaynomicsPlacementDelegate>) delegate;

+ (void) showPlacementWithName:(NSString *)placementName
                   rawDelegate:(id<PlaynomicsPlacementRawDelegate>)delegate;

+ (void) hideFrameWithId:(NSString *) frameId DEPRECATED_ATTRIBUTE;
+ (void) hidePlacementWithName: (NSString *) placementName;

+ (void) setFrameParentView:(UIView *) parentView DEPRECATED_ATTRIBUTE;
+ (void) setPlacementParentView:(UIView *) parentView;

@end

@interface PNApplication : UIApplication<UIApplicationDelegate>
- (void) sendEvent:(UIEvent *)event;
@end