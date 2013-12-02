//
//  PNCache.m
//  iosapi
//
//  Created by Jared Jenkins on 8/26/13.
//
//

#import "PNCache.h"
#import "PNCache+Private.h"
#import <UIKit/UIKit.h>

@implementation PNCache

@synthesize idfa;
@synthesize idfv;
@synthesize limitAdvertising;

@synthesize idfaChanged = _idfaChanged;
@synthesize idfvChanged = _idfvChanged;
@synthesize limitAdvertisingChanged = _limitAdvertisingChanged;
@synthesize deviceToken=_deviceToken;

- (void)dealloc{
    [super dealloc];
}

-(void) loadDataFromCache {
    UIPasteboard *playnomicsPasteboard = [self getPlaynomicsPasteboard];
    if([[playnomicsPasteboard items] count] > 0){
        NSDictionary *data = [[playnomicsPasteboard items] objectAtIndex:0];
        self.idfa = [self deserializeStringFromData:data key:PNPasteboardLastIDFA];
        
        self.limitAdvertising = [PNUtil stringAsBool: [self deserializeStringFromData:data key:PNPasteboardLastLimitAdvertising]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.idfv = [defaults stringForKey:PNUserDefaultsLastIDFV];
    
    NSString *lastSessionIdHex = [defaults stringForKey:PNUserDefaultsLastSessionID];
    if (lastSessionIdHex) {
        self.lastSessionId = [[[PNGeneratedHexId alloc] initWithValue: lastSessionIdHex] autorelease];
    }
    
    self.lastUserId = [defaults stringForKey:PNUserDefaultsLastUserID];
    self.lastEventTime = [defaults doubleForKey:PNUserDefaultsLastSessionEventTime];
    self.deviceToken = [defaults stringForKey:PNUserDefaultsLastDeviceToken];
}

-(void) writeDataToCache {
    if(_idfaChanged || _limitAdvertisingChanged){
        UIPasteboard *playnomicsPasteboard = [self getPlaynomicsPasteboard];
        NSMutableDictionary *pasteboardData = ([[playnomicsPasteboard items] count] == 1) ?
                                    [[playnomicsPasteboard items] objectAtIndex:0] :
                                    [[NSMutableDictionary new] autorelease];

        
        [pasteboardData setValue:self.idfa forKey:PNPasteboardLastIDFA];
        [pasteboardData setValue:[PNUtil boolAsString: self.limitAdvertising] forKey: PNPasteboardLastLimitAdvertising];
        
        playnomicsPasteboard.items = [[[NSArray alloc] initWithObjects:pasteboardData, nil] autorelease];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(_idfvChanged){
        [defaults setValue:self.idfv forKey: PNUserDefaultsLastIDFV];
    }
    
    [defaults setValue:[ self.lastSessionId toHex] forKey: PNUserDefaultsLastSessionID];
    [defaults setValue: self.lastUserId forKey: PNUserDefaultsLastUserID];
    [defaults setDouble: self.lastEventTime forKey: PNUserDefaultsLastSessionEventTime];
    [defaults setValue: self.deviceToken forKey: PNUserDefaultsLastDeviceToken];
    [defaults synchronize];
}

- (UIPasteboard *) getPlaynomicsPasteboard {
    UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:PNPasteboardName create:YES];
    pasteboard.persistent = YES;
    return pasteboard;
}

- (NSString *) getIdfa{
    return self.idfa;
}

- (void) updateIdfa: (NSString *) value{
    if(!(self.idfa && [value isEqualToString:self.idfa])){
        self.idfa = value;
        _idfaChanged = TRUE;
    }
}

- (NSString *) getIdfv {
    return self.idfv;
}

- (void) updateIdfv : (NSString *) value{
    if(!(self.idfv && [value isEqualToString: self.idfv])){
        self.idfv = value;
        _idfvChanged = TRUE;
    }
}

- (BOOL) getLimitAdvertising{
    return self.limitAdvertising;
}

- (void) updateLimitAdvertising : (BOOL) value{
    if(self.limitAdvertising != value){
        self.limitAdvertising = value;
        _limitAdvertisingChanged = TRUE;
    }
}

- (PNGeneratedHexId *) getLastSessionId{
    return self.lastSessionId;
}

- (void) updateLastSessionId: (PNGeneratedHexId *) value{
    if(self.lastSessionId != value){
        self.lastSessionId = value;
    }
}

- (NSString *) getLastUserId{
    return self.lastUserId;
}

- (void) updateLastUserId: (NSString *) value{
    if(!(self.lastUserId && [value isEqualToString:self.lastUserId])){
        self.lastUserId = value;
    }
}

- (NSTimeInterval) getLastEventTime{
    return self.lastEventTime;
}

- (void) updateLastEventTimeToNow {
    self.lastEventTime = [[NSDate date] timeIntervalSince1970];
}

- (NSString *) getDeviceToken{
    return self.deviceToken;
}

- (void) updateDeviceToken: (NSString *) value{
    self.deviceToken = value;
}

- (NSString *) deserializeStringFromData : (NSDictionary*) dict key:(NSString*) key{
    return [[[NSString alloc] initWithData:[dict valueForKey:key] encoding: NSUTF8StringEncoding] autorelease];
}
@end
