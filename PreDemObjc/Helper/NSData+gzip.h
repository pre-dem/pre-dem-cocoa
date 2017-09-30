//
//  PREDGZIP.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (gzip)

- (NSData *)gzippedDataWithCompressionLevel:(float)level;
- (NSData *)gzippedData;
- (NSData *)gunzippedData;

@end

NS_ASSUME_NONNULL_END
