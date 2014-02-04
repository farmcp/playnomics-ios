//
//  PNPlayerSessionInfo.h
//  iosapi
//
//  Created by Jared Jenkins on 8/28/13.
//
//

#import <Foundation/Foundation.h>
#import "PNGeneratedHexId.h"

@interface PNGameSessionInfo : NSObject

@property (nonatomic, readonly) NSNumber *applicationId;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *idfv;
@property (nonatomic, readonly) PNGeneratedHexId *sessionId;

-(id) initWithApplicationId:(unsigned long long)applicationId
                     userId:(NSString *) userId
                       idfv:(NSString *) idfv
                  sessionId:(PNGeneratedHexId *)sessionId;

@end
