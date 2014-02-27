//
//  PNLogger.h
//
//  Created by Jared Jenkins
//  Version 1.5.2
//

#import <UIKit/UIKit.h>

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif
typedef NS_ENUM(int, PNLoggingLevel){
    PNLogLevelVerbose   = 0,
    PNLogLevelDebug     = 1,
    PNLogLevelWarning   = 2,
    PNLogLevelError     = 3,
    PNLogLevelNone      = 4
};

@interface PNLogger : NSObject
+(void) setLoggingLevel: (PNLoggingLevel) level;

+(void) log: (PNLoggingLevel) level
     format: (NSString *) format, ...;

+(void) log: (PNLoggingLevel) level
  exception: (NSException *) exception;

+(void) log: (PNLoggingLevel) level
  exception: (NSException *) exception
     format: (NSString *) format, ...;

+(void) log: (PNLoggingLevel) level
      error: (NSError *) exception;

+(void) log: (PNLoggingLevel) level
      error: (NSError *) error
     format: (NSString *) format, ...;
@end
