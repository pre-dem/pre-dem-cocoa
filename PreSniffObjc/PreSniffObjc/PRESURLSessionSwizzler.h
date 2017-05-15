//
//  PRESURLSessionSwizzler.h
//  PreSniffSDK
//
//  Created by WangSiyu on 14/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESURLSessionSwizzler : NSObject

@property (nonatomic, assign) BOOL isSwizzle;

+ (PRESURLSessionSwizzler *)defaultSwizzler;
- (void)load;
- (void)unload;

@end
