//
//  PNAdInfo.h
//  PlaynomicsSDK
//
//  Created by Jared Jenkins on 9/24/13.
//
//

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

typedef NS_ENUM(int, AdTarget){
    AdTargetUnknown = 0,
    AdTargetUrl = 1,
    AdTargetData = 2,
    AdTargetExternal = 3
};

typedef NS_ENUM(int, AdType){
    AdTypeImage = 0,
    AdTypeVideo = 1,
    AdTypeWebView = 2,
    AdTypeUnknown = 3
};

typedef NS_ENUM(int, CloseButtonType){
    CloseButtonHtml = 0,
    CloseButtonNative = 1,
    CloseButtonUnknown = 2
};

@interface PNBackground : NSObject
@property (assign) CGRect landscapeDimensions;
@property (assign) CGRect portraitDimensions;
@property (retain) NSString *imageUrl;

-(CGRect) dimensionsForCurrentOrientation;
@end

@interface PNAd : NSObject
@property (retain) NSString *closeUrl;

@property (retain) NSString *impressionUrl;

@property (retain) NSString *clickUrl;
@property (retain) NSDictionary *targetData;
@property (retain) NSString *rawTargetData;
@property (retain) NSString *targetUrl;

@property (assign) AdType adType;
@property (assign) AdTarget targetType;
@property (assign) BOOL fullscreen;
@end

@interface PNHtmlAd : PNAd
@property (retain) NSString *htmlContent;
@property (retain) NSString *clickLink;
@end

@interface PNNativeImageAd : PNAd
@property (retain) NSString *imageUrl;
@property (assign) CGRect dimensions;
@end

@interface PNNativeCloseButton : NSObject
@property (retain) NSString *imageUrl;
@property (assign) CGRect dimensions;
@end

@interface PNHtmlCloseButton : NSObject
@property (retain) NSString *closeButtonLink;
@end