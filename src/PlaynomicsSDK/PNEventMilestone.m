//
//  MilestoneEvent.m
//  iosapi
//
//  Created by Douglas Kadlecek on 12/10/12.
//
//
#import "PNEventMilestone.h"
@implementation PNEventMilestone

- (id) initWithSessionInfo:(PNGameSessionInfo *)info milestoneType: (PNMilestoneType) milestoneType {
    
    if ((self = [super initWithSessionInfo:info])) {
        unsigned long long milestoneId = [PNUtil generateRandomLongLong];
        NSString *milestoneName = [self getNameForMilestoneType: milestoneType];
        
        [self appendParameter: [NSNumber numberWithUnsignedLongLong: milestoneId] forKey: PNEventParameterMilestoneId];
        [self appendParameter: milestoneName forKey: PNEventParameterMilestoneName];
    }
    return self;
}

- (id) initWithSessionInfo:(PNGameSessionInfo *)info
           customEventName:(NSString *) customEventName {
    if ((self = [super initWithSessionInfo:info])) {
        [self appendParameter: customEventName forKey: PNEventParameterMilestoneName];
    }
    return self;
}

- (NSString *) baseUrlPath{
    return @"milestone";
}

- (NSString *) getNameForMilestoneType: (PNMilestoneType) milestoneType{
    int milestoneNum  = (int)milestoneType;
    return [NSString stringWithFormat: @"CUSTOM%d", milestoneNum];
}

@end