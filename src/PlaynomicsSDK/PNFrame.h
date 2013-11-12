//
// Created by jmistral on 10/3/12.
//

#import <Foundation/Foundation.h>
#import "Playnomics.h"
#import "PNSession.h"
#import "PNFrameResponse.h"
#import "PNMessaging.h"

typedef enum {
    AdComponentStatusPending,   // Component is waiting for image download to complete
    AdComponentStatusCompleted, // Component has completed image download and is ready to be displayed
    AdComponentStatusError      // Component experienced an error retrieving image
} AdComponentStatus;

typedef NS_ENUM(int, PNFrameState){
    PNFrameStateNotLoaded = 0,
    PNFrameStateLoadingStarted = 1,
    PNFrameStateLoadingComplete = 2,
    PNFrameStateLoadingFailed = 3
};

@protocol PNFrameDelegate <NSObject>
@required
-(void) didLoad;
-(void) didFailToLoad;
-(void) didFailToLoadWithError: (NSError *) error;
-(void) didFailToLoadWithException: (NSException *) exception;
-(void) adClosed:(BOOL) closedByUser;
-(void) adClicked;
@end

@protocol PNAdView <NSObject>
@required
- (void) renderAdInView:(UIView *) parentView;
- (void) hide;
- (void) rotate;
@end

// Represents the container for the ad image.
//
// This frame frame will be responsible for displaying the ad image and capturing all of
// clicks within the ad area.
@interface PNFrame : NSObject <PNFrameDelegate>

@property (assign) PNFrameState state;
@property (readonly) NSString *frameId;
@property (assign, readonly) UIView *parentView;
@property (assign) id<PlaynomicsFrameDelegate> delegate;
@property (readonly) id<PNAdView> adView;


// Called to display the ad frame and to begin capturing clicks within the frame.
- (id) initWithFrameId:(NSString *) frameId
               session:(PNSession *) session
             messaging:(PNMessaging *) messaging;

- (void) showInView:(UIView *) parentView
       withDelegate:(id<PlaynomicsPlacementDelegate>) delegate;

- (void) hide;

- (void) updateFrameResponse:(PNFrameResponse *) frameResponse;

@end
