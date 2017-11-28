//
//  NSObject+Serialization.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "NSObject+Serialization.h"
#import <objc/runtime.h>
#import "PREDError.h"

@implementation NSObject (Serialization)

- (NSData *)toJsonWithError:(NSError **)error {
    
    NSDictionary *dic;
    if([self isKindOfClass:[NSDictionary class]]) {
        dic = (NSDictionary *)self;
    } else {
        dic = [self toDic];
    }
    NSData *data;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:error];
    } @catch (NSException *exception) {
        *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidJsonObject description:exception.reason];
    } @finally {
        return data;
    }
}

- (NSMutableDictionary *)toDic {
    Class class = self.class;
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    while (class != NSObject.class) {
        [dic addEntriesFromDictionary:[self toDicForClass:class]];
        class = class_getSuperclass(class);
    }
    return dic;
}

- (NSMutableDictionary *)toDicForClass:(Class)class {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    
    objc_property_t *props = class_copyPropertyList(class, &propsCount);
    
    for(int i = 0;i < propsCount; i++) {
        
        objc_property_t prop = props[i];
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        id value = [self valueForKey:propName];
        if(value != nil) {
            value = [self getObjectInternal:value];
            [dic setObject:value forKey:propName];
        }
    }
    
    if (props) {
        free(props);
    }
    return dic;
}

- (id)getObjectInternal:(id)obj {
    
    if([obj isKindOfClass:[NSString class]]
       ||
       [obj isKindOfClass:[NSNumber class]]
       ||
       [obj isKindOfClass:[NSNull class]]) {
        
        return obj;
        
    }
    if([obj isKindOfClass:[NSArray class]]) {
        
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        
        for(int i = 0; i < objarr.count; i++) {
            
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    if([obj isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        
        for(NSString *key in objdic.allKeys) {
            
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self toDic];
}

@end
