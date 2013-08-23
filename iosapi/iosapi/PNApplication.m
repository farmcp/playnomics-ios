//
//  PNApplication.m
//  iosapi
//
//  Created by Martin Harkins on 6/27/12.
//  Copyright (c) 2012 Grio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Playnomics.h"

@implementation PNApplication
- (void) sendEvent: (UIEvent *) event {
    [super sendEvent:event];
    if (event.type == UIEventTypeTouches) {
        UITouch *touch = [event allTouches].anyObject;
        if (touch.phase == UITouchPhaseBegan) {
            [Playnomics onTouchDown: event];
        }
    }
}
@end
