//
//  PNConcurrentSet.m
//  iosapi
//
//  Created by Jared Jenkins on 9/3/13.
//
//

#import "PNConcurrentSet.h"

@implementation PNConcurrentSet{
    NSMutableSet *_set;
    NSObject *_syncLock;
}

-(id) init{
    if((self = [super init])){
        _set = [[NSMutableSet alloc] init];
        _syncLock = [[NSObject alloc] init];
    }
    return self;
}

-(void) dealloc{
    [_set release];
    [super dealloc];
}

-(void) addObject: (id) obj{
    @synchronized(_syncLock){
        [_set addObject:obj];
    }
}

-(void) removeObject: (id) obj{
    @synchronized(_syncLock){
        [_set removeObject:obj];
    }
}

-(BOOL) containsObject : (NSObject *) obj{
    @synchronized(_syncLock){
        return [_set containsObject:obj];
    }
}

-(NSSet *) copyOfData{
    @synchronized(_syncLock){
        NSSet* setCopy = [[NSSet alloc] initWithSet:_set copyItems:YES];
        return setCopy;
    }
}

-(NSUInteger) count{
    @synchronized(_syncLock){
        return [_set count];
    }
}
@end
