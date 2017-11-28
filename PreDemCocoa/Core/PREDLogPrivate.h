//
//  PREDLogger_private.h
//  Pods
//
//  Created by 王思宇 on 30/08/2017.
//
//

#ifndef PREDLogger_private_h
#define PREDLogger_private_h

#import "PREDLog.h"
#import "PREDLogFileManager.h"
#import "PREDLogFormatter.h"
#import "PREDPersistence.h"

@interface PREDLog (Private)
<
PREDLogFileManagerDelegate,
PREDLogFormatterDelegate
>

@property (class, nonatomic, strong) PREDPersistence *persistence;

@end

#endif /* PREDLogger_private_h */
