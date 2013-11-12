
//
//  ViewController.m
//  PlaynomicsSample
//
//  Created by Martin Harkins on 6/27/12.
//  Copyright (c) 2012 Grio. All rights reserved.
//

#define PNUserDefaultsLastSessionEventTime @"com.playnomics.lastSessionStartTime"
#define PNUserDefaultsLastSessionID @"com.playnomics.lastSessionId"
#define PNUserDefaultsLastUserID @"com.playnomics.lastUserId"
#define PNUserDefaultsLastDeviceToken @"com.playnomics.lastDeviceToken"
#define PNUserDefaultsLastIDFV @"com.playnomics.lastIDFV"

#import "ViewController.h"
#import "Playnomics.h"
#import "FrameDelegate.h"

@implementation ViewController{
    FrameDelegate* _frameDelegate;
}
@synthesize transactionCount;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    if([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)]){
    //    self.extendedLayoutIncludesOpaqueBars = YES;
    } else {
    //    self.wantsFullScreenLayout = YES;
    }
    
    _frameDelegate = [[FrameDelegate alloc] init];
    [super viewDidLoad];
    [Playnomics preloadPlacementsWithNames:@"546e241b9b97149b", @"c6877f336e9d9dda", @"7a9138a971ce1773", @"15bec4e2b78424a2", @"33a3cf0ecfa71c1a", nil];

    /*
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didReceiveTap:)];
    [self.view addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
     */
}

- (void)viewDidUnload
{
    [_frameDelegate release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Button receivers
- (IBAction) onTransactionClick:(id)sender {
    NSNumber* price = [NSNumber numberWithDouble:.99];
    [Playnomics transactionWithUSDPrice: price quantity: 1];
}

- (IBAction) onUserInfo:(id)sender {
    [Playnomics attributeInstallToSource:@"source" withCampaign:@"campaign" onInstallDate:[NSDate date]];
}

- (IBAction) onMilestoneClick:(id)sender {
    [Playnomics milestone : PNMilestoneCustom1];
    [Playnomics milestone : PNMilestoneCustom2];
    [Playnomics milestone : PNMilestoneCustom3];
    [Playnomics milestone : PNMilestoneCustom4];
    [Playnomics milestone : PNMilestoneCustom5];
}

- (IBAction)onHttpClick:(id)sender {
    [self showPlacement:@"546e241b9b97149b"];
}

- (IBAction)onJsonClick:(id)sender {
    [self showPlacement:@"c6877f336e9d9dda"];
}

- (IBAction)onNullTargetClick:(id)sender {
    [self showPlacement:@"7a9138a971ce1773"];
}

-(IBAction)onNoAdsClick:(id)sender{
    [self showPlacement:@"15bec4e2b78424a2"];
}

-(IBAction) onThirdPartyAd:(id) sender{
    [self showPlacement:@"33a3cf0ecfa71c1a"];
}

- (IBAction) onClearCache:(id)sender{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm cache clear"
                                                    message:@"This clears the app cache, so that you'll be treated like a new user. You need to close this app and restart once this is done. Are you sure you want to do this?"
                                                   delegate:self
                                          cancelButtonTitle:@"No thanks"
                                          otherButtonTitles:@"Yes, do it!", nil];
    [alert show];
}

-(void) alertView:(UIAlertView *) alertView clickedButtonAtIndex:(NSInteger) buttonIndex{
    [alertView release];
    if(buttonIndex == 1){
        UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:@"com.playnomics.pasteboardData" create:YES];
        pasteboard.items = nil;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setValue:nil forKey: PNUserDefaultsLastIDFV];
        [defaults setValue:nil forKey: PNUserDefaultsLastSessionID];
        [defaults setValue:nil forKey: PNUserDefaultsLastUserID];
        [defaults setDouble:0 forKey: PNUserDefaultsLastSessionEventTime];
        [defaults setValue:nil forKey: PNUserDefaultsLastDeviceToken];
    }
}

- (void) showPlacement: (NSString *) placementName {
    [Playnomics showPlacementWithName:placementName delegate:_frameDelegate];
}

#pragma mark Misc Functions

- (void)dealloc {
    [super dealloc];
}

- (void)adColonyTakeoverBeganForZone:(NSString*)zone {
    NSLog(@"AdColony video ad launched for zone %@",zone);
}

- (void)adColonyTakeoverEndedForZone:(NSString*)zone withVC:(BOOL)withVirtualCurrencyAward {
    //NSLog(@"AdColony video ad finished for zone %@ and boolean %d",zone,withVirtualCurrencyAward);
    //[videoFrame sendVideoView];
}

- (void)adColonyVideoAdNotServedForZone:(NSString*)zone {
    NSLog(@"AdColonydidnotserveavideoforzone%@",zone);
}

-(void) didReceiveTap:(UITapGestureRecognizer *)sender{
    NSLog(@"The View Controller received a touch event");
}

@end
