//
//  PNFrameResponse.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/9/13.
//
//

#import "PNFrameResponse.h"

@implementation PNFrameResponse
@synthesize ad = _ad;
@synthesize background = _background;
@synthesize closeButton = _closeButton;

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
    
    NSDictionary *backgroundInfo = (NSDictionary *)[self cleanValue: [frameResponse objectForKey:FrameResponseBackgroundInfo]];
    if(backgroundInfo){
        _background = [self parseBackgroundResponse:backgroundInfo];
    }
    
    NSArray *adsSet = [frameResponse objectForKey:FrameResponseAds];
    if (adsSet && adsSet.count > 0){
        NSDictionary *adInfo = [adsSet objectAtIndex:0];
        NSDictionary *adLocationInfo = [frameResponse objectForKey:FrameResponseAdLocationInfo];
        
        if(adInfo){
            NSString *closeButtonLink = nil;
            NSString *closeButtonTypeString = nil;
            
            _ad = [self parseAdFromResponse:adInfo
                                 adLocation:adLocationInfo
                            closeButtonLink:&closeButtonLink
                            closeButtonType:&closeButtonTypeString];
            
            CloseButtonType closeButtonType = [self toCloseButtonType:closeButtonTypeString];
            
            if(closeButtonType == CloseButtonNative){
                NSDictionary *closeButtonInfo = [frameResponse objectForKey:FrameResponseCloseButtonInfo];
                
                if(closeButtonInfo){
                    NSString * closeButtonImage = [self getImageFromProperties:closeButtonInfo];
                    
                    if(closeButtonImage){
                        _closeButton = [[PNNativeCloseButton alloc] init];
                        ((PNNativeCloseButton *)_closeButton).imageUrl = [self getImageFromProperties:closeButtonInfo];
                        ((PNNativeCloseButton *)_closeButton).dimensions = [self getViewDimensions:closeButtonInfo];
                    }
                }
            } else if(closeButtonType == CloseButtonHtml && closeButtonLink) {
                _closeButton = [[PNHtmlCloseButton alloc] init];
                ((PNHtmlCloseButton *) _closeButton).closeButtonLink = closeButtonLink;
            }
        }
    }
}

-(PNBackground *) parseBackgroundResponse:(NSDictionary *) backgroundData{
    if(!backgroundData){ return nil; }
    
    PNBackground *background = [[PNBackground alloc] init];
    float height = [self getFloatValue:[backgroundData objectForKey:FrameResponseHeight]];
    float width = [self getFloatValue:[backgroundData objectForKey:FrameResponseWidth]];
    
    NSDictionary *landscapeData =[backgroundData objectForKey:FrameResponseBackground_Landscape];
    float x = [self getFloatValue:[landscapeData objectForKey:FrameResponseXOffset]];
    float y = [self getFloatValue:[landscapeData objectForKey:FrameResponseYOffset]];
    background.landscapeDimensions = CGRectMake(x, y, width, height);
    
    NSDictionary *portraitData =[backgroundData objectForKey:FrameResponseBackground_Portrait];
    x = [self getFloatValue:[portraitData objectForKey:FrameResponseXOffset]];
    y = [self getFloatValue:[portraitData objectForKey:FrameResponseYOffset]];
    background.portraitDimensions = CGRectMake(x, y, width, height);
    
    background.imageUrl = [self getImageFromProperties:backgroundData];
    return background;
}

-(PNAd *) parseAdFromResponse:(NSDictionary *) adResponse
                   adLocation:(NSDictionary *) location
              closeButtonLink:(NSString **) closeButtonLink
              closeButtonType:(NSString **) type
{

    NSString *adTypeString = [self cleanValue:[adResponse objectForKey:FrameResponseAd_AdType]];
    AdType adType = adTypeString == nil ? AdTypeImage : [self toAdType:adTypeString];
    PNAd *ad = nil;

    if(adType == AdTypeImage){
        ad = [[PNNativeImageAd alloc] init];
        ((PNNativeImageAd *) ad).imageUrl = [self getImageFromProperties:adResponse];
        ((PNNativeImageAd *) ad).dimensions = [self getViewDimensions:location];
    } else if (adType == AdTypeWebView){
        ad = [[PNHtmlAd alloc] init];
        ((PNHtmlAd *) ad).htmlContent = [self cleanValue:[adResponse objectForKey:FrameResponseAd_HtmlContent]];
        ((PNHtmlAd *) ad).clickLink = [self cleanValue:[adResponse objectForKey:FrameResponseAd_ClickLink]];
    }
    
    ad.impressionUrl = [self cleanValue: [adResponse objectForKey:FrameResponseAd_ImpressionUrl]];
    ad.closeUrl = [self cleanValue: [adResponse objectForKey:FrameResponseAd_CloseUrl]];
    ad.clickUrl = [self cleanValue: [adResponse objectForKey:FrameResponseAd_ClickUrl]];
    
    ad.targetType = [self toAdTarget: [adResponse objectForKey:FrameResponseAd_TargetType]];
    
    if(ad.targetType == AdTargetData){
        NSString *targetDataString = [self cleanValue:[adResponse objectForKey:FrameResponseAd_TargetData]];
        ad.rawTargetData = targetDataString;
        if(targetDataString){
            ad.targetData = [PNUtil deserializeJsonString: targetDataString];
        }
    } else if(ad.targetType == AdTargetUrl){
        ad.targetUrl = [self cleanValue: [adResponse objectForKey:FrameResponseAd_TargetUrl]];
    }
    
    *type = [adResponse objectForKey:FrameResponseAd_CloseButtonType];
    *closeButtonLink = [adResponse objectForKey:FrameResponseAd_CloseButtonLink];
    
    NSNumber *fullscreenAsNum = (NSNumber *)[adResponse objectForKey:FrameResponseAd_Fullscreen];
    ad.fullscreen = [fullscreenAsNum boolValue];
    return ad;
}


-(CGRect) getViewDimensions:(NSDictionary*) componentInfo {
    float height = [self getFloatValue:[componentInfo objectForKey:FrameResponseHeight]];
    float width = [self getFloatValue:[componentInfo objectForKey:FrameResponseWidth]];
    float x = [self getFloatValue:[componentInfo objectForKey:FrameResponseXOffset]];
    float y = [self getFloatValue:[componentInfo objectForKey:FrameResponseYOffset]];
    return CGRectMake(x, y, width, height);
}

-(id) cleanValue:(id) value{
    if(!value || value == (id)[NSNull null]){
        return nil;
    }
    return value;
}

-(float) getFloatValue:(NSNumber *) n {
    return [n floatValue];
}

-(NSString *) getImageFromProperties: (NSDictionary *) properties{
    return [self cleanValue: [properties objectForKey:FrameResponseImageUrl]];
}


-(AdTarget) toAdTarget:(NSString *) adTargetType {
    adTargetType = [self cleanValue:adTargetType];
    if(!adTargetType){
        return AdTargetUnknown;
    }
    if([adTargetType isEqualToString: @"data"]){
        return AdTargetData;
    }
    if([adTargetType isEqualToString:@"url"]){
        return AdTargetUrl;
    }
    if([adTargetType isEqualToString:@"external"]){
        return AdTargetExternal;
    }
    return AdTargetUnknown;
}

-(CloseButtonType) toCloseButtonType:(NSString *) closeButtonType{
    closeButtonType = [self cleanValue:closeButtonType];
    
    if(!closeButtonType){
        return CloseButtonUnknown;
    }
    
    if([closeButtonType isEqualToString:@"html"]){
        return CloseButtonHtml;
    }
    
    if([closeButtonType isEqualToString:@"native"]){
        return CloseButtonNative;
    }
    
    return CloseButtonUnknown;
}

-(AdType) toAdType:(NSString *) adType{
    adType = [self cleanValue:adType];
    if(!adType){
        return AdTypeUnknown;
    }
    
    if([adType isEqualToString:@"html"]){
        return AdTypeWebView;
    }
    
    if([adType isEqualToString:@"image"]){
        return AdTypeImage;
    }
    
    if([adType isEqualToString:@"video"]){
        return AdTypeVideo;
    }
    return AdTypeUnknown;
}
@end
