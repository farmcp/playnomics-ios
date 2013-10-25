Playnomics PlayRM iOS SDK Integration Guide
=============================================

[![Build Status](https://api.travis-ci.org/playnomics/playnomics-ios.png)](https://travis-ci.org/playnomics/playnomics-ios)
## Considerations for Cross-Platform Applications

If you want to deploy your app to multiple platforms (eg: Android and the Unity Web player), you'll need to create separate applications in the control panel. Each application must incorporate a separate `<APPID>` particular to that application. In addition, placements and their respective creative uploads will be particular to that app in order to ensure that they are sized appropriately - proportionate to your app screen size.

Getting Started
===============	

## Download and Installing the SDK

You can download the SDK from our [releases page](https://github.com/playnomics/playnomics-ios/releases), or you can add our SDK to your [CocoaPods](http://github.com/CocoaPods) `Podfile` with `pod "Playnomics"`.

All of the necessary install files are in the *Playnomics* folder:
* libPlaynomics.a
* Playnomics.h
* PNLogger.h

You can also fork this [repo](https://github.com/playnomics/playnomics-ios), building the PlaynomicsSDK project.

Import the SDK files into your existing app through Xcode.

## Starting a PlayRM Session

To start tracking user engagement data, you need to first start a session. **No other SDK calls will work until you do this.**

In the class that implements `AppDelegate`, start the PlayRM Session in the `didFinishLaunchingWithOptions` method.

```objectivec
#import "AppDelegate.h"
#import "Playnomics.h"

@implementation AppDelegate

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Enable test mode to view your events in the Validator. Remove this line of code before releasing your application to the app store.
    [Playnomics setTestMode: YES];
    const unsigned long long applicationId = <APPID>;
    [Playnomics startWithApplicationId:applicationId];

    //other code to initialize your iOS application below this
}
```
You can either provide a dynamic `<USER-ID>` to identify each user:

```objectivec
+ (BOOL) startWithApplicationId:(unsigned long long) applicationId andUserId: (NSString *) userId;
```

or have PlayRM, generate a *best-effort* unique-identifier for the user:

```objectivec
+ (BOOL) startWithApplicationId:(unsigned long long) applicationId;
```

If you do choose to provide a `<USER-ID>`, this value should be persistent, anonymized, and unique to each user. This is typically discerned dynamically when a user starts the application. Some potential implementations:

* An internal ID (such as a database auto-generated number).
* A hash of the user's email address.

**You cannot use the user's Facebook ID or any personally identifiable information (plain-text email, name, etc) for the `<USER-ID>`.**

## Tracking Intensity

To track user intensity, PlayRM needs to know about UI events occurring in the app. We provide an implementation of `UIApplication<UIApplicationDelegate>`, which automatically captures these events. In the **main.m** file of your iOS application, you pass this class name into the `UIApplicationMain` method:

```objectivec
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Playnomics.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, NSStringFromClass([PNApplication class]), NSStringFromClass([AppDelegate class]));
    }
}
```

If you already have your own implementation of `UIApplication<UIApplicationDelegate>` in main.m, just add the following code snippet to your class implementation:

```objectivec
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Playnomics.h"

@implementation YourApplication
- (void) sendEvent: (UIEvent *) event {
    [super sendEvent:event];
    [Playnomics onUIEventReceived:event];
}
@end
```

Messaging Integration
=====================
This guide assumes you're already familiar with the concept of placements and messaging, and that you have all of the relevant `placements` setup for your application.

If you are new to PlayRM's messaging feature, please refer to <a href="http://integration.playnomics.com" target="_blank">integration documentation</a>.

Once you have all of your placements created with their associated `<PLAYRM-FRAME-ID>`s, you can start the integration process.

## SDK Integration

We recommend that you preload all placements when your application loads, so that you can quickly show a message when necessary:

```objectivec
+ (void) preloadFramesWithIds: (NSString *)firstFrameId, ... NS_REQUIRES_NIL_TERMINATION;
```

```objectivec
//...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //...
    [Playnomics setTestMode:NO];
    [Playnomics startWithApplicationId:applicationId];
    //preloads placements at app start
    [Playnomics preloadFramesWithIds:@"frame-ID-1", @"frame-ID-2", @"frame-ID-2", @"frame-ID-3", nil];
    //...
}
```

Then when you're ready, you can show the placement:

```objectivec
+ (void) showFrameWithId:(NSString *) frameId;
```

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>frameId</code></td>
            <td>NSString*</td>
            <td>Unique identifier for a placement, the <code>&lt;PLAYRM-FRAME-ID&gt;</code></td>
        </tr>
    </tbody>
</table>

Optionally, associate a class that can respond to the `PlaynomicsFrameDelegate` protocol, to process rich data callbacks. See [Using Rich Data Callbacks](#using-rich-data-callbacks) for more information.

```objectivec
+ (void) showFrameWithId:(NSString *) frameId
                delegate:(id<PlaynomicsFrameDelegate>) delegate;
```
<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>frameId</code></td>
            <td>NSString*</td>
            <td>Unique identifier for a placement, the <code>&lt;PLAYRM-FRAME-ID&gt;</code></td>
        </tr>
        <tr>
            <td><code>frameDelegate</code></td>
            <td>id&lt;PlaynomicsFrameDelegate&gt;</td>
            <td>
                Processes rich data callbacks, see <a href="#using-rich-data-callbacks">Using Rich Data Callbacks</a>. This delegate is not <strong>retained</strong>, you are responsible for managing the lifecycle of this object.
            </td>
        </tr>
    </tbody>
</table>

By default, the SDK renders frames on the Root `ViewController`'s view. If your application uses multiple `ViewController`s, you need to explicitally set the parent View for the frame by calling:

```objectivec
+ (void) setFrameParentView:(UIView *) parentView;
```

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>parentView</code></td>
            <td>UIView *</td>
            <td>The parent view where the frame should be rendered.</td>
        </tr>
    </tbody>
</table>

Do this before, calling `showFrameWithId`:

```objectivec
-(void) viewDidLoad {
    //Show the frame after the ViewController has been loaded
    [Playnomics setFrameParentView: self.view];
    [Playnomics showFrameWithId:@"frame-ID-1"];
}
```

## Using Rich Data Callbacks

Using an implementation of `PlaynomicsFrameDelegate` your application can receive notifications when a placement:

* Is shown in the screen.
* Receives a touch event on the creative.
* Is dismissed by the user, when they press the close button.
* Can't be rendered in the view because of connectivity or other issues.

```objectiveC
@protocol PlaynomicsFrameDelegate <NSObject>
@optional
-(void) onShow: (NSDictionary *) jsonData;
-(void) onTouch: (NSDictionary *) jsonData;
-(void) onClose: (NSDictionary *) jsonData;
-(void) onDidFailToRender;
@end
```

For each of these events, your delegate may also receive Rich Data that has been tied with this creative. Rich Data is a JSON message that you can associate with your message creative. In all cases, the `jsonData` value can be `nil`.

The actual contents of your JSON message can be delayed until the time of the messaging campaign configuration. However, the structure of your message needs to be decided before you can process it in your application. See [example use-cases for rich data](#example-use-cases-for-rich-data) below.

## Validate Integration
After you've finished the installation, you should verify that your application is correctly integrated by checkout the integration verification section of your application page.

Simply visit the self-check page for your application: **`https://controlpanel.playnomics.com/applications/<APPID>`**

The page will update with events as they occur in real-time, with any errors flagged. Visit the  <a href="http://integration.playnomics.com/technical/#self-check">self-check validation guide</a> for more information.

We strongly recommend running the self-check validator before deploying your newly integrated application to production.

## Switch SDK to Production Mode

Once you have [validated](#validate-integration) your integration, switch the SDK from **test** to **production** mode by simply setting `setTestMode` field to `NO` (or by removing/commenting out the call entirely) in the initialization block:

```objectivec
//...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //...
    [Playnomics setTestMode:NO];
    [Playnomics startWithApplicationId:applicationId];
    //...
}
```
If you ever wish to test or troubleshoot your integration later on, simply set `setTestMode` back to `YES` and revisit the self-check validation tool for your application:

**`https://controlpanel.playnomics.com/applications/<APPID>`**


**Congratulations!** You've completed our basic integration. You will now be able to track engagement data through the PlayRM dashboard.

Full Integration
================

<div class="outline">
    <ul>
        <li>
            <a href="#monetization">Monetization</a>
        </li>
        <li>
            <a href="#install-attribution">Install Attribution</a>
        </li>
        <li>
            <a href="#custom-event-tracking">Custom Event Tracking</a>
        </li>
        <li>
            <a href="#push-notifications">Push Notifications</a>
        </li>
        <li>
            <a href="#example-use-cases-for-rich-data">Example Use-Cases for Rich Data</a>
        </li>
        <li>
            <a href="#support-issues">Support Issues</a>
        </li>
        <li>
            <a href="#change-log>">Change Log</a>
        </li>
    </ul>
</div>

## Monetization

PlayRM allows you to track monetization through in-app purchases denominated in real US dollars.

```objectivec
+ (void) transactionWithUSDPrice: (NSNumber *) priceInUSD
                        quantity: (NSInteger) quantity;
```
<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>priceInUSD</code></td>
            <td>NSNumber *</td>
            <td>The price of the item in USD.</td>
        </tr>
        <tr>
            <td><code>quantity</code></td>
            <td>NSInteger</td>
            <td>
               The number of items being purchased at the price specified.
            </td>
        </tr>
    </tbody>
</table>


```objectivec

NSNumber * priceInUSD = [NSNumber numberWithFloat:0.99];
NSInteger  quantity = 1;

[Playnomics transactionWithUSDPrice: priceInUSD quantity: quantity];
```

## Install Attribution

PlayRM allows you track and segment based on the source of install attribution. You can track this at the level of a source like *AdMob* or *MoPub*, and optionally include a campaign and an install date. By default, PlayRM tracks the install date by the first day we started seeing engagement date for your users.

```objectivec
+ (void) attributeInstallToSource:(NSString *) source;

+ (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString *) campaign;

+ (void) attributeInstallToSource:(NSString *) source
                     withCampaign:(NSString *) campaign
                    onInstallDate:(NSDate *) installDate;
```

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>source</code></td>
            <td>NSString *</td>
            <td>The source of install.</td>
        </tr>
        <tr>
            <td><code>campaign</code></td>
            <td>NSString *</td>
            <td>
               The campaign for this source.
            </td>
        </tr>
        <tr>
            <td><code>installDate</code></td>
            <td>NSDate *</td>
            <td>
               The date this user installed your app.
            </td>
        </tr>
    </tbody>
</table>

```objectivec
[Playnomics attributeInstallToSource:@"AdMob" withCampaign:@"Holiday" onInstallDate:[NSDate date]];
```

## Custom Event Tracking

Custom Events may be used in a number of ways.  They can be used to track certain key in-app events such as finishing a tutorial or receiving a high score. They may also be used to track other important lifecycle events such as level up, zone unlocked, etc.  PlayRM, by default, supports up to five custom events.  You can then use these custom events to create more targeted custom segments.

Each time a user completes a certain event, track it with this call:

```objectivec
+ (void) milestone: (PNMilestoneType) milestoneType;
```
<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>milestoneType</code></td>
            <td>PNMilestoneType</td>
            <td>
                An enum for custom events 1 through 10. Note that a basic PlayRM account only supports 5 custom events.
            </td>
        </tr>
    </tbody>
</table>

Example client-side calls for users completing events, with generated IDs:

```objectivec
// when custom event CUSTOM1 is completed
[PlaynomicsSession milestone: PNMilestoneCustom1];
```

Push Notifications
==================

## Registering for PlayRM Push Messaging

To get started with PlayRM Push Messaging, your app will need to register with Apple to receive push notifications. Do this by calling the `registerForRemoteNotificationTypes` method on UIApplication.

```objectivec
@implementation AppDelegate

//...

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    const long long applicationId = <APPID>;
    [Playnomics startWithApplicationId:applicationId];

    //enable notifications
    UIApplication *app = [UIApplication sharedApplication];
    [app registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge 
        | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    //...
}
```

Once the user, authorizes push notifications from your app, you need to provide Playnomics with user’s device token:

```objectivec
@implementation AppDelegate

//...

-(void)application:(UIApplication *)application 
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
   [Playnomics enablePushNotificationsWithToken:deviceToken];
}
```

## Push Messaging Impression and Click Tracking

There are 3 situations in which an iOS device can receive a Push Notification

<table>
    <thead>
        <tr>
            <th>Sitatuation</th>
            <th>Push Message Shown?</th>
            <th>Delegate Handler</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>App is not running</td>
            <td rowspan="2">Yes</td>
            <td>didFinishLaunchingWithOptions:(NSDictionary*)launchOptions</td>
        </tr>
        <tr>
            <td>App is running in the background</td>
            <td rowspan="2">
                didReceiveRemoteNotification:(NSDictionary*)userInfo
            </td>
        </tr>
        <tr>
            <td>App is running in the foreground</td>
            <td>No</td>
        </tr>
    </tbody>
</table>

The first situation is automatically handled by the Playnomics SDK. The other two situations, however, need to be implemented in the `didReceiveRemoteNotification` method:

```objectivec
-(void) application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSMutableDictionary *payload = [userInfo mutableCopy];
    [Playnomics pushNotificationsWithPayload:payload];
    [payload release];
}
```

By default, iOS does not show push notifications when your app is already in the foreground. Consequently, PlayRM does NOT track these push notifications as impressions nor clicks. However, if you do circumvent this default behavior and show the Push Notification when the app is in the foreground, you can override this functionality by adding the following line of code in the `didReceiveRemoteNotification` method:

```objectivec
    [payload setObject:[NSNumber numberWithBool:NO] forKey:@"pushIgnored"];
```

This will allow each push notification to be treated as a click even if the app is in the foreground.

## Clearing Push Badge Numbers

When you send push notifications, you can configure a badge number that will be set on your application icon in the home screen. When you send push notifications, you can configure a badge number that will be set on your application. iOS defers the responsibility of resetting the badge number to the developer. 

To do this, insert this code snippet in the `applicationWillResignActive` method of your `UIAppDelegate`

```objectivec
- (void)applicationWillResignActive:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}
```

Example Use-Cases for Rich Data
===============================

Here are three common use cases for placements and a messaging campaign:

* [App Start Placement](#app-start-placement)
* [Currency Balance Low Placement](#currency-balance-low-placement) - for instance, when the user is running low on premium currency
* [Level Complete Placement](#level-complete-placement)

### App Start Placement

In this use-case, we want to configure a placement that is always shown to users when they start a new session. The message shown to the user may change based on the desired segments:

<table>
    <thead>
        <tr>
            <th>
                Segment
            </th>
            <th>
                Priority
            </th>
            <th>
                Callback Behavior
            </th>
            <th>
                Creative
            </th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
                At-Risk
            </td>
            <td>1st</td>
            <td>
                In this case, we're worried once-active users are now in danger of leaving the app. We might offer them <strong>50 MonsterBucks</strong> to bring them back.
            </td>
            <td>
                <img src="http://playnomics.com/integration-dev/img/messaging/50-free-monster-bucks.png"/>
            </td>
        </tr>
        <tr>
            <td>
                Lapsed 7 or more days
            </td>
            <td>2nd</td>
            <td>
                In this case, we want to thank the user for coming back and incentivize these lapsed users to continue doing so. We might offer them <strong>10 MonsterBucks</strong> to increase their engagement and loyalty.
            </td>
            <td> 
                <img src="http://playnomics.com/integration-dev/img/messaging/10-free-monster-bucks.png"/>
            </td>
        </tr>
        <tr>
            <td>
                Default - users who don't fall into either segment.
            </td>
            <td>3rd</td>
            <td>
                In this case, we can offer a special item to them for returning to the app.
            </td>
            <td>
                <img src="http://playnomics.com/integration-dev/img/messaging/free-bfb.png"/>
            </td>
        </tr>
    </tbody>
</table>

```objectivec
//AwardFrameDelegate.h

#import <Foundation/Foundation.h>
#import "Playnomics.h"
@interface AwardFrameDelegate : NSObject<PlaynomicsFrameDelegate>
@end

//AwardFrameDelegate.m

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AwardFrameDelegate.h"
#import "Inventory.h"

@implementation AwardFrameDelegate
- (void)onTouch:(NSDictionary *)jsonData{
    
    if(jsonData){
        if([jsonData objectForKey: @"type"] != (id)[NSNull null] &&
             [[jsonData objectForKey:@"type"] isEqualToString: @"award"]){

            if([jsonData objectForKey: @"award"] != (id)[NSNull null]){
                NSDictionary* award = [jsonData objectForKey: @"award"];

                NSString* item = [award objectForKey: @"item"];
                NSNumber* quantity = [award objectForKey: @"quantity"];

                //call your own inventory object
                [[Inventory sharedInstanced] addItem:item andQuantity: quanity];
            }
        }
    }
}
@end
```

And then attaching this `AwardFrameDelegate` class to the frame shown in the first app scene:

```objectiveC
@implementation GameViewController{
    AwardFrameDelegate* _awardDelegate;
}

-(void) viewDidLoad{
    _awardDelegate = [[AwardFrameDelegate alloc] init];
    [Playnomics showFrameWithId: frameId delegate: _awardDelegate];
}

-(void) dealloc{
    //make sure to release the delegate, if you are not using ARC
    [_awardDelegate release];
    [super dealloc];
}
@end
```

The related messages would be configured in the Control Panel to use this callback by placing this in the **Target Data** for each message:

Grant 10 Monster Bucks
```json
{
    "type" : "award",
    "award" : 
    {
        "item" : "MonsterBucks",
        "quantity" : 10
    }
}
```

Grant 50 Monster Bucks
```json
{
    "type" : "award",
    "award" : 
    {
        "item" : "MonsterBucks",
        "quantity" : 50
    }
}
```

Grant Bazooka
```json
{
    "type" : "award",
    "award" :
    {
        "item" : "Bazooka",
        "quantity" : 1
    }
}
```

### Currency Balance Low Placement

An advantage of a *dynamic* placement is that it can be triggered by in-app events. For each in-app event you would configure a separate placement. While segmentation may be helpful in deciding what message you show, it may be sufficient to show the same message to all users.

For example, a user may deplete their premium currency and you want to remind them that they can re-up through your store. In this context, we display the same message to all users.

<table>
    <thead>
        <tr>
            <th>
                Segment
            </th>
            <th>
                Priority
            </th>
            <th>
                Callback Behavior
            </th>
            <th>
                Creative
            </th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
                Default - all users, because this message is intended for anyone using the app.
            </td>
            <td>1st</td>
            <td>
                You notice that the user’s in-app, premium currency drops below a certain threshold, now you can prompt them to re-up with this <strong>message</strong>.
            </td>
            <td>
                <img src="http://playnomics.com/integration-dev/img/messaging/running-out-of-monster-bucks.png"/>
            </td>
        </tr>
    </tbody>
</table>

```objectivec
//StoreFrameDelegate.h

#import <Foundation/Foundation.h>
#import "Playnomics.h"
@interface StoreFrameDelegate : NSObject<PlaynomicsFrameDelegate>
@end

//StoreFrameDelegate.m

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "StoreFrameDelegate.h"
#import "Inventory.h"

@implementation StoreFrameDelegate
- (void)onTouch:(NSDictionary *)jsonData{
    if(jsonData){
        if([jsonData objectForKey: @"type"] != (id)[NSNull null] && 
            [[jsonData objectForKey:@"type"] isEqualToString: @"action"]){
            
            if([jsonData objectForKey: @"action"] != (id)[NSNull null] && 
                [[jsonData objectForKey:@"type"] isEqualToString: @"openStore"]){
                
                [[Store sharedInstance] open];
            }
        }
    }
}
@end
```

The Default message would be configured in the Control Panel to use this callback by placing this in the **Target Data** for the message:

```json
{
    "type" : "action",
    "action" : "openStore"
}
```

### Level Complete Placement

In the following example, we wish to generate third-party revenue from users unlikely to monetize by showing them a segmented message after completing a level or challenge: 

<table>
    <thead>
        <tr>
            <th>
                Segment
            </th>
            <th>
                Priority
            </th>
            <th>
                Callback Behavior
            </th>
            <th>
                Creative
            </th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
                Non Monetizers, in their 5th day of app usage
            </td>
            <td>1st</td>
            <td>Show them a 3rd party ad, because they are unlikely to monetize.</td>
            <td>
                <img src="http://playnomics.com/integration-dev/img/messaging/third-party-ad.png"/>
            </td>
        </tr>
        <tr>
            <td>
                Default: everyone else
            </td>
            <td>2nd</td>
            <td>
                You simply congratulate them on completing the level and grant them some attention currency, "Mana" for completing the level.
            </td>
            <td>
                <img src="http://playnomics.com/integration-dev/img/messaging/darn-good-job.png"/>
            </td>
        </tr>
    </tbody>
</table>

This is another continuation on the `AwardFrameDelegate`, with some different data. The related messages would be configured in the Control Panel:

* **Non-monetizers, in their 5th day of app usage**, a Target URL: `HTTP URL for Third Party Ad`
* **Default**, Target Data:

```json
{
    "type" : "award",
    "award" :
    {
        "item" : "Mana",
        "quantity" : 20
    }
}
```

Support Issues
==============
If you have any questions or issues, please contact <a href="mailto:support@playnomics.com">support@playnomics.com</a>.

Change Log
==========
#### Version 1.2.0
* Support for 64 bit architectures.

#### Version 1.1.1
* Send IDFA and allowTracking every time we request an ad for a placement.

#### Version 1.1.0
* Support up to 25 custom events in the SDK

#### Version 1.0.1
* Minor bug fixes

#### Version 1
* Support for 3rd party html-based advertisements
* Support for simplified, fullscreen placements and internal messaging creatives
* A greatly simplified interface and API
* More robust error and exception handling
* Performance improvements, including background event queuing and better support for offline-mode
* Tested against iOS 7, with support for iOS 5 and 6
* Version number reset

#### Version 9
* Adding support for Rich Data Callbacks
* Targeting the arm7, arm7s, i386 CPU Arcitectures
* Now compatible with iOS 5 and above
* Supporting touch events for Cocos2DX

####  Version 8.2
* Support for video ads
* Capture advertising tracking information

####  Version 8.1.1
* Renamed method in PlaynomicsMessaging.h from "initFrameWithId" to "createFrameWithId"
* Minor bug fixes

####  Version 8.1
* Support for push notifications
* Minor bug fixes

####  Version 8
* Support for internal messaging
* Added custom event module

####  Version 7
* Support for new iOS hardware, iPhone 5s

#### Version 6
* Improved dual support for iOS4 and iOS5+ utilizing best methods depending on runtime version
* This build is a courtesy build provided for debugging for an irreproducible customer-reported crash that was unrelated to PlayRM code. 

#### Version 4
* Support for iOS version 4.x

#### Version 3
* Improved crash protection
* Ability to run integrated app on the iOS simulator
* Minor tweaks to improve connection to server

#### Version 2
* First production release

View version tags <a href="https://github.com/playnomics/playnomics-ios/tags">here</a>
