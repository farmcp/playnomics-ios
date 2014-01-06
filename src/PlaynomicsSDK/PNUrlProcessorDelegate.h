//
//  PNUrlProcessorDelegate.h
//  iosapi
//
//  Created by Jared Jenkins on 9/3/13.
//
//

#import <Foundation/Foundation.h>

@protocol PNUrlProcessorDelegate <NSObject>
-(void) onDidProcessUrl: (NSString *) url;
-(void) onDidFailToProcessUrl: (NSString *) url tryAgain:(BOOL) tryAgain;
-(void) onConnectionUnavailable;
@end
