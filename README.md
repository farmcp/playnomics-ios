Playnomics PlayRM iOS SDK Integration Guide
=============================================


## Considerations for Cross-Platform Applications

If you want to deploy your app to multiple platforms (eg: Android and the Unity Web player), you'll need to create separate applications in the control panel. Each application must incorporate a separate `<APPID>` particular to that application. In addition, placements and their respective creative uploads will be particular to that app in order to ensure that they are sized appropriately - proportionate to your app screen size.

Supports iOS versions 5+.

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

Once you have all of your placements created with their associated `<PLACEMENT-ID>`s, you can start the integration process.

## SDK Integration

We recommend that you preload all placements when your application loads, so that you can quickly show a message when necessary:

```objectivec
+ (void) preloadPlacementsWithNames:(NSString *) firstPlacementName, ... NS_REQUIRES_NIL_TERMINATION;
```

```objectivec
//...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Playnomics startWithApplicationId:applicationId];
    //preloads placements at app start
    [Playnomics preloadPlacementsWithNames:@"placement 1", @"placement 2", @"placement 3", @"placement 4", nil];
    //...
}
```

Then when you're ready, you can show the placement:

```objectivec
+ (void) showPlacementWithName:(NSString *) placementName;
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
            <td><code>placementName</code></td>
            <td>NSString*</td>
            <td>Unique identifier for a placement</code></td>
        </tr>
    </tbody>
</table>

Optionally, associate a class that can respond to the `PlaynomicsPlacementDelegate` protocol, to process rich data callbacks. See [Using Rich Data Callbacks](https://github.com/playnomics/playnomics-ios/wiki/Rich-Data-Callbacks) for more information.

```objectivec
+ (void) showPlacementWithName:(NSString *) placementName
                      delegate:(id<PlaynomicsPlacementDelegate>) delegate;
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
            <td><code>placementName</code></td>
            <td>NSString*</td>
            <td>Unique identifier for a placement</td>
        </tr>
        <tr>
            <td><code>delegate</code></td>
            <td>id&lt;PlaynomicsPlacementDelegate&gt;</td>
            <td>
                Processes rich data callbacks, see <a href="https://github.com/playnomics/playnomics-ios/wiki/Rich-Data-Callbacks">Using Rich Data Callbacks</a>. This delegate is not <strong>retained</strong>, you are responsible for managing the lifecycle of this object.
            </td>
        </tr>
    </tbody>
</table>

By default, the SDK renders placements on the Root `ViewController`'s view. If your application uses multiple `ViewController`s, you need to explicitally set the parent View for the placement by calling:

```objectivec
+ (void) setPlacementParentView:(UIView *) parentView;
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
            <td>The parent view where the placement should be rendered.</td>
        </tr>
    </tbody>
</table>

Do this before, calling `showPlacementWithName`:

```objectivec
-(void) viewDidLoad {
    //Show the placement after the ViewController has been loaded
    [Playnomics setPlacementParentView: self.view];
    [Playnomics showPlacementWithName:@"placement 1"];
}
```

## Using Rich Data Callbacks

Using an implementation of `PlaynomicsPlacementDelegate` your application can receive notifications when a placement:

* Is shown in the screen.
* Receives a touch event on the creative.
* Is dismissed by the user, when they press the close button.
* Can't be rendered in the view because of connectivity or other issues.

```objectiveC
@protocol PlaynomicsPlacementDelegate <NSObject>
@optional
-(void) onShow: (NSDictionary *) jsonData;
-(void) onTouch: (NSDictionary *) jsonData;
-(void) onClose: (NSDictionary *) jsonData;
-(void) onDidFailToRender;
@end
```

For each of these events, your delegate may also receive Rich Data that has been tied with this creative. Rich Data is a JSON message that you can associate with your message creative. In all cases, the `jsonData` value can be `nil`.

The actual contents of your JSON message can be delayed until the time of the messaging campaign configuration. However, the structure of your message needs to be decided before you can process it in your application. See [example use-cases for rich data](https://github.com/playnomics/playnomics-ios/wiki/Rich-Data-Callbacks).

## Validate Integration
After you've finished the installation, you should verify that your application is correctly integrated by checkout the integration verification section of your application page.

Using iOS SDK v1.4.0+ you can register your device as a Test Device and validate your events on the self-check page for your application: **`https://controlpanel.playnomics.com/applications/<APPID>`**

To test your in-app campaigns, you can enter your device's IDFA and select which segments to fall into.  Optionally, you can opt to not select any segments to simply see your device's data flowing through the validator.

This page will update with events as they occur in real-time, with any errors flagged.

We strongly recommend running the self-check validator before deploying your newly integrated application to production.

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
            <a href="https://github.com/playnomics/playnomics-ios/wiki/Rich-Data-Callbacks">
                Rich Data Callbacks
            </a>
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
+ (void) customEventWithName: (NSString *) customEventName;
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
            <td><code>customEventName</code></td>
            <td>NSString *</td>
            <td>
                A string to indentify the event.
            </td>
        </tr>
    </tbody>
</table>

Example client-side calls for users completing events, with generated IDs:

```objectivec
[Playnomics customEventWithName: @"level 1 complete"];
```

Push Notifications
==================

To set up push notifications, please view the [wiki page](https://github.com/playnomics/playnomics-ios/wiki/Push-Notifications).

Support Issues
==============
If you have any questions or issues, please contact <a href="mailto:support@playnomics.com">support@playnomics.com</a>.

Change Log
==========
#### Version 1.4.1
* Start a new session if the last event was captured 30 or more minutes ago

#### Version 1.4.0
* setTestMode is deprecated
* Send IDFA and IDFV for all events
* userId defaults to IDFA if none is passed

#### Version 1.3.0
* Frames are now Placements
    * The frames interface is still usable, but has become deprecated. You will receive build warnings when using these old methods.
* Milestones are now Custom Events
    * The old milestones interface is still usable, but has become deprecated. You will receive build warnings when using these old methods.
    * Custom events are flexible: they can be described by a string, as opposed to just an enum.

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
