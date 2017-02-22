//
//  PRESURLProtocol.h
//  PreSniffSDK
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESURLProtocol : NSURLProtocol

+ (void)enableHTTPSniff;
+ (void)disableHTTPSniff;

@end
