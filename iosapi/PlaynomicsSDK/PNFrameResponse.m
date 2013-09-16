//
//  PNFrameResponse.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/9/13.
//
//

#import "PNFrameResponse.h"

@implementation PNFrameResponse

@synthesize backgroundInfo = _backgroundInfo;
@synthesize backgroundDimensions = _backgroundDimensions;
@synthesize backgroundImageUrl = _backgroundImageUrl;
@synthesize adInfo = _adInfo;
@synthesize adDimensions = _adDimensions;
@synthesize adType = _adType;
@synthesize fullscreen = _fullscreen;
@synthesize htmlContent = _htmlContent;
@synthesize primaryImageUrl = _primaryImageUrl;
@synthesize rolloverImageUrl = _rolloverImageUrl;
@synthesize tooltipText = _tooltipText;
@synthesize clickTarget = _clickTarget;
@synthesize clickTargetType = _clickTargetType;
@synthesize clickTargetData = _clickTargetData;
@synthesize preClickUrl = _preClickUrl;
@synthesize postClickUrl = _postClickUrl;
@synthesize impressionUrl = _impressionUrl;
@synthesize flagUrl = _flagUrl;
@synthesize closeUrl = _closeUrl;
@synthesize viewUrl = _viewUrl;
@synthesize closeButtonInfo = _closeButtonInfo;
@synthesize closeButtonImageUrl = _closeButtonImageUrl;
@synthesize closeButtonDimensions = _closeButtonDimensions;

- (id) initWithJSONData:(NSData *) jsonData {
    self = [super init];
    if(self){
        NSDictionary* jsonDict = [PNUtil deserializeJsonData: jsonData];
        [self parseFrameResponse: jsonDict];
    }
    return self;
}

-(void) parseFrameResponse:(NSDictionary *)frameResponse {
    if(frameResponse == nil){
        return;
    }
    // Get the background details, which are in the key "b" and is a dictionary of data
    _backgroundInfo = [frameResponse objectForKey:FrameResponseBackgroundInfo];
    _backgroundDimensions = [self getViewDimensions:_backgroundInfo];
    _backgroundImageUrl = [[self getImageFromProperties:_backgroundInfo] retain];
    
    NSDictionary *adLocationInfo = [frameResponse objectForKey:FrameResponseAdLocationInfo];
    _adDimensions = [self getViewDimensions:adLocationInfo];
    
    NSArray *adResponse = [frameResponse objectForKey:FrameResponseAds];
    if (!adResponse || adResponse.count == 0){
        _adInfo = nil;
    } else {
        _adInfo = [adResponse objectAtIndex:0];
        _primaryImageUrl = [[self getImageFromProperties:_adInfo] retain];
        _rolloverImageUrl = [[_adInfo objectForKey:FrameResponseAd_RolloverImage] retain];
        _tooltipText = [[_adInfo objectForKey:FrameResponseAd_ToolTipText] retain];
        _impressionUrl = [[_adInfo objectForKey:FrameResponseAd_ImpressionUrl] retain];
        _flagUrl = [[_adInfo objectForKey:FrameResponseAd_FlagUrl] retain];
        _closeUrl = [[_adInfo objectForKey:FrameResponseAd_CloseUrl] retain];
        
        _clickTargetType = [[_adInfo objectForKey:FrameResponseAd_TargetType] retain];
        _clickTarget = [[_adInfo objectForKey:FrameResponseAd_ClickTarget] retain];
        _preClickUrl = [[_adInfo objectForKey:FrameResponseAd_PreExecuteUrl] retain];
        _postClickUrl =  [[_adInfo objectForKey:FrameResponseAd_PostExecuteUrl] retain];
        _clickTargetData = [[_adInfo objectForKey:FrameResponseAd_TargetData] retain];
        
        NSString* adType = [_adInfo objectForKey:FrameResponseAd_AdType];
        if (adType) {
            if ([adType isEqualToString:@"html"]) {
                _adType = WebView;
                _fullscreen = [[_adInfo objectForKey:FrameResponseAd_Fullscreen] retain];
                _htmlContent = [[_adInfo objectForKey:FrameResponseAd_HtmlContent] retain];
            } else if ([adType isEqualToString:@"video"]) {
                if ([[_adInfo objectForKey:FrameResponseAd_AdProvider] isEqualToString:@"AdColony"]) {
                    NSLog(@"Setting ad type to AdColony");
                    _adType = AdColony;
                } else {
                    _adType = Video;
                }
                _viewUrl = [[_adInfo objectForKey:FrameResponseAd_VideoViewUrl] retain];
            } else if ([adType isEqualToString:@"image"]) {
                _adType = Image;
            } else {
                _adType = AdUnknown;
                NSLog(@"Encountered Unknown AdType %@", adType);
            }
        } else {
            _adType = Image;
        }
    }
    
    _closeButtonInfo = [frameResponse objectForKey:FrameResponseCloseButtonInfo];
    _closeButtonImageUrl = [[self getImageFromProperties:_closeButtonInfo] retain];
    if (_closeButtonImageUrl != nil) {
        _closeButtonDimensions = [self getViewDimensions:_closeButtonInfo];
    }
}


-(PNViewDimensions) getViewDimensions:(NSDictionary*) componentInfo {
    float height = [self getFloatValue:[componentInfo objectForKey:FrameResponseHeight]];
    float width = [self getFloatValue:[componentInfo objectForKey:FrameResponseWidth]];
    
    NSDictionary *coordinateProps = [self extractCoordinateProps:componentInfo];
    float x = [self getFloatValue:[coordinateProps objectForKey:FrameResponseXOffset]];
    float y = [self getFloatValue:[coordinateProps objectForKey:FrameResponseYOffset]];
    
    PNViewDimensions dimensions = {.width = width, .height = height, .x = x, .y = y};
    return dimensions;
}

-(NSDictionary *) extractCoordinateProps:(NSDictionary*) componentInfo {
    // This is dumb, but the reason for this if statement is because ad and close components
    // both have the size and offset locations in the same dictionary whereas the background
    // component has the coordinates in a sub-dictionary called 'l' for landscape mode and
    // 'p' for portrait mode. This is also because the ad and close components are offsets to
    // the background image whereas the background is just a raw location
    if ([componentInfo objectForKey:FrameResponseBackground_Landscape] == nil) {
        return componentInfo;
    }
    
    // By default, return portrait
    UIInterfaceOrientation orientation = [PNUtil getCurrentOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return [componentInfo objectForKey:FrameResponseBackground_Portrait];
    } else if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        return [componentInfo objectForKey:FrameResponseBackground_Landscape];
    } else {
        return [componentInfo objectForKey:FrameResponseBackground_Portrait];
    }
}

-(float) getFloatValue:(NSNumber *) n {
    @try {
        return [n floatValue];
    } @catch (NSException * exception) {
        //
    }
    return 0;
}

-(NSString *) getImageFromProperties: (NSDictionary *) properties{
    NSString *imageUrl = [properties objectForKey:FrameResponseImageUrl];
    if(imageUrl == nil || imageUrl == (id)[NSNull null] ){
        return nil;
    }
    return imageUrl;
}



@end
