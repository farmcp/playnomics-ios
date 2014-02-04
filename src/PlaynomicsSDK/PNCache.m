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

@synthesize idfv;

@synthesize idfvChanged = _idfvChanged;
@synthesize deviceToken=_deviceToken;

- (void)dealloc{
    [super dealloc];
}

-(void) loadDataFromCache {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.idfv = [defaults stringForKey:PNUserDefaultsLastIDFV];
    
    NSString *lastSessionIdHex = [defaults stringForKey:PNUserDefaultsLastSessionID];
    if (lastSessionIdHex) {
        self.lastSessionId = [[[PNGeneratedHexId alloc] initWithValue: lastSessionIdHex] autorelease];
    }
    
    //try to get the user ID from NSUserDefaults, fallback to the legacy pasteboard
    //for obtaining the user ID. This is done for backwards compatibility with the old Unity SDK
    self.lastUserId = [defaults stringForKey:PNUserDefaultsLastUserID]
                ? [defaults stringForKey:PNUserDefaultsLastUserID]
                : [self getLegacyUserId];
    
    self.lastEventTime = [defaults doubleForKey:PNUserDefaultsLastSessionEventTime];
    self.deviceToken = [defaults stringForKey:PNUserDefaultsLastDeviceToken];
}

-(void) writeDataToCache {
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

- (NSString *) getIdfv {
    return self.idfv;
}

- (void) updateIdfv : (NSString *) value{
    if(value &&  !(self.idfv && [value isEqualToString: self.idfv])){
        self.idfv = value;
        _idfvChanged = TRUE;
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

- (NSString *) getLegacyUserId {
    //for previous versions of the Unity SDK
    UIPasteboard *pasteBoard = [UIPasteboard pasteboardWithName:PNUserDefaultsLastDeviceID create:NO];
    if(pasteBoard){
        NSString *storedUUID = [pasteBoard string];
        if ([storedUUID length] > 0) {
            return storedUUID;
        }
    }
    return nil;
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
