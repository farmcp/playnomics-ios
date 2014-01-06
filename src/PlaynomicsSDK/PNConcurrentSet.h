//
//  PNConcurrentSet.h
//  iosapi
//
//  Created by Jared Jenkins on 9/3/13.
//
//

#import <Foundation/Foundation.h>
@interface PNConcurrentSet : NSObject
-(void) addObject: (id) obj;
-(void) removeObject: (id) obj;
-(BOOL) containsObject: (id) obj;
-(NSUInteger) count;
-(NSSet *) copyOfData;
@end
