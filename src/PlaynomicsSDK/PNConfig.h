//
//  PNConfig.h
//  iosapi
//
//  Created by Martin Harkins on 6/25/12.
//  Copyright (c) 2012 Grio. All rights reserved.
//

#ifndef iosapi_PNConfig_h
#define iosapi_PNConfig_h

#define PNSettingCollectionMode (int) 8;

#define PNFileEventArchive [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent: @"PlayRMEvents.archive"]
// Playnomics server urls
#define PNPropertyBaseTestUrl @"https://e.b.playnomics.net/v1/"
#define PNPropertyBaseProdUrl @"https://e.a.playnomics.net/v1/"
//TODO: get correct urls
#define PNPropertyMessagingTestUrl @"https://ads.b.playnomics.net/v2/"
#define PNPropertyMessagingProdUrl @"https://ads.a.playnomics.net/v2/"

#define PNPropertyVersion @"1.4.0"
// Connection timeout in seconds
#define PNPropertyConnectionTimeout 60

#ifdef DEBUG

#define PNUpdateTimeInterval (NSTimeInterval) 60
#define PNSessionTimeout (NSTimeInterval) 180

#else

#define PNUpdateTimeInterval (NSTimeInterval) 60
#define PNSessionTimeout (NSTimeInterval) 180
// DEBUG
#endif
// iosapi_PNConfig_h
#endif
