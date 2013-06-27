//
// Created by jmistral on 10/16/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BaseAdComponent.h"
#import "FSNConnection.h"

@implementation BaseAdComponent {
@private
    NSMutableArray *_subComponents;
    UIImage *_image;
    id<PNBaseAdComponentDelegate> _delegate;
}

@synthesize properties = _properties;
@synthesize imageUI = _imageUI;
@synthesize imageUrl = _imageUrl;
@synthesize parentComponent = _parentComponent;
@synthesize frame = _frame;

@synthesize xOffset = _xOffset;
@synthesize yOffset = _yOffset;
@synthesize height = _height;
@synthesize width = _width;
@synthesize touchHandler = _touchHandler;
@synthesize status = _status;


#pragma mark - Lifecycle/Memory management
- (id)initWithProperties:(NSDictionary *)aProperties
                forFrame:(PlaynomicsFrame *)aFrame
        withTouchHandler:(SEL)aTouchHandler
             andDelegate:(id<PNBaseAdComponentDelegate>)delegate {
    self = [super init];
    if (self) {
        NSLog(@"Creating ad component with properties: %@", aProperties);
        _subComponents = [[NSMutableArray array] retain];
        _properties = [aProperties retain];
        _frame = [aFrame retain];
        _touchHandler = aTouchHandler;
        _status = AdComponentStatusPending;
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    [_subComponents release];
    [_properties release];
    [_imageUI release];
    [_imageUrl release];
    [_parentComponent release];
    [_frame release];
    [_image release];
    
    [super dealloc];
}

#pragma mark - Public Interface
- (void)layoutComponent {
    [self _initCoordinateValues];
    [self _createComponentView];
    // make sure image url is not null
    if (self.imageUrl != (id)[NSNull null] && self.imageUrl.length > 0 )
        [self _startImageDownload];
}

- (void)_initCoordinateValues {
    // TODO: why is this not setting to null correctly?
    self.imageUrl = [self.properties objectForKey:FrameResponseImageUrl];
    self.height = [self getFloatValue:[self.properties objectForKey:FrameResponseHeight]];
    self.width = [self getFloatValue:[self.properties objectForKey:FrameResponseWidth]];
    
    // no sense getting image if it has 0 height or width
    if (self.height == 0 || self.width == 0)
        self.imageUrl = nil;
    
    NSDictionary *coordinateProps = [self _extractCoordinateProps];
    self.xOffset = [self getFloatValue:[coordinateProps objectForKey:FrameResponseXOffset]];
    self.yOffset = [self getFloatValue:[coordinateProps objectForKey:FrameResponseYOffset]];
}

- (float)getFloatValue:(NSNumber*)n {
    @try {
        return [n floatValue];
    }
    @catch (NSException * exception) {
        //
    }
    return 0;
}

- (NSDictionary *)_extractCoordinateProps {
    if ([self.properties objectForKey:FrameResponseBackground_Landscape] == nil) {
        return self.properties;
    }
    
    // By default, return portrait
    UIInterfaceOrientation orientation = [PNUtil getCurrentOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return [self.properties objectForKey:FrameResponseBackground_Portrait];
    } else if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        return [self.properties objectForKey:FrameResponseBackground_Landscape];
    } else {
        return [self.properties objectForKey:FrameResponseBackground_Portrait];
    }
}

- (void)_createComponentView {
    CGRect backgroundRect = CGRectMake(self.xOffset, self.yOffset, self.width, self.height);
    NSLog(@"Frame for component image view (%@): %@", self.imageUrl, NSStringFromCGRect(backgroundRect));
    
    if (self.imageUI == nil) {
        UIImageView *newImageView = [[UIImageView alloc] init];
        newImageView.userInteractionEnabled = YES;
        
        self.imageUI = newImageView;
        [newImageView release];
    }
    
    self.imageUI.frame = backgroundRect;
}

- (void)_startImageDownload {
    
    NSURL *url = [NSURL URLWithString:self.imageUrl];
    if (url==nil || self.imageUrl==nil) {
        return;//invalid or will crash...stop here
    }
    if ([self.imageUrl hasSuffix:@".gif"]) {
        self.imageUI = [AnimatedGif getAnimationForGifAtUrl:url withDelegate:self];
    } else {
        FSNConnection *connection =
        [FSNConnection withUrl:url
                        method:FSNRequestMethodGET
                       headers:nil
                    parameters:nil
                    parseBlock:nil
               completionBlock:^(FSNConnection *c) { [self _handleImageDownloadCompletion:c]; }
                 progressBlock:nil];
        
        [connection start];
    }
}

- (void) gifImageLoaded {
    [self _finishImageSetup];
}

- (void)_handleImageDownloadCompletion:(FSNConnection *)connection {
    if (connection.error) {
        NSLog(@"Error retrieving image from the internet: %@", connection.error.localizedDescription);
        self.status = AdComponentStatusError;
    } else {
        self.imageUI.image =  [UIImage imageWithData:connection.responseData];
        [self _finishImageSetup];
    }
}

- (void)_finishImageSetup {
    [self _setupTapRecognizer];
    [self.imageUI setNeedsDisplay];
    self.status = AdComponentStatusCompleted;
    [_delegate componentDidLoad:self];
}

-(void)_setupTapRecognizer {
    if (self.touchHandler != nil) {
        UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self.frame action:self.touchHandler] autorelease];
        [self.imageUI addGestureRecognizer:tap];
        self.imageUI.userInteractionEnabled = YES;
    }
}

- (void)addSubComponent:(BaseAdComponent *)subComponent {
    subComponent.parentComponent = self;
    [_subComponents addObject:subComponent];
    [self.imageUI addSubview:subComponent.imageUI];
    subComponent.imageUI.frame = CGRectMake(subComponent.xOffset, subComponent.yOffset, subComponent.width, subComponent.height);
}

- (void)display {
    UIView *topLevelView = [[UIApplication sharedApplication] keyWindow].rootViewController.view;
    int lastDisplayIndex = topLevelView.subviews.count;
    [topLevelView insertSubview:self.imageUI atIndex:lastDisplayIndex + 1];
}

- (void)hide {
    [self.imageUI removeFromSuperview];
}

@end