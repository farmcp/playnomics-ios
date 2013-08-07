#import "PNConstants.h"
#import "PNEvent.h"

@interface PNUserInfoEvent : PNEvent {
    PNUserInfoType _type;
    NSString * _country;
    NSString * _subdivision;
    PNUserInfoSex _sex;
    NSTimeInterval _birthday;
    NSString * _sourceStr;
    NSString * _sourceCampaign;
    NSTimeInterval _installTime;
    NSString* _limitAdvertising;
    NSString* _idfa;
    NSString* _idfv;
}

@property(nonatomic, assign) PNUserInfoType type;
@property(nonatomic, retain) NSString * country;
@property(nonatomic, retain) NSString * subdivision;
@property(nonatomic, assign) PNUserInfoSex sex;
@property(nonatomic, assign) NSTimeInterval birthday;
@property(nonatomic, retain) NSString * sourceStr;
@property(nonatomic, retain) NSString * sourceCampaign;
@property(nonatomic, assign) NSTimeInterval installTime;
@property(nonatomic, retain) NSString* limitAdvertising;
@property(nonatomic, retain) NSString* idfa;
@property(nonatomic, retain) NSString* idfv;

- (id) initUserInfoEvent: (signed long long) applicationId
                  userId: (NSString *) userId
                cookieId: (NSString *) cookieId
                    type: (PNUserInfoType) type;

- (id) init: (signed long long) applicationId
     userId: (NSString *) userId
   cookieId: (NSString *) cookieId
       type: (PNUserInfoType) type
    country: (NSString *) country
subdivision: (NSString *) subdivision
        sex: (PNUserInfoSex) sex
   birthday: (NSTimeInterval) birthday
     source: (NSString *) source
sourceCampaign: (NSString *) sourceCampaign
installTime: (NSTimeInterval) installTime;

- (id) initWithAdvertisingInfo: (signed long long) applicationId
                        userId: (NSString *) userId
                      cookieId: (NSString *) cookieId
                          type: (PNUserInfoType) type
              limitAdvertising: (NSString *) limitAdvertising
                          idfa: (NSString *) idfa
                          idfv: (NSString *) idfv;

@end
