//
//  PNFrameResponseTests.m
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/24/13.
//
//

#import <XCTest/XCTest.h>
#import "PNFrameResponse.h"

#define TestTargetTypeExternal @"external"
#define TestTargetTypeUrl @"url"
#define TestTargetTypeData @"data"
#define TestTargetData @"{\"key\":\"value\"}"

#define TestTargetUrl @"http://targetUrl"


#define TestBackgroundImage @"http://backgroundImageUrl"
#define TestBackgroundOrientationDetect @"detect"

#define TestButtonTypeNative @"native"
#define TestButtonTypeHtml @"html"

#define TestCloseButtonImage @"http://closeButtonImage"
#define TestImageUrl @"http://primaryImage"

#define TestCloseLink @"pn://close"
#define TestClickLink @"pn://click"

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

-(NSData *) factoryForFrameResponseData: (FrameResponseType) responseType{
    
    NSString *resource = nil;
    
    if(responseType == FrameResponseAdvancedInternalNullTarget){
        resource = @"sample-internal-ad-native-null-target";
    } else if(responseType == FrameResponseAdvancedInternalTargetData){
        resource = @"sample-internal-ad-native-target-data";
    } else if(responseType == FrameResponseAdvancedInternalTargetUrl){
        resource = @"sample-internal-ad-native-target-url";
    } else if(responseType == FrameResponseEmpty){
        resource = @"sample-empty-response";
    } else if(responseType == FrameResponseFullscreenInternalNullTarget){
        resource = @"sample-internal-ad-all-html-null-target";
    } else if(responseType == FrameResponseFullscreenInternalTargetData){
        resource = @"sample-internal-ad-all-html-target-data";
    } else if(responseType == FrameResponseFullscreenInternalTargetUrl){
        resource = @"sample-internal-ad-all-html-target-url";
    } else if(responseType == FrameResponseThirdPartyNativeClose){
        resource = @"sample-third-party-ad-native-close";
    } else if(responseType == FrameResponseThirdPartyHtmlClose){
        resource = @"sample-third-party-ad-html-close";
    }
    
    NSAssert(resource != nil, @"Frame Response must be valid");
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *jsonPath = [bundle pathForResource: resource ofType:@"json"];
    return [[NSData alloc] initWithContentsOfFile:jsonPath];
}

-(void) assertAdTrackingInfo:(PNAd *) ad responseType: (FrameResponseType) responseType{
    if(responseType == FrameResponseFullscreenInternalNullTarget || responseType == FrameResponseAdvancedInternalNullTarget){
        XCTAssertNil(ad.clickUrl, @"Click url is null");
    } else {
        XCTAssertEqualObjects(ad.clickUrl, TestClickUrl, @"Click url is set up correctly");
    }
        
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
        [targetData setObject:@"value" forKey:@"key"];
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
    
    NSData * response = [self factoryForFrameResponseData : responseType];
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:response];
    
    XCTAssertNil(frame.background, @"The background should be nil");
    
    XCTAssertTrue([frame.ad isKindOfClass:[PNHtmlAd class]], @"This ad is an HTML ad");
    PNHtmlAd *htmlAd = (PNHtmlAd *)frame.ad;
    
    XCTAssertEqualObjects(htmlAd.clickLink, TestClickLink, @"Click link is set up correctly");
    XCTAssertEqual(htmlAd.fullscreen, YES, @"Html ad is fullscreen");
    XCTAssertEqualObjects(htmlAd.htmlContent, TestHtmlContent, @"Html content is set");
   
    XCTAssertTrue([frame.closeButton isKindOfClass:[PNHtmlCloseButton class]], @"This close button is an HTML close button");
    
    PNHtmlCloseButton *closeButton = (PNHtmlCloseButton *)frame.closeButton;
    XCTAssertEqualObjects(closeButton.closeButtonLink, TestCloseLink, @"Close Link is set correctly");
    
    [self assertAdTrackingInfo:htmlAd responseType: responseType];
    [self assertAdTargetInfo:responseType ad:htmlAd];
}

-(void) assertThirdPartyAds:(FrameResponseType) responseType{
    NSData * response = [self factoryForFrameResponseData : responseType];
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:response];
    
    XCTAssertNil(frame.background, @"The background should be nil");
    
    XCTAssertTrue([frame.ad isKindOfClass:[PNHtmlAd class]], @"This ad is an HTML ad");
    PNHtmlAd *htmlAd = (PNHtmlAd *)frame.ad;
    
    XCTAssertNil(htmlAd.clickLink, @"Click link is set up correctly");
    XCTAssertEqual(htmlAd.fullscreen, YES, @"Html ad is fullscreen");
    XCTAssertEqualObjects(htmlAd.htmlContent, @"<html>Third party ad here</html>", @"Html content is set");
    [self assertAdTargetInfo:responseType ad:htmlAd];
    [self assertAdTrackingInfo:htmlAd responseType: responseType];
    
    if(responseType == FrameResponseThirdPartyHtmlClose){
        XCTAssertTrue([frame.closeButton isKindOfClass:[PNHtmlCloseButton class]], @"This close button is an HTML close button");
        PNHtmlCloseButton *closeButton = (PNHtmlCloseButton *)frame.closeButton;
        XCTAssertEqualObjects(closeButton.closeButtonLink, @"applovin://com.applovin.sdk/adservice/close_ad", @"Close Link is set correctly");
    } else if(responseType == FrameResponseThirdPartyNativeClose) {
        XCTAssertTrue([frame.closeButton isKindOfClass:[PNNativeCloseButton class]], @"This close button is a native close button");
        PNNativeCloseButton *closeButton = (PNNativeCloseButton *)frame.closeButton;
        XCTAssertEqual(closeButton.dimensions, CGRectMake(0,0, 26, 26), @"Close button dimensions set correctly");
        XCTAssertEqualObjects(closeButton.imageUrl, @"http://s3.amazonaws.com/pn-assets/close/default/glyphicons_470_remove_white_background.png", @"Close button image set correctly");
    } else {
        XCTFail(@"You're holding it wrong.. Bad test setup");
    }
}

-(void) assertAdvancedAd:(FrameResponseType) responseType{
    NSData * response = [self factoryForFrameResponseData : responseType];
    
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:response];
    PNBackground *background = frame.background;
    
    XCTAssertNil(background.imageUrl, @"Background image is nil");
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
    NSData * response = [self factoryForFrameResponseData : FrameResponseEmpty];
    PNFrameResponse *frame = [[PNFrameResponse alloc] initWithJSONData:response];
    
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
