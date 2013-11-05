#import "PNEventTransaction.h"
#import "PNUtil.h"

@implementation PNEventTransaction
- (id) initWithSessionInfo: (PNGameSessionInfo *)info itemId: (NSString*) itemId quantity: (int) quantity type: (PNTransactionType) type currencyTypes: (NSArray*) currencyTypes currencyValues: (NSArray*) currencyValues currencyCategories: (NSArray*) currencyCategories {
    
    if ((self = [super initWithSessionInfo: info])) {
        unsigned long long transactionId = [PNUtil generateRandomLongLong];
        
        [self appendParameter:[NSNumber numberWithUnsignedLongLong : transactionId] forKey:PNEventParameterTransactionId];
        [self appendParameter:itemId forKey:PNEventParameterTransactionItemId];
        [self appendParameter:[self PNTransactionTypeDescription: type] forKey:PNEventParameterTransactionType];
        [self appendParameter:[NSNumber numberWithInt:quantity] forKey:PNEventParameterTransactionQuantity];
    
        for(int i = 0; i < [currencyTypes count]; i ++){
            id obj = [currencyTypes objectAtIndex:i];
            
            
            NSString *currentTypeStr = nil;
            if ([obj isKindOfClass:[NSNumber class]]) {
                currentTypeStr = [self PNCurrencyTypeDescription: [(NSNumber *)obj intValue]];
            }
            else if ([obj isKindOfClass:[NSString class]]) {
                currentTypeStr = (NSString *) obj;
            }
            
            if(currentTypeStr) {
                
                NSNumber *currencyValue = (NSNumber *)[currencyValues objectAtIndex:i];
                NSNumber *currencyType = (NSNumber *)[currencyCategories objectAtIndex:i];
                
                NSString* currencyCategoryStr = [self PNCurrencyCategoryDescription: [currencyType intValue]];
                
                [self appendParameter:currencyValue forKey: [NSString stringWithFormat: PNEventParameterTransactionCurrencyValueFormat, i]];
                [self appendParameter:currencyCategoryStr forKey: [NSString stringWithFormat: PNEventParameterTransactionCurrencyCategoryFormat, i]];
                [self appendParameter:currentTypeStr forKey: [NSString stringWithFormat: PNEventParameterTransactionCurrencyTypeFormat, i]];
            }
        }
    }
    return self;
}

- (NSString *) baseUrlPath{
    return @"transaction";
}

- (NSString *) PNTransactionTypeDescription:(PNTransactionType) value {
    switch (value) {
        case PNTransactionBuyItem:
            return @"BuyItem";
        case PNTransactionSellItem:
            return @"SellItem";
        case PNTransactionReturnItem:
            return @"ReturnItem";
        case PNTransactionBuyService:
            return @"BuyService";
        case PNTransactionSellService:
            return @"SellService";
        case PNTransactionReturnService:
            return @"ReturnService";
        case PNTransactionCurrencyConvert:
            return @"CurrencyConvert";
        case PNTransactionInitial:
            return @"Initial";
        case PNTransactionFree:
            return @"Free";
        case PNTransactionReward:
            return @"Reward";
        case PNTransactionGiftSend:
            return @"GiftSend";
        case PNTransactionGiftReceive:
            return @"GiftReceive";
    }
    return nil;
}


- (NSString *) PNCurrencyCategoryDescription:(PNCurrencyCategory) value {
    switch (value) {
        case PNCurrencyCategoryReal:
            return @"r";
        case PNCurrencyCategoryVirtual:
            return @"v";
    }
    return nil;
}


- (NSString *) PNCurrencyTypeDescription:(PNCurrencyType) value {
    switch (value) {
        case PNCurrencyUSD:
            return @"USD";
        case PNCurrencyFBC:
            return @"FBC";
        case PNCurrencyOFD:
            return @"OFD";
        case PNCurrencyOFF:
            return @"OFF";
    }
    return nil;
}
@end
