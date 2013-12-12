//
//  PNSession_PNSession_Private.h
//  iosapi
//
//  Created by Jared Jenkins on 8/29/13.
//
//

#import "PNSession.h"
#import "PNEventApiClient.h"


@interface PNSession ()
@property (retain) PNEventApiClient *apiClient;
@property (retain) PNDeviceManager *deviceManager;
@property (assign) NSTimeInterval pauseTime;
@end
