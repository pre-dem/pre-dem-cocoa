/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *         Kent Sutherland
 *
 * Copyright (c) 2012-2013 HockeyApp, Bit Stadium GmbH.
 * Copyright (c) 2011 Andreas Linde & Kent Sutherland.
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


#import <Foundation/Foundation.h>
#import "PREDLogger.h"

#ifndef PreDemObjc_PREDPrivate_h
#define PreDemObjc_PREDPrivate_h

#define PRED_NAME @"PreDemObjc"
#define PRED_IDENTIFIER @"net.hockeyapp.sdk.ios"
#define PRED_CRASH_SETTINGS @"PREDCrashManager.plist"
#define PRED_CRASH_ANALYZER @"PREDCrashManager.analyzer"

#define kPREDMetaUserName  @"PREDMetaUserName"
#define kPREDMetaUserEmail @"PREDMetaUserEmail"
#define kPREDMetaUserID    @"PREDMetaUserID"

#define PRED_BUNDLE @"PreDemObjcResources.bundle"
#define PRED_URL @"http://hriygkee.bq.cloudappl.com"

#define PRED_RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

NSBundle *PREDBundle(void);
NSString *PREDLocalizedString(NSString *stringToken);

#ifndef __IPHONE_8_0
#define __IPHONE_8_0     80000
#endif

#ifndef TARGET_OS_SIMULATOR

#ifdef TARGET_IPHONE_SIMULATOR

#define TARGET_OS_SIMULATOR TARGET_IPHONE_SIMULATOR

#else

#define TARGET_OS_SIMULATOR 0

#endif /* TARGET_IPHONE_SIMULATOR */

#endif /* TARGET_OS_SIMULATOR */

#endif /* PreDemObjc_PREDPrivate_h */
