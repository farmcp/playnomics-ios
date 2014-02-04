//
//  MockPNCache.m
//  iosapi
//
//  Created by Jared Jenkins on 8/27/13.
//
//

#import "StubPNCache.h"
#import "PNCache.h"
#import "PNCache+Private.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OCMock.h"
#import "OCMockObject.h"
#import "OCMArg.h"

@implementation StubPNCache{
    NSString *_initIdfv;
    
    NSTimeInterval _initLastEventTime;
    PNGeneratedHexId *_initLastSessionId;
    NSString *_initLastUserId;
    
    NSString* _initDeviceToken;
    //these values exist in the PNCache class
    id _mock;
    PNCache *_cache;
}

-(id) initWithIdfv: (NSString *) idfv {
  
    if((self = [super init])){
        _cache = [[PNCache alloc] init];
        
        _initIdfv = idfv;
        
        _initLastEventTime = 0;
    }
    return self;
}

-(id) initWithIdfv: (NSString *) idfv
     lastEventTime: (NSTimeInterval) lastEventTime
        lastUserId: (NSString *)lastUserId
     lastSessionId: (PNGeneratedHexId *) sessionId {
    if((self = [super init])){
        _cache = [[PNCache alloc] init];
        
        _initIdfv = idfv;
        _initLastEventTime = lastEventTime;
        _initLastSessionId = sessionId;
        _initLastUserId = lastUserId;
    }
    return self;
}

-(id) initWithIdfv: (NSString *) idfv
       deviceToken:(StubDeviceToken *) token {
    
    if((self = [super init])){
        _cache = [[PNCache alloc] init];
        
        _initIdfv = idfv;
        _initDeviceToken = [token cleanToken];
        _initLastEventTime = 0;
    }
    return self;
}


-(void) dealloc {
    [_mock stopMocking];
    [_cache release];
    [super dealloc];
}

-(void) loadDataFromCache{
    //mock out the calls for actually loading the data
    _cache.idfv = _initIdfv;
    _cache.deviceToken = _initDeviceToken;

    if(_initLastEventTime){
        _cache.lastEventTime = _initLastEventTime;
    }
    if(_initLastUserId){
        _cache.lastUserId = _initLastUserId;
    }
    if(_initLastSessionId){
        _cache.lastSessionId = _initLastSessionId;
    }
}

-(void) writeDataToCache{
    //this does nothing
}

-(id) getMockCache{
    if(!_mock){
        _mock = [OCMockObject partialMockForObject:_cache];
        //stubs out the IO related calls for testing
        [[[_mock stub] andCall:@selector(loadDataFromCache) onObject:self] loadDataFromCache];
        [[[_mock stub] andCall:@selector(writeDataToCache) onObject:self] writeDataToCache];
    }
    return _mock;
}
@end
