//
//  PNImage.m
//  iosapi
//
//  Created by Jared Jenkins on 8/15/13.
//
//

#import "PNNativeImageView.h"
#import "PNNativeViewComponent.h"
#import "PNFrame.h"

@implementation PNNativeImageView {
@private
    PNNativeViewComponent* _backgroundView;
    PNNativeViewComponent* _adAreaView;
    PNNativeViewComponent* _closeButtonView;
    
    PNNativeImageAd *_staticAd;
    PNBackground *_background;
    PNNativeCloseButton *_closeButton;
    id<PNFrameDelegate> _delegate;
}
#pragma mark - Lifecycle/Memory management

-(id) initWithAd:(PNNativeImageAd *) staticAd
      background:(PNBackground *) background
        delegate:(id<PNFrameDelegate>) delegate
{
    self = [super init];
    
    if(self){
        _delegate = delegate;
        _background = [background retain];
        _staticAd = [staticAd retain];
        _backgroundView = [[PNNativeViewComponent alloc] initWithDimensions:[_background dimensionsForCurrentOrientation]
                                                             delegate:self
                                                                image:_background.imageUrl];
        
        _adAreaView = [[PNNativeViewComponent alloc] initWithDimensions:_staticAd.dimensions
                                                         delegate:self
                                                            image:_staticAd.imageUrl];
        [_backgroundView addSubComponent: _adAreaView];
        _backgroundView.hidden = YES;
    }
    
    return self;
}

-(id) initWithAd:(PNNativeImageAd *) staticAd
      background:(PNBackground *) background
     closeButton:(PNNativeCloseButton *) closeButton
        delegate:(id<PNFrameDelegate>) delegate
{
    self = [self initWithAd:staticAd background:background delegate:delegate];
    if(self){
        _closeButton = [closeButton retain];
        _closeButtonView = [[PNNativeViewComponent alloc] initWithDimensions:_closeButton.dimensions
                                                              delegate:self
                                                                 image:_closeButton.imageUrl];
        [_backgroundView addSubComponent: _closeButtonView];
    }
    return self;
}


-(void) dealloc {
    [_backgroundView release];
    [_adAreaView release];
    [_closeButtonView release];
    _delegate = nil;
    [super dealloc];
}

#pragma mark "Public Interface"
-(void) renderAdInView:(UIView*) parentView {
    int lastDisplayIndex = (int)parentView.subviews.count;
    [parentView insertSubview: _backgroundView atIndex:lastDisplayIndex + 1];
    _backgroundView.hidden = NO;
    [_backgroundView setNeedsDisplay];
}


- (void) hide{
    [self closeAd];
    [_delegate adClosed: NO];
}

-(void) rotate{
    _backgroundView.frame = [_background dimensionsForCurrentOrientation];
}

#pragma mark "Helper Methods"
// Returns TRUE if all instantiated components are done loading. FALSE otherwise
- (BOOL) _allComponentsLoaded {
    if(!_closeButtonView){
        return (_backgroundView.status == AdComponentStatusCompleted
                && _adAreaView.status == AdComponentStatusCompleted);
    }
    return (_backgroundView.status == AdComponentStatusCompleted
            && _adAreaView.status == AdComponentStatusCompleted
            && _closeButtonView.status == AdComponentStatusCompleted);
}

#pragma mark "Delegate Handlers"

// Hide the background and since all other components are attached to the background,
// everything else will also be hidden
-(void) closeAd{
    [_backgroundView hide];
}

// Only notify the delegate if all the components have been loaded successfully
- (void) componentDidLoad {
    if([self _allComponentsLoaded]){
        [_delegate didLoad];
    }
}

- (void)componentDidFailToLoad{
    [self closeAd];
    [_delegate didFailToLoad];
}

// Close the ad in case of an error and notify the delegate
-(void) componentDidFailToLoadWithError: (NSError *) error {
    [self closeAd];
    [_delegate didFailToLoadWithError:error];
}

// Close the ad in case of an exception and notify the delegate
-(void) componentDidFailToLoadWithException: (NSException *) exception {
    [self closeAd];
    [_delegate didFailToLoadWithException:exception];
}

// If the close button component was clicked, close the ad and notify the delegate
// If the ad was clicked, also close the ad and notify the delegate
-(void) component: (id) component didReceiveTouch: (UITouch*) touch {
    if (component == _closeButtonView) {
        [PNLogger log:PNLogLevelVerbose format:@"Close button was pressed on PNImage"];
        [self closeAd];
        [_delegate adClosed: YES];
    } else if (component == _adAreaView) {
        CGPoint location = [touch locationInView: _adAreaView];
        int x = location.x;
        int y = location.y;
        [PNLogger log:PNLogLevelVerbose format:@"Ad area was clicked on at location %d,%d", x, y];
        [self closeAd];
        [_delegate adClicked];
    }
}

@end
