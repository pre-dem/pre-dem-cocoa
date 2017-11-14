//
//  PREDBreadcrumbTracker.m
//  PRED
//
//  Created by Daniel Griesser on 31/05/2017.
//  Copyright © 2017 PRED. All rights reserved.
//

#import "PREDSwizzle.h"
#import "PREDBreadcrumbTracker.h"
#import "PREDBreadCrumb.h"
#import <UIKit/UIKit.h>


@implementation PREDBreadcrumbTracker {
    PREDPersistence *_persistence;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence {
    if (self = [self init]) {
        _persistence = persistence;
    }
    return self;
}

- (void)start {
    [self addEnabledCrumb];
    [self swizzleSendAction];
    [self swizzleViewDidAppear];
}

- (void)addEnabledCrumb {
    PREDBreadcrumb *breadcrumb = [PREDBreadcrumb breadcrumbWithName:@"started" contentDic:nil];
    [_persistence persistCustomEvent:breadcrumb];
}

- (void)swizzleSendAction {
    static const void *swizzleSendActionKey = &swizzleSendActionKey;
    //    - (BOOL)sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent *)event;
    SEL selector = NSSelectorFromString(@"sendAction:to:from:forEvent:");
    PREDSwizzleInstanceMethod(UIApplication.class,
                              selector,
                              PREDSWReturnType(BOOL),
                              PREDSWArguments(SEL action, id target, id sender, UIEvent * event),
                              PREDSWReplacement({
        NSMutableDictionary *data = [NSMutableDictionary new];
        for (UITouch *touch in event.allTouches) {
            if (touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded) {
                data = [@{@"view": [NSString stringWithFormat:@"%@", touch.view]} mutableCopy];
            }
        }
        
        [data setObject:[NSString stringWithFormat:@"%s", sel_getName(action)] forKey:@"action_name"];
        PREDBreadcrumb *breadcrumb = [PREDBreadcrumb breadcrumbWithName:@"touch" contentDic:data];
        [_persistence persistCustomEvent:breadcrumb];
        return PREDSWCallOriginal(action, target, sender, event);
    }), PREDSwizzleModeOncePerClassAndSuperclasses, swizzleSendActionKey);
}

- (void)swizzleViewDidAppear {
    static const void *swizzleViewDidAppearKey = &swizzleViewDidAppearKey;
    // -(void)viewDidAppear:(BOOL)animated
    SEL selector = NSSelectorFromString(@"viewDidAppear:");
    PREDSwizzleInstanceMethod(UIViewController.class,
                              selector,
                              PREDSWReturnType(void),
                              PREDSWArguments(BOOL animated),
                              PREDSWReplacement({
        NSMutableDictionary *data = [@{
                                      @"controller": [NSString stringWithFormat:@"%@", self],
                                      @"method": @"viewDidAppear",
                                      } mutableCopy];
        PREDBreadcrumb *breadcrumb = [PREDBreadcrumb breadcrumbWithName:@"UIViewController" contentDic:data];
        [_persistence persistCustomEvent:breadcrumb];
        PREDSWCallOriginal(animated);
    }), PREDSwizzleModeOncePerClassAndSuperclasses, swizzleViewDidAppearKey);
}

@end
