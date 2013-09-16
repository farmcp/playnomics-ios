//
//  Playnomics.h
//
//  Created by Jared Jenkins on 8/23/13.
//
//

#import <Foundation/Foundation.h>
#import "PNLogger.h"

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
};


@protocol PlaynomicsFrameDelegate <NSObject>
@optional
-(void) onTouch: (NSDictionary*) jsonData;
-(void) onClose: (NSDictionary*) jsonData;
-(void) onShow: (NSDictionary*) jsonData;
-(void) onDidFailToRender;
@end

@interface Playnomics : NSObject
+ (void) setLoggingLevel :(PNLoggingLevel) level;

+ (void) overrideMessagingURL: (NSString*) messagingUrl;

+ (void) overrideEventsURL: (NSString*) messagingUrl;
//Engagement
+ (BOOL) startWithApplicationId:(unsigned long long) applicationId;

+ (BOOL) startWithApplicationId:(unsigned long long) applicationId
                      andUserId: (NSString*) userId;

+ (void) onUIEventReceived: (UIEvent*) event;
//Explicit Events
+ (void) milestone: (PNMilestoneType) milestoneType;

+ (void) transactionWithUSDPrice: (NSNumber*) priceInUSD
                        quantity: (NSInteger) quantity;

+ (void) attributeInstallTo:(NSString *) source;

+ (void) attributeInstallTo:(NSString *) source withCampaign: (NSString*) campaign;

+ (void) attributeInstallTo:(NSString *) source withCampaign: (NSString*) campaign onInstallDate: (NSDate *) installDate;


//Push Notifications
+ (void) enablePushNotificationsWithToken: (NSData*)deviceToken;

+ (void) pushNotificationsWithPayload: (NSDictionary*)payload;
//Messaging
+ (void) preloadFramesWithIds: (NSString *)firstFrameId, ... NS_REQUIRES_NIL_TERMINATION;

+ (void) showFrameWithId:(NSString *) frameId;

+ (void) showFrameWithId:(NSString *) frameId
                delegate:(id<PlaynomicsFrameDelegate>) delegate;

+ (void) hideFrameWithId:(NSString *) frameId;
@end

@interface PNApplication : UIApplication<UIApplicationDelegate>
- (void) sendEvent:(UIEvent *)event;
@end