//
//  Playnomics.m
//  iosapi
//
//  Created by Jared Jenkins on 8/23/13.
//
//

#import "Playnomics.h"
#import "PNSession.h"

@implementation Playnomics

+(void) setLoggingLevel:(PNLoggingLevel)level{
    [PNLogger setLoggingLevel: level];
}

+ (void) overrideMessagingURL: (NSString *) messagingUrl{
    [PNSession sharedInstance].overrideMessagingUrl = messagingUrl;
}

+ (void) overrideEventsURL: (NSString *) eventsUrl{
    [PNSession sharedInstance].overrideEventsUrl = eventsUrl;
}

+(void) setTestMode : (BOOL) testMode{
}

+ (BOOL) startWithApplicationId:(unsigned long long) applicationId{
    PNSession *session = [PNSession sharedInstance];
    session.applicationId = applicationId;
    [session start];
    return session.state == PNSessionStateStarted;
}

+ (BOOL) startWithApplicationId:(unsigned long long) applicationId
                      andUserId: (NSString *) userId{
    PNSession *session = [PNSession sharedInstance];
    session.applicationId = applicationId;
    session.userId = userId;
    [session start];
    return session.state == PNSessionStateStarted;
}

+ (void) onUIEventReceived:(UIEvent *)event{
    [[PNSession sharedInstance] onUIEventReceived: event];
}

+ (void) milestone: (PNMilestoneType) milestoneType{
    [[PNSession sharedInstance] milestone: milestoneType];
}

+ (void) customEventWithName:(NSString *)customEventName {
    [[PNSession sharedInstance] customEventWithName: customEventName];
}

+ (void) transactionWithUSDPrice: (NSNumber *) priceInUSD
                        quantity: (NSInteger) quantity{
    [[PNSession sharedInstance] transactionWithUSDPrice:priceInUSD quantity: quantity];
}

+ (void) attributeInstallToSource:(NSString *) source{
    [[PNSession sharedInstance] attributeInstallToSource:source
                                            withCampaign:nil
                                           onInstallDate:nil];
}

+ (void) attributeInstallToSource:(NSString *) source
                     withCampaign: (NSString*) campaign{
    [[PNSession sharedInstance] attributeInstallToSource:source
                                            withCampaign:campaign
                                           onInstallDate:nil];
}

+ (void) attributeInstallToSource: (NSString *) source
                     withCampaign: (NSString *) campaign
                    onInstallDate: (NSDate *) installDate{
    [[PNSession sharedInstance] attributeInstallToSource:source
                                      withCampaign:campaign
                                     onInstallDate:installDate];
}

+ (void) enablePushNotificationsWithToken: (NSData *)deviceToken{
    [[PNSession sharedInstance] enablePushNotificationsWithToken: deviceToken];
}

+ (void) pushNotificationsWithPayload: (NSDictionary *)payload{
    [[PNSession sharedInstance] pushNotificationsWithPayload: payload];
}

+ (void) preloadFramesWithIds: (NSString *)firstFrameId, ...{
    NSMutableSet *frameIds = [NSMutableSet new];
    va_list args;
    va_start(args, firstFrameId);
    [frameIds addObject:firstFrameId];
   
    NSString* frameId;
    while( (frameId = va_arg(args, NSString *)) )
    {
        [frameIds addObject: frameId];
    }
    va_end(args);
    
    [[PNSession sharedInstance] preloadFramesWithIds: frameIds];
    [frameIds autorelease];
}

+ (void) preloadPlacementsWithNames:(NSString *)firstPlacementName, ...{
    //TODO: Refactor this
    NSMutableSet *placementNames = [NSMutableSet new];
    va_list args;
    va_start(args, firstPlacementName);
    [placementNames addObject:firstPlacementName];
    
    NSString* placementName;
    while( (placementName = va_arg(args, NSString *)) )
    {
        [placementNames addObject: placementName];
    }
    va_end(args);
    
    [[PNSession sharedInstance] preloadFramesWithIds: placementNames];
    [placementNames autorelease];
}


+ (void) showFrameWithId:(NSString *) frameId{
    [self showPlacementWithName:frameId];
}

+ (void) showPlacementWithName:(NSString *)placementName{
    [[PNSession sharedInstance] showFrameWithId:placementName];
}

+ (void) showFrameWithId:(NSString *) frameId
                delegate:(id<PlaynomicsPlacementDelegate>) delegate{
    [self showPlacementWithName:frameId delegate:delegate];
}

+ (void) showPlacementWithName:(NSString *)placementName
                      delegate:(id<PlaynomicsPlacementDelegate>)delegate{
    [[PNSession sharedInstance] showFrameWithId: placementName
                                       delegate: delegate];
}

+(void) showPlacementWithName:(NSString *)placementName
                  rawDelegate:(id<PlaynomicsPlacementRawDelegate>)delegate {
    [[PNSession sharedInstance] showFrameWithId: placementName
                                       delegate: delegate];
}

+ (void) hideFrameWithId:(NSString *) frameId{
    [self hidePlacementWithName: frameId];
}

+ (void) hidePlacementWithName:(NSString *)placementName{
    [[PNSession sharedInstance] hideFrameWithID: placementName];
}

+ (void) setFrameParentView:(UIView *) parentView{
    [self setPlacementParentView: parentView];
}

+(void) setPlacementParentView:(UIView *)parentView{
    [[PNSession sharedInstance] setFrameParentView:parentView];
}

@end
