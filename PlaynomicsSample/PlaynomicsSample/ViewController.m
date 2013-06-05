
//
//  ViewController.m
//  PlaynomicsSample
//
//  Created by Martin Harkins on 6/27/12.
//  Copyright (c) 2012 Grio. All rights reserved.
//

#import "ViewController.h"
#import "PlaynomicsSession.h"

@implementation ViewController
@synthesize transactionCount;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Grab the shared (singleton) instance of the messaging class
    PlaynomicsMessaging *messaging = [PlaynomicsMessaging sharedInstance];
    
    // Register an action handler bound to the provided label.  You can set as many handlers as you want, as long
    //   they are registered with unique names
    [messaging registerActionHandler:self withLabel:@"test_action"];
    
    // Set the delegate that execution targets will be called against.
    messaging.delegate = self;
    _frameIdText.delegate = self;
}

- (void)viewDidUnload
{
    [self setFrameIdText:nil];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_frameIdText resignFirstResponder];
    
    return YES;
}

#pragma mark - Button receivers


- (IBAction) onGameStartClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession gameStartWithInstanceId:1234567890 sessionId:666 site:@"TEST_SITE" type:@"TEST_TYPE" gameId:@"TEST_GAMEID"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onGameEndClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession gameEndWithInstanceId:1234567890 sessionId:666 reason:@"TEST_REASON"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onSendInvitationClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession invitationSentWithId:98765432210 recipientUserId:@"TEST_RECIPIENTID" recipientAddress:@"TEST_RECIPIENT_ADDRESS" method:@"TEST_METHOD"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onRespondToInvitationClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession invitationResponseWithId:98765432210 recipientUserId:@"TEST_RECIPIENTID" responseType:PNResponseTypeAccepted];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onTransactionClick:(id)sender {
    [self.view endEditing:YES];
    
    NSInteger count = 1;
    if ([transactionCount.text length] > 0) {
        count = MIN(100, [transactionCount.text integerValue]);
    }
    
    PNAPIResult resval;
    if (count > 0) {
        NSMutableArray *tStack = [NSMutableArray array];
        NSMutableArray *vStack = [NSMutableArray array];
        NSMutableArray *cStack = [NSMutableArray array];
        for (int j = 0; j < count; j++) {
            [tStack addObject:[NSNumber numberWithInt:(arc4random() % 4)]];
            [vStack addObject:[NSNumber numberWithDouble:(arc4random() % 10000) / 10]];
            [cStack addObject:[NSNumber numberWithInt:(arc4random() % 2)]];
        }
        
        resval = [PlaynomicsSession transactionWithId:(arc4random() & NSUIntegerMax) 
                                      //itemId:@"TEST_ITEM_ID"
                                               itemId: @"Test Item Id"
                                             quantity:(arc4random() % 100)
                                                type:(arc4random() % 12)
                  otherUserId:nil
                               currencyTypes:tStack 
                              currencyValues:vStack 
                          currencyCategories:cStack
                  ];
    }
    else {
        resval = [PlaynomicsSession transactionWithId:(arc4random() & NSUIntegerMax)
                  //itemId:@"TEST_ITEM_ID"
                                               itemId: @"Test Item Id"
                                             quantity:0
                                                 type:(arc4random() % 12)
                                          otherUserId:nil
                                         currencyType:(arc4random() % 4)
                                        currencyValue:((arc4random() % 10000) / 10)
                                     currencyCategory:(arc4random() % 2)];
    }
    [self handlePLAPIRResult:resval];
}

- (IBAction) onSessionStartClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession sessionStartWithId:5678901234 site:@"TEST_SITE"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onSessionEndClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession sessionEndWithId:5678901234 reason:@"TEST_REASON"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onUserInfoClick:(id)sender {
    PNAPIResult resval = [PlaynomicsSession userInfoForType:PNUserInfoTypeUpdate
                                                    country:@"TEST_COUNTRY"
                                                subdivision:@"TEST_SUBDIVISION"
                                                        sex:(arc4random() % 3)
                                                   birthday:[NSDate date]
                                                     source:(arc4random() % 17)
                                             sourceCampaign:@"TEST_SRC_CAMPAIGN"
                                                installTime:[[NSDate date] dateByAddingTimeInterval:(- (double)(arc4random() % 1000000))]];
    [self handlePLAPIRResult:resval];
    
}

- (IBAction)onChangeUserClick:(id)sender {
    
    PNAPIResult resval = [PlaynomicsSession changeUserWithUserId: @"testChangeUserId"];
    [self handlePLAPIRResult:resval];
}

- (IBAction) onMilestoneClick:(id)sender {
    
    PNAPIResult resval = [PlaynomicsSession milestoneWithId:4L
                                                    andName:@"testMilestone"];
    [self handlePLAPIRResult:resval];
}

- (IBAction)onMessageTLClick:(id)sender {
    [self initMsgFrame:@"testTL"];
}
- (IBAction)onMessageCCClick:(id)sender {
    [self initMsgFrame:@"testCC"];    
}
- (IBAction)onMessageBRClick:(id)sender {
    [self initMsgFrame:@"testBR"];    
}
- (IBAction)onMessageNoCloseClick:(id)sender {
    [self initMsgFrame:@"testNoClose"];   
}
- (IBAction)onMessageMessOnlyClick:(id)sender {
    [self initMsgFrame:@"testMessOnly"];  
}

- (IBAction)onMessageGenericClick:(id)sender {
    [self initMsgFrame:_frameIdText.text];
}


- (void) initMsgFrame: (NSString *) frameId {
    // Retrieve the ad frame you need using the provided Frame ID and start it.  Once all of the assets are loaded
    //   the frame will display itself.
    PlaynomicsMessaging *messaging = [PlaynomicsMessaging sharedInstance];
    
    
    //FIXME: this needs to be on another thread
    PlaynomicsFrame *frame = [messaging initFrameWithId:frameId];
    DisplayResult result = [frame start];
    if (result==DisplayResultFailUnknown) {
       
    }else
        NSLog(@"Result of calling start: %i", result);

}

-(void)onpnx
{
        [[[[UIAlertView alloc] initWithTitle:@"pnx success!" message:@"i am the call back from pnx" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] autorelease]show];
}

#pragma mark Misc Functions
- (void)performActionOnAdClicked {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Action"
                                                    message:@"You're performing a test ACTION."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)someRandomExecution {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Execution"
                                                    message:@"You're performing a test EXECUTION."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    // @throw [NSException exceptionWithName:@"Test Exception" reason:@"Oopps...I was a bad boy" userInfo:nil];
}

- (void) handlePLAPIRResult: (PNAPIResult) result {
    if (result == PNAPIResultSent) {
        [[[[UIAlertView alloc] initWithTitle:@"Result" message:@"Event Sent !" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease] show];
    }
    else {
        [[[[UIAlertView alloc] initWithTitle:@"Result" message:@"Event NOT Sent !" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil]autorelease] show];
    }
}
- (void)dealloc {
    [_frameIdText release];
    [super dealloc];
}
@end
