//
//  main.m
//  Cocoas2dxSample
//
//  Created by Jared Jenkins on 8/14/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaynomicsSession.h"

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, NSStringFromClass([PNApplication class]), @"AppController");
    [pool release];
    return retVal;
}
