#import "PNEventUserInfo.h"
@implementation PNEventUserInfo


- (id) initWithSessionInfo:(PNGameSessionInfo *)info
                 pushToken:(NSString *) pushToken{
    if((self = [super initWithSessionInfo: info])){
        [self appendParameter:pushToken forKey:PNEventParameterUserInfoPushToken];
        [self appendParameter:@"update" forKey:PNEventParameterUserInfoType];
    }
    return self;
}

- (id) initWithSessionInfo:(PNGameSessionInfo *)info
          limitAdvertising: (BOOL) limitAdvertising {
    if((self = [super initWithSessionInfo: info])){
        
        [self appendParameter:[PNUtil boolAsString:limitAdvertising] forKey:PNEventParameterUserInfoLimitAdvertising];
        [self appendParameter:@"update" forKey:PNEventParameterUserInfoType];
    }
    return self;
}


-(id) initWithSessionInfo:(PNGameSessionInfo *)info
                   source:(NSString *) source
                 campaign:(NSString *) campaign
              installDate:(NSDate *) installDate{
    if((self = [super initWithSessionInfo: info])){

        [self appendParameter:source forKey:PNEventParameterUserInfoSource];
        [self appendParameter:campaign forKey:PNEventParameterUserInfoCampaign];
        if(installDate){
            NSTimeInterval unixTime = [installDate timeIntervalSince1970];
            NSNumber* unixTimeNum = [NSNumber numberWithInt: unixTime];
            [self appendParameter:unixTimeNum forKey:PNEventParameterUserInfoInstallDate];
        }
        
        [self appendParameter:@"update" forKey:PNEventParameterUserInfoType];
    }
    return self;
}

-(NSString *) baseUrlPath{
    return @"userInfo";
}

@end
