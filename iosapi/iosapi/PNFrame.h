//
// Created by jmistral on 10/3/12.
//

#import <Foundation/Foundation.h>
#import "Playnomics.h"
#import "PNSession.h"

typedef enum {
    AdComponentStatusPending,   // Component is waiting for image download to complete
    AdComponentStatusCompleted, // Component has completed image download and is ready to be displayed
    AdComponentStatusError      // Component experienced an error retrieving image
} AdComponentStatus;

typedef enum {
    AdColony,
    Image,
    Video,
    WebView,
    AdUnknown
} AdType;

typedef enum {
    DisplayResultNoInternetPermission,  // Communication with the ad server is impossible
    DisplayResultStartNotCalled,  // Data collection API was not initialized
    DisplayResultUnableToConnect,  // No successful connections to the ad server have occurred
    DisplayResultFailUnknown,  // Any other problem (included bad responses from the ad server)
    DisplayResultDisplayPending,  // Ad server has been reached, but assets not ready yet, will display when ready
    DisplayAdColony,  // Show an AdColony video ad
    DisplayResultDisplayed  // Success
} DisplayResult;

typedef struct {
    float width;
    float height;
    float x;
    float y;
} PNViewDimensions;

@protocol PNFrameDelegate <NSObject>
@required
-(void) didLoad;
-(void) didFailToLoad;
-(void) didFailToLoadWithError: (NSError*) error;
-(void) didFailToLoadWithException: (NSException*) exception;
-(void) adClosed;
-(void) adClicked;
@end

// Represents the container for the ad image.
//
// This frame frame will be responsible for displaying the ad image and capturing all of
// clicks within the ad area.
@interface PNFrame : NSObject <PNFrameDelegate>
@property (assign, readonly) UIView* parentView;
@property (assign) id<PlaynomicsFrameDelegate> delegate;

@property (readonly) NSDictionary* backgroundInfo;
@property (readonly) PNViewDimensions backgroundDimensions;
@property (readonly) NSString* backgroundImageUrl;

@property (readonly) NSDictionary* adInfo;
@property (readonly) PNViewDimensions adDimensions;
@property (readonly) AdType adType;
@property (readonly) NSString* creativeType;
@property (readonly) NSString* adTag;
@property (readonly) NSString* primaryImageUrl;
@property (readonly) NSString* rolloverImageUrl;
@property (readonly) NSString* tooltipText;
@property (readonly) NSString* clickTarget;
@property (readonly) NSString* clickTargetType;
@property (readonly) NSString* clickTargetData;
@property (readonly) NSString* preClickUrl;
@property (readonly) NSString* postClickUrl;
@property (readonly) NSString* impressionUrl;
@property (readonly) NSString* flagUrl;
@property (readonly) NSString* closeUrl;
@property (readonly) NSString* viewUrl;

@property (readonly) NSDictionary* closeButtonInfo;
@property (readonly) NSString* closeButtonImageUrl;
@property (readonly) PNViewDimensions closeButtonDimensions;
@property (readonly) id adObject;

// Called to display the ad frame and to begin capturing clicks within the frame.
- (id) initWithProperties: (NSDictionary *)adResponse frameDelegate: (id<PlaynomicsFrameDelegate>) frameDelegate session: (PNSession *) session;
- (DisplayResult) startInView:(UIView*) parentView;
- (void) sendVideoView;
@end
