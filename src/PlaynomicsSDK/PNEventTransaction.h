#import "PNExplicitEvent.h"

typedef enum {
    PNCurrencyCategoryReal,
    PNCurrencyCategoryVirtual
} PNCurrencyCategory;

typedef enum {
    PNTransactionBuyItem,
    PNTransactionSellItem,
    PNTransactionReturnItem,
    PNTransactionBuyService,
    PNTransactionSellService,
    PNTransactionReturnService,
    PNTransactionCurrencyConvert,
    PNTransactionInitial,
    PNTransactionFree,
    PNTransactionReward,
    PNTransactionGiftSend,
    PNTransactionGiftReceive
} PNTransactionType;

typedef enum {
    PNCurrencyUSD,
    PNCurrencyFBC,
    PNCurrencyOFD,
    PNCurrencyOFF
} PNCurrencyType;

@interface PNEventTransaction : PNExplicitEvent

- (id) initWithSessionInfo: (PNGameSessionInfo *)info itemId: (NSString*) itemId quantity: (int) quantity type: (PNTransactionType) type currencyTypes: (NSArray*) currencyTypes currencyValues: (NSArray*) currencyValues currencyCategories: (NSArray*) currencyCategories;
- (NSString *) baseUrlPath;

@end
