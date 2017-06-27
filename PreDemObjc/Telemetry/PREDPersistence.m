#import "PreDemObjc.h"
#import "PREDPersistence.h"
#import "PREDPersistencePrivate.h"
#import "PREDPrivate.h"
#import "PREDHelper.h"

NSString *const PREDPersistenceSuccessNotification = @"PREDPersistenceSuccessNotification";

static NSString *const kPREDTelemetry = @"Telemetry";
static NSString *const kPREDMetaData = @"MetaData";
static NSString *const kPREDFileBaseString = @"hockey-app-bundle-";
static NSString *const kPREDFileBaseStringMeta = @"metadata";

static NSString *const kPREDDirectory = @"com.microsoft.PreDem";
static NSString *const kPREDTelemetryDirectory = @"Telemetry";
static NSString *const kPREDMetaDataDirectory = @"MetaData";

static char const *kPREDPersistenceQueueString = "com.microsoft.PreDem.persistenceQueue";
static NSUInteger const PREDDefaultFileCount = 50;

@implementation PREDPersistence {
    BOOL _directorySetupComplete;
}

#pragma mark - Public

- (instancetype)init {
    self = [super init];
    if (self) {
        _persistenceQueue = dispatch_queue_create(kPREDPersistenceQueueString, DISPATCH_QUEUE_SERIAL); //TODO several queues?
        _requestedBundlePaths = [NSMutableArray new];
        _maxFileCount = PREDDefaultFileCount;
        
        // Evantually, there will be old files on disk, the flag will be updated before the first event gets created
        _directorySetupComplete = NO; //will be set to true in createDirectoryStructureIfNeeded
        
        [self createDirectoryStructureIfNeeded];
    }
    return self;
}

/**
 * Saves the Bundle using NSKeyedArchiver and NSData's writeToFile:atomically
 * Sends out a PREDPersistenceSuccessNotification in case of success
 */
- (void)persistBundle:(NSData *)bundle {
    //TODO send out a fail notification?
    NSString *fileURL = [self fileURLForType:PREDPersistenceTypeTelemetry];
    
    if (bundle) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.persistenceQueue, ^{
            typeof(self) strongSelf = weakSelf;
            BOOL success = [bundle writeToFile:fileURL atomically:YES];
            if (success) {
                PREDLogDebug(@"Wrote bundle to %@", fileURL);
                [strongSelf sendBundleSavedNotification];
            }
            else {
                PREDLogError(@"Error writing bundle to %@", fileURL);
            }
        });
    }
    else {
        PREDLogWarning(@"WARNING: Unable to write %@ as provided bundle was null", fileURL);
    }
}

- (void)persistMetaData:(NSDictionary *)metaData {
    NSString *fileURL = [self fileURLForType:PREDPersistenceTypeMetaData];
    //TODO send out a notification, too?!
    dispatch_async(self.persistenceQueue, ^{
        [NSKeyedArchiver archiveRootObject:metaData toFile:fileURL];
    });
}

- (BOOL)isFreeSpaceAvailable {
    NSArray *files = [self persistedFilesForType:PREDPersistenceTypeTelemetry];
    return files.count < _maxFileCount;
}

- (NSString *)requestNextFilePath {
    __block NSString *path = nil;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.persistenceQueue, ^() {
        typeof(self) strongSelf = weakSelf;
        
        path = [strongSelf nextURLOfType:PREDPersistenceTypeTelemetry];
        
        if (path) {
            [self.requestedBundlePaths addObject:path];
        }
    });
    return path;
}

- (NSDictionary *)metaData {
    NSString *filePath = [self fileURLForType:PREDPersistenceTypeMetaData];
    NSObject *bundle = [self bundleAtFilePath:filePath withFileBaseString:kPREDFileBaseStringMeta];
    if ([bundle isKindOfClass:NSDictionary.class]) {
        return (NSDictionary *) bundle;
    }
    PREDLogDebug(@"The context meta data file could not be loaded.");
    return [NSDictionary dictionary];
}

- (NSObject *)bundleAtFilePath:(NSString *)filePath withFileBaseString:(NSString *)filebaseString {
    id bundle = nil;
    if (filePath && [filePath rangeOfString:filebaseString].location != NSNotFound) {
        bundle = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    return bundle;
}

- (NSData *)dataAtFilePath:(NSString *)path {
    NSData *data = nil;
    if (path && [path rangeOfString:kPREDFileBaseString].location != NSNotFound) {
        data = [NSData dataWithContentsOfFile:path];
    }
    return data;
}

/**
 * Deletes a file at the given path.
 *
 * @param path to look for a file and delete it.
 */
- (void)deleteFileAtPath:(NSString *)path {
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.persistenceQueue, ^() {
        typeof(self) strongSelf = weakSelf;
        if ([path rangeOfString:kPREDFileBaseString].location != NSNotFound) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                PREDLogError(@"Error deleting file at path %@", path);
            }
            else {
                PREDLogDebug(@"Successfully deleted file at path %@", path);
                [strongSelf.requestedBundlePaths removeObject:path];
            }
        } else {
            PREDLogDebug(@"Empty path, nothing to delete");
        }
    });
    
}

- (void)giveBackRequestedFilePath:(NSString *)filePath {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.persistenceQueue, ^() {
        typeof(self) strongSelf = weakSelf;
        
        [strongSelf.requestedBundlePaths removeObject:filePath];
    });
}

#pragma mark - Private

- (nullable NSString *)fileURLForType:(PREDPersistenceType)type {
    
    NSString *fileName = nil;
    NSString *filePath;
    
    switch (type) {
        case PREDPersistenceTypeMetaData: {
            fileName = kPREDFileBaseStringMeta;
            filePath = [self.appPreDemSDKDirectoryPath stringByAppendingPathComponent:kPREDMetaDataDirectory];
            break;
        };
        default: {
            NSString *uuid = pres_UUID();
            fileName = [NSString stringWithFormat:@"%@%@", kPREDFileBaseString, uuid];
            filePath = [self.appPreDemSDKDirectoryPath stringByAppendingPathComponent:kPREDTelemetryDirectory];
            break;
        };
    }
    
    filePath = [filePath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

/**
 * Create directory structure if necessary and exclude it from iCloud backup
 */
- (void)createDirectoryStructureIfNeeded {
    // Using the local variable looks unnecessary but it actually silences a static analyzer warning.
    NSString *appPreDemSDKDirectoryPath = [self appPreDemSDKDirectoryPath];
    NSURL *appURL = [NSURL fileURLWithPath:appPreDemSDKDirectoryPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (appURL) {
        NSError *error = nil;
        
        // Create PreDemSDK folder if needed
        if (![fileManager createDirectoryAtURL:appURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PREDLogError(@"%@", error.localizedDescription);
            return;
        }
        
        // Create metadata subfolder
        NSURL *metaDataURL = [appURL URLByAppendingPathComponent:kPREDMetaDataDirectory];
        if (![fileManager createDirectoryAtURL:metaDataURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PREDLogError(@"%@", error.localizedDescription);
            return;
        }
        
        // Create telemetry subfolder
        
        //NOTE: createDirectoryAtURL:withIntermediateDirectories:attributes:error
        //will return YES if the directory already exists and won't override anything.
        //No need to check if the directory already exists.
        NSURL *telemetryURL = [appURL URLByAppendingPathComponent:kPREDTelemetryDirectory];
        if (![fileManager createDirectoryAtURL:telemetryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PREDLogError(@"%@", error.localizedDescription);
            return;
        }
        
        //Exclude PreDemSDK folder from backup
        if (![appURL setResourceValue:@YES
                               forKey:NSURLIsExcludedFromBackupKey
                                error:&error]) {
            PREDLogError(@"Error excluding %@ from backup %@", appURL.lastPathComponent, error.localizedDescription);
        } else {
            PREDLogDebug(@"Exclude %@ from backup", appURL);
        }
        
        _directorySetupComplete = YES;
    }
}

/**
 * @returns the URL to the next file depending on the specified type. If there's no file, return nil.
 */
- (NSString *)nextURLOfType:(PREDPersistenceType)type {
    NSArray<NSURL *> *fileNames = [self persistedFilesForType:type];
    if (fileNames && fileNames.count > 0) {
        for (NSURL *filename in fileNames) {
            NSString *absolutePath = filename.path;
            if (![self.requestedBundlePaths containsObject:absolutePath]) {
                return absolutePath;
            }
        }
    }
    return nil;
}

- (NSArray *)persistedFilesForType: (PREDPersistenceType)type {
    NSString *directoryPath = [self folderPathForType:type];
    NSError *error = nil;
    NSArray<NSURL *> *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:directoryPath]
                                                                includingPropertiesForKeys:@[NSURLNameKey]
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                     error:&error];
    return fileNames;
}

- (NSString *)folderPathForType:(PREDPersistenceType)type {
    NSString *subFolder = @"";
    switch (type) {
        case PREDPersistenceTypeTelemetry: {
            subFolder = kPREDTelemetryDirectory;
            break;
        }
        case PREDPersistenceTypeMetaData: {
            subFolder = kPREDMetaDataDirectory;
            break;
        }
    }
    return [self.appPreDemSDKDirectoryPath stringByAppendingPathComponent:subFolder];
}

/**
 * Send a PREDPersistenceSuccessNotification to the main thread to notify observers that we have successfully saved a file
 * This is typically used to trigger sending.
 */
- (void)sendBundleSavedNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PREDPersistenceSuccessNotification
                                                            object:nil
                                                          userInfo:nil];
    });
}

- (NSString *)appPreDemSDKDirectoryPath {
    if (!_appPreDemSDKDirectoryPath) {
        NSString *appSupportPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByStandardizingPath];
        if (appSupportPath) {
            _appPreDemSDKDirectoryPath = [appSupportPath stringByAppendingPathComponent:kPREDDirectory];
        }
    }
    return _appPreDemSDKDirectoryPath;
}

@end
