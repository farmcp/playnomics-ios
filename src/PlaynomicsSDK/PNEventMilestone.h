//
//  MilestoneEvent.h
//  iosapi
//
//  Created by Douglas Kadlecek on 12/10/12.
//
//
#import "PNSession.h"
#import "PNExplicitEvent.h"

@interface PNEventMilestone : PNExplicitEvent
- (id) initWithSessionInfo:(PNGameSessionInfo *)info milestoneType: (PNMilestoneType) milestoneType;
- (id) initWithSessionInfo:(PNGameSessionInfo *)info
           customEventName:(NSString *) customEventName;
- (NSString *) baseUrlPath;
@end
