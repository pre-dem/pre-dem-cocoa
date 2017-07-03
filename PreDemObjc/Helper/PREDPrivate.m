/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
 * Copyright (c) 2011 Andreas Linde.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPREDS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PreDemObjc.h"
#import "PREDPrivate.h"
#include <CommonCrypto/CommonDigest.h>

NSString *const kPREDCrashErrorDomain = @"PREDCrashReporterErrorDomain";
NSString *const kPREDUpdateErrorDomain = @"PREDUpdaterErrorDomain";
NSString *const kPREDFeedbackErrorDomain = @"PREDFeedbackErrorDomain";
NSString *const kPREDErrorDomain = @"PREDErrorDomain";
NSString *const kPREDAuthenticatorErrorDomain = @"PREDAuthenticatorErrorDomain";

// Load the framework bundle.
NSBundle *PREDBundle(void) {
    static NSBundle *bundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle bundleForClass:[PREDManager class]] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:PRED_BUNDLE];
        bundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return bundle;
}

NSString *PREDLocalizedString(NSString *stringToken) {
    if (!stringToken) return @"";
    
    NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
    if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
        return appSpecificLocalizationString;
    } else if (PREDBundle()) {
        NSString *bundleSpecificLocalizationString = NSLocalizedStringFromTableInBundle(stringToken, @"PreDemObjc", PREDBundle(), @"");
        if (bundleSpecificLocalizationString)
            return bundleSpecificLocalizationString;
        return stringToken;
    } else {
        return stringToken;
    }
}
