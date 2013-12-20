//
//  PNFrameResponseTests.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/24/13.
//
//

#import <XCTest/XCTest.h>
#import "PNFrameResponse.h"


#define TestClickLink @"pn://clickLink"

#define TestTargetTypeExternal @"external"
#define TestTargetTypeUrl @"url"
#define TestTargetTypeData @"data"
#define TestTargetData @"{\"data\":\"test\"}"

#define TestTargetUrl @"http://targetUrl"


#define TestBackgroundImage @"http://backgroundImageUrl"
#define TestBackgroundOrientationDetect @"detect"

#define TestButtonTypeNative @"native"
#define TestButtonTypeHtml @"html"

#define TestCloseButtonImage @"http://closeButtonImage"
#define TestImageUrl @"http://imageUrl"

#define TestCloseLink @"pn://closeLink"
#define TestClickLink @"pn://clickLink"

#define TestCloseUrl @"http://closeUrl"
#define TestClickUrl @"http://clickUrl"
#define TestImpressionUrl @"http://impressionUrl"

#define TestAdTypeHtml @"html"
#define TestAdTypeImage @"image"

#define TestHtmlContent @"<html></html>"

typedef enum{
    FrameResponseEmpty,
    FrameResponseFullscreenInternalTargetUrl,
    FrameResponseFullscreenInternalTargetData,
    FrameResponseFullscreenInternalNullTarget,
    FrameResponseThirdPartyHtmlClose,
    FrameResponseThirdPartyNativeClose,
    FrameResponseAdvancedInternalTargetUrl,
    FrameResponseAdvancedInternalTargetData,
    FrameResponseAdvancedInternalNullTarget
}FrameResponseType;

@interface PNFrameResponseTests : XCTestCase
@end

@implementation PNFrameResponseTests{
    NSDictionary *_response;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(NSDictionary *) factoryForFrameResponseData: (FrameResponseType) responseType{
    NSMutableDictionary * response = [[NSMutableDictionary alloc]init];
    //m is always nil
    [response setValue:[NSNull null] forKey:@"m"];
    //the expiration time at this point is still constant
    [response setValue:[NSNumber numberWithInt:3600] forKey:@"e"];
    //status is Ok
    [response setValue:@"Ok" forKey:@"s"];
    
    NSMutableArray *ads = [[NSMutableArray alloc]init];
    NSMutableDictionary *ad =  nil;
    NSMutableDictionary *background = nil;
    NSMutableDictionary *closeButton = nil;
    NSMutableDictionary *location = nil;
    
    if(responseType == FrameResponseAdvancedInternalNullTarget ||
       responseType == FrameResponseAdvancedInternalTargetData ||
       responseType == FrameResponseAdvancedInternalTargetUrl){
        
        ad = [[NSMutableDictionary alloc] init];
        [ad setObject:[NSNumber numberWithInt:0] forKey:@"fullscreen"];
        [ad setObject:TestCloseUrl forKey:@"d"];
        [ad setObject:[NSNull null] forKey:@"clickLink"];
        [ad setObject:TestImageUrl forKey:@"i"];
        [ad setObject:TestButtonTypeNative forKey:@"closeButtonType"];
        [ad setObject:TestAdTypeImage forKey:@"adType"];
        [ad setObject:[NSNull null] forKey:@"closeButtonLink"];
        [ad setObject:TestImpressionUrl forKey:@"s"];
        [ad setObject:TestClickUrl forKey:@"t"];
        
        if(responseType == FrameResponseAdvancedInternalTargetUrl){
            [ad setObject:TestTargetUrl forKey:@"targetURL"];
            [ad setObject:TestTargetTypeUrl forKey:@"targetType"];
        } else if (responseType == FrameResponseAdvancedInternalTargetData){
            [ad setObject:TestTargetData forKey:@"targetData"];
            [ad setObject:TestTargetTypeData forKey:@"targetType"];
        } else if (responseType == FrameResponseAdvancedInternalNullTarget){
            [ad setObject:[NSNull null] forKey:@"targetURL"];
            [ad setObject:TestTargetTypeUrl forKey:@"targetType"];
        }
        
        //background settings
        background = [[NSMutableDictionary alloc] init];
        [background setObject:TestBackgroundImage forKey:@"i"];
        [background setObject:[NSNumber numberWithFloat:250] forKey:@"h"];
        [background setObject:[NSNumber numberWithFloat:300] forKey:@"w"];
        [background setObject:TestBackgroundOrientationDetect forKey:@"o"];
        
        NSMutableDictionary *landscape = [[NSMutableDictionary alloc] init];
        [landscape setObject:[NSNumber numberWithFloat:352] forKey:@"x"];
        [landscape setObject:[NSNumber numberWithFloat:259] forKey:@"y"];
        [background setObject:landscape forKey:@"l"];
        
        NSMutableDictionary *portrait = [[NSMutableDictionary alloc] init];
        [portrait setObject:[NSNumber numberWithFloat:234] forKey:@"x"];
        [portrait setObject:[NSNumber numberWithFloat:377] forKey:@"y"];
        [background setObject:portrait forKey:@"p"];
        
        //close button settings
        closeButton =  [[NSMutableDictionary alloc] init];
        [closeButton setObject:TestCloseButtonImage forKey:@"i"];
        [closeButton setObject:[NSNumber numberWithFloat:270] forKey:@"x"];
        [closeButton setObject:[NSNumber numberWithFloat:0] forKey:@"y"];
        [closeButton setObject:[NSNumber numberWithFloat:30] forKey:@"h"];
        [closeButton setObject:[NSNumber numberWithFloat:30] forKey:@"w"];
        //location settings for the ad
        location = [[NSMutableDictionary alloc] init];
        [location setObject:[NSNumber numberWithFloat:0] forKey:@"x"];
        [location setObject:[NSNumber numberWithFloat:0] forKey:@"y"];
        [location setObject:[NSNumber numberWithFloat:250] forKey:@"h"];
        [location setObject:[NSNumber numberWithFloat:300] forKey:@"w"];
        
    } else if (responseType == FrameResponseFullscreenInternalTargetUrl ||
               responseType == FrameResponseFullscreenInternalTargetData ||
               responseType == FrameResponseFullscreenInternalNullTarget){
        
        
        ad = [[NSMutableDictionary alloc] init];
        [ad setObject:[NSNumber numberWithInt:1] forKey:@"fullscreen"];
        [ad setObject:TestCloseUrl forKey:@"d"];
        [ad setObject:TestClickLink forKey:@"clickLink"];
        
        
        [ad setObject:TestHtmlContent forKey:@"htmlContent"];
        
        [ad setObject:TestImpressionUrl forKey:@"s"];
        [ad setObject:TestClickUrl forKey:@"t"];
        [ad setObject:TestButtonTypeHtml forKey:@"closeButtonType"];
        [ad setObject:TestAdTypeHtml forKey:@"adType"];
        [ad setObject:TestCloseLink forKey:@"closeButtonLink"];
    
        if(responseType == FrameResponseFullscreenInternalTargetUrl){
            [ad setObject:TestTargetUrl forKey:@"targetURL"];
            [ad setObject:TestTargetTypeUrl forKey:@"targetType"];
        } else if (responseType == FrameResponseFullscreenInternalTargetData){
            [ad setObject:TestTargetData forKey:@"targetData"];
            [ad setObject:TestTargetTypeData forKey:@"targetType"];
        } else if (responseType == FrameResponseFullscreenInternalNullTarget){
            [ad setObject:[NSNull null] forKey:@"targetURL"];
            [ad setObject:TestTargetTypeUrl forKey:@"targetType"];
        }
    } else if (responseType == FrameResponseThirdPartyHtmlClose || responseType == FrameResponseThirdPartyNativeClose){
        
        ad = [[NSMutableDictionary alloc] init];
        [ad setObject:[NSNumber numberWithInt:1] forKey:@"fullscreen"];
        [ad setObject:TestHtmlContent forKey:@"htmlContent"];
        [ad setObject:[NSNull null] forKey:@"clickLink"];
        [ad setObject:@"provider" forKey:@"adProvider"];
        [ad setObject:TestTargetTypeExternal forKey:@"targetType"];
        [ad setObject:TestImpressionUrl forKey:@"s"];
        [ad setObject:TestCloseUrl forKey:@"d"];
        [ad setObject:TestClickUrl forKey:@"t"];
        [ad setObject:TestAdTypeHtml forKey:@"adType"];
    
        if(responseType == FrameResponseThirdPartyNativeClose){
            [ad setObject:TestButtonTypeNative forKey:@"closeButtonType"];
            [ad setObject:[NSNull null] forKey:@"closeLink"];
            
            closeButton =  [[NSMutableDictionary alloc] init];
            [closeButton setObject:TestCloseButtonImage forKey:@"i"];
            [closeButton setObject:[NSNumber numberWithFloat:26] forKey:@"h"];
            [closeButton setObject:[NSNumber numberWithFloat:26] forKey:@"w"];
        } else {
            [ad setObject:TestButtonTypeHtml forKey:@"closeButtonType"];
            [ad setObject:TestCloseLink forKey:@"closeButtonLink"];
        }
    }
    
    if(ad){
        [ads addObject:ad];
    }
    
    if(background){
        [response setObject:background forKey:@"b"];
    }
    
    if(closeButton){
        [response setObject:closeButton forKey:@"c"];
    }
    
    if(location){
        [response setObject:location forKey:@"l"];
    }
    
    [response setObject:ads forKey:@"a"];
    return response;
}

-(void) assertAdTrackingInfo:(PNAd *) ad{
    XCTAssertEqualObjects(ad.clickUrl, TestClickUrl, @"Click url is set up correctly");
    XCTAssertEqualObjects(ad.closeUrl, TestCloseUrl, @"Close url is set up correctly");
    XCTAssertEqualObjects(ad.impressionUrl, TestImpressionUrl, @"Impression url is set");
}

-(void) assertAdTargetInfo:(FrameResponseType) responseType ad : (PNAd *) ad{
    if(responseType == FrameResponseFullscreenInternalNullTarget ||
       responseType == FrameResponseAdvancedInternalNullTarget){
        XCTAssertEqual(ad.targetType, AdTargetUrl, @"Target type is URL");
        XCTAssertNil(ad.targetUrl, @"Target url is null");
        XCTAssertNil(ad.targetData, @"Target data is null");
    } else if(responseType == FrameResponseFullscreenInternalTargetData ||
              responseType == FrameResponseFullscreenInternalTargetData) {
        XCTAssertEqual(ad.targetType, AdTargetData, @"Target type is data");
        XCTAssertNil(ad.targetUrl, @"Target url is null");
        XCTAssertEqualObjects(ad.rawTargetData, TestTargetData, @"Raw target data is set");
        
        NSMutableDictionary *targetData = [[NSMutableDictionary alloc] init];
        [targetData setObject:@"test" forKey:@"data"];
        XCTAssertEqualObjects(ad.targetData, targetData, @"Target data is set");
    } else if(responseType == FrameResponseFullscreenInternalTargetUrl ||
              responseType == FrameResponseFullscreenInternalTargetUrl) {
        XCTAssertEqual(ad.targetType, AdTargetUrl, @"Target type is URL");
        XCTAssertEqualObjects(ad.targetUrl, TestTargetUrl, @"Target url is set");
        XCTAssertNil(ad.targetData, @"Target data is null");
    } else if (responseType == FrameResponseThirdPartyHtmlClose ||
               responseType == FrameResponseThirdPartyNativeClose){
        XCTAssertNil(ad.targetUrl, @"Target url is null");
        XCTAssertNil(ad.targetData, @"Target data is null");
        XCTAssertEqual(ad.targetType, AdTargetExternal);
    }
}

-(void) assertFullscreenInternalAdWithType: (FrameResponseType) responseType {
    
    NSDictionary * response = [self factoryForFrameResponseData:responseType];
    
    NSError *error = nil;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    
    XCTAssertNil(error, @"Test data was serialized properly");
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:jsonData];
    
    XCTAssertNil(frame.background, @"The background should be nil");
    
    XCTAssertTrue([frame.ad isKindOfClass:[PNHtmlAd class]], @"This ad is an HTML ad");
    PNHtmlAd *htmlAd = (PNHtmlAd *)frame.ad;
    
    XCTAssertEqualObjects(htmlAd.clickLink, TestClickLink, @"Click link is set up correctly");
    XCTAssertEqual(htmlAd.fullscreen, YES, @"Html ad is fullscreen");
    XCTAssertEqualObjects(htmlAd.htmlContent, TestHtmlContent, @"Html content is set");
   
    XCTAssertTrue([frame.closeButton isKindOfClass:[PNHtmlCloseButton class]], @"This close button is an HTML close button");
    
    PNHtmlCloseButton *closeButton = (PNHtmlCloseButton *)frame.closeButton;
    XCTAssertEqualObjects(closeButton.closeButtonLink, TestCloseLink, @"Close Link is set correctly");
    
    [self assertAdTrackingInfo:htmlAd];
    [self assertAdTargetInfo:responseType ad:htmlAd];
}

-(void) assertThirdPartyAds:(FrameResponseType) responseType{
    NSDictionary * response = [self factoryForFrameResponseData:responseType];
    
    NSError *error = nil;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    
    XCTAssertNil(error, @"Test data was serialized properly");
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:jsonData];
    
    XCTAssertNil(frame.background, @"The background should be nil");
    
    XCTAssertTrue([frame.ad isKindOfClass:[PNHtmlAd class]], @"This ad is an HTML ad");
    PNHtmlAd *htmlAd = (PNHtmlAd *)frame.ad;
    
    XCTAssertNil(htmlAd.clickLink, @"Click link is set up correctly");
    XCTAssertEqual(htmlAd.fullscreen, YES, @"Html ad is fullscreen");
    XCTAssertEqualObjects(htmlAd.htmlContent, TestHtmlContent, @"Html content is set");
    [self assertAdTargetInfo:responseType ad:htmlAd];
    [self assertAdTrackingInfo:htmlAd];
    
    if(responseType == FrameResponseThirdPartyHtmlClose){
        XCTAssertTrue([frame.closeButton isKindOfClass:[PNHtmlCloseButton class]], @"This close button is an HTML close button");
        PNHtmlCloseButton *closeButton = (PNHtmlCloseButton *)frame.closeButton;
        XCTAssertEqualObjects(closeButton.closeButtonLink, TestCloseLink, @"Close Link is set correctly");
    } else if(responseType == FrameResponseThirdPartyNativeClose) {
        XCTAssertTrue([frame.closeButton isKindOfClass:[PNNativeCloseButton class]], @"This close button is a native close button");
        PNNativeCloseButton *closeButton = (PNNativeCloseButton *)frame.closeButton;
        XCTAssertEqual(closeButton.dimensions, CGRectMake(0,0, 26, 26), @"Close button dimensions set correctly");
        XCTAssertEqualObjects(closeButton.imageUrl, TestCloseButtonImage, @"Close button image set correctly");
    } else {
        XCTFail(@"You're holding it wrong.. Bad test setup");
    }
}

-(void) assertAdvancedAd:(FrameResponseType) responseType{
    NSDictionary * response = [self factoryForFrameResponseData:responseType];
    
    NSError *error = nil;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    
    XCTAssertNil(error, @"Test data was serialized properly");
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:jsonData];
    
    PNBackground *background = frame.background;
    XCTAssertEqualObjects(background.imageUrl, TestBackgroundImage, @"Background image is set");
    XCTAssertEqual(background.landscapeDimensions, CGRectMake(352, 259, 300, 250), @"Background landscape dimensions is set");
    XCTAssertEqual(background.portraitDimensions, CGRectMake(234, 377, 300, 250), @"Background portrait dimensions is set");
    
    PNNativeCloseButton *closeButton = frame.closeButton;
    XCTAssertEqualObjects(closeButton.imageUrl, TestCloseButtonImage, @"Close button image is set");
    XCTAssertEqual(closeButton.dimensions, CGRectMake(270, 0, 30, 30), @"Close button dimensions is set");
    
    PNNativeImageAd *staticAd = (PNNativeImageAd *)frame.ad;
    XCTAssertEqualObjects(staticAd.imageUrl, TestImageUrl, @"Ad image is set");
    XCTAssertEqual(staticAd.dimensions, CGRectMake(0, 0, 300, 250), @"Close button dimensions is set");
    
    [self assertAdTargetInfo:responseType ad:staticAd];
    XCTAssertEqual(staticAd.fullscreen, NO, @"Full screen is set");
}

-(void) testEmptyAdArray{
    NSDictionary * response = [self factoryForFrameResponseData:FrameResponseEmpty];

    NSError *error = nil;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    
    XCTAssertNil(error, @"Test data was serialized properly");
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:jsonData];
    
    XCTAssertNil(frame.background, @"The background should be nil");
    XCTAssertNil(frame.closeButton, @"The close button should be nil");
    XCTAssertNil(frame.ad, @"The ad is nil");
}


-(void) testFullscreenInternalAdTargetUrl{
    [self assertFullscreenInternalAdWithType: FrameResponseFullscreenInternalTargetUrl];
}

-(void) testFullscreenInternalAdTargetData{
    [self assertFullscreenInternalAdWithType: FrameResponseFullscreenInternalTargetData];
}

-(void) testFullscreenInternalAdNullTarget{
    [self assertFullscreenInternalAdWithType: FrameResponseFullscreenInternalNullTarget];
}

-(void) testThirdPartyNativeClose{
    [self assertThirdPartyAds:FrameResponseThirdPartyNativeClose];
}

-(void) testThirdPartyHtmlClose{
    [self assertThirdPartyAds:FrameResponseThirdPartyHtmlClose];
}

-(void) testAdvancedAdTargetUrl{
    [self assertAdvancedAd:FrameResponseAdvancedInternalTargetUrl];
}

-(void) testAdvancedAdTargetData{
    [self assertAdvancedAd:FrameResponseAdvancedInternalTargetData];
}

-(void) testAdvancedAdNullTarget{
    [self assertAdvancedAd:FrameResponseAdvancedInternalNullTarget];
}
@end
