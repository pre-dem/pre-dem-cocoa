#import "PreSniffObjc.h"
#import "PRESPersistence.h"
#import "PRESPersistencePrivate.h"
#import "PRESPrivate.h"
#import "PRESHelper.h"

NSString *const PRESPersistenceSuccessNotification = @"PRESPersistenceSuccessNotification";

static NSString *const kPRESTelemetry = @"Telemetry";
static NSString *const kPRESMetaData = @"MetaData";
static NSString *const kPRESFileBaseString = @"hockey-app-bundle-";
static NSString *const kPRESFileBaseStringMeta = @"metadata";

static NSString *const kPRESDirectory = @"com.microsoft.PreSniff";
static NSString *const kPRESTelemetryDirectory = @"Telemetry";
static NSString *const kPRESMetaDataDirectory = @"MetaData";

static char const *kPRESPersistenceQueueString = "com.microsoft.PreSniff.persistenceQueue";
static NSUInteger const PRESDefaultFileCount = 50;

@implementation PRESPersistence {
    BOOL _directorySetupComplete;
}

#pragma mark - Public

- (instancetype)init {
    self = [super init];
    if (self) {
        _persistenceQueue = dispatch_queue_create(kPRESPersistenceQueueString, DISPATCH_QUEUE_SERIAL); //TODO several queues?
        _requestedBundlePaths = [NSMutableArray new];
        _maxFileCount = PRESDefaultFileCount;
        
        // Evantually, there will be old files on disk, the flag will be updated before the first event gets created
        _directorySetupComplete = NO; //will be set to true in createDirectoryStructureIfNeeded
        
        [self createDirectoryStructureIfNeeded];
    }
    return self;
}

/**
 * Saves the Bundle using NSKeyedArchiver and NSData's writeToFile:atomically
 * Sends out a PRESPersistenceSuccessNotification in case of success
 */
- (void)persistBundle:(NSData *)bundle {
    //TODO send out a fail notification?
    NSString *fileURL = [self fileURLForType:PRESPersistenceTypeTelemetry];
    
    if (bundle) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.persistenceQueue, ^{
            typeof(self) strongSelf = weakSelf;
            BOOL success = [bundle writeToFile:fileURL atomically:YES];
            if (success) {
                PRESLogDebug(@"INFO: Wrote bundle to %@", fileURL);
                [strongSelf sendBundleSavedNotification];
            }
            else {
                PRESLogError(@"Error writing bundle to %@", fileURL);
            }
        });
    }
    else {
        PRESLogWarning(@"WARNING: Unable to write %@ as provided bundle was null", fileURL);
    }
}

- (void)persistMetaData:(NSDictionary *)metaData {
    NSString *fileURL = [self fileURLForType:PRESPersistenceTypeMetaData];
    //TODO send out a notification, too?!
    dispatch_async(self.persistenceQueue, ^{
        [NSKeyedArchiver archiveRootObject:metaData toFile:fileURL];
    });
}

- (BOOL)isFreeSpaceAvailable {
    NSArray *files = [self persistedFilesForType:PRESPersistenceTypeTelemetry];
    return files.count < _maxFileCount;
}

- (NSString *)requestNextFilePath {
    __block NSString *path = nil;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.persistenceQueue, ^() {
        typeof(self) strongSelf = weakSelf;
        
        path = [strongSelf nextURLOfType:PRESPersistenceTypeTelemetry];
        
        if (path) {
            [self.requestedBundlePaths addObject:path];
        }
    });
    return path;
}

- (NSDictionary *)metaData {
    NSString *filePath = [self fileURLForType:PRESPersistenceTypeMetaData];
    NSObject *bundle = [self bundleAtFilePath:filePath withFileBaseString:kPRESFileBaseStringMeta];
    if ([bundle isKindOfClass:NSDictionary.class]) {
        return (NSDictionary *) bundle;
    }
    PRESLogDebug(@"INFO: The context meta data file could not be loaded.");
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
    if (path && [path rangeOfString:kPRESFileBaseString].location != NSNotFound) {
        data = [NSData dataWithContentsOfFile:path];
    }
    return data;
}

/**
 * Deletes a file at the given path.
 *
 * @param the path to look for a file and delete it.
 */
- (void)deleteFileAtPath:(NSString *)path {
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.persistenceQueue, ^() {
        typeof(self) strongSelf = weakSelf;
        if ([path rangeOfString:kPRESFileBaseString].location != NSNotFound) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                PRESLogError(@"Error deleting file at path %@", path);
            }
            else {
                PRESLogDebug(@"INFO: Successfully deleted file at path %@", path);
                [strongSelf.requestedBundlePaths removeObject:path];
            }
        } else {
            PRESLogDebug(@"INFO: Empty path, nothing to delete");
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

- (nullable NSString *)fileURLForType:(PRESPersistenceType)type {
    
    NSString *fileName = nil;
    NSString *filePath;
    
    switch (type) {
        case PRESPersistenceTypeMetaData: {
            fileName = kPRESFileBaseStringMeta;
            filePath = [self.appPreSniffSDKDirectoryPath stringByAppendingPathComponent:kPRESMetaDataDirectory];
            break;
        };
        default: {
            NSString *uuid = pres_UUID();
            fileName = [NSString stringWithFormat:@"%@%@", kPRESFileBaseString, uuid];
            filePath = [self.appPreSniffSDKDirectoryPath stringByAppendingPathComponent:kPRESTelemetryDirectory];
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
    NSString *appPreSniffSDKDirectoryPath = [self appPreSniffSDKDirectoryPath];
    NSURL *appURL = [NSURL fileURLWithPath:appPreSniffSDKDirectoryPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (appURL) {
        NSError *error = nil;
        
        // Create PreSniffSDK folder if needed
        if (![fileManager createDirectoryAtURL:appURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PRESLogError(@"ERROR: %@", error.localizedDescription);
            return;
        }
        
        // Create metadata subfolder
        NSURL *metaDataURL = [appURL URLByAppendingPathComponent:kPRESMetaDataDirectory];
        if (![fileManager createDirectoryAtURL:metaDataURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PRESLogError(@"ERROR: %@", error.localizedDescription);
            return;
        }
        
        // Create telemetry subfolder
        
        //NOTE: createDirectoryAtURL:withIntermediateDirectories:attributes:error
        //will return YES if the directory already exists and won't override anything.
        //No need to check if the directory already exists.
        NSURL *telemetryURL = [appURL URLByAppendingPathComponent:kPRESTelemetryDirectory];
        if (![fileManager createDirectoryAtURL:telemetryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PRESLogError(@"ERROR: %@", error.localizedDescription);
            return;
        }
        
        //Exclude PreSniffSDK folder from backup
        if (![appURL setResourceValue:@YES
                               forKey:NSURLIsExcludedFromBackupKey
                                error:&error]) {
            PRESLogError(@"ERROR: Error excluding %@ from backup %@", appURL.lastPathComponent, error.localizedDescription);
        } else {
            PRESLogDebug(@"INFO: Exclude %@ from backup", appURL);
        }
        
        _directorySetupComplete = YES;
    }
}

/**
 * @returns the URL to the next file depending on the specified type. If there's no file, return nil.
 */
- (NSString *)nextURLOfType:(PRESPersistenceType)type {
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

- (NSArray *)persistedFilesForType: (PRESPersistenceType)type {
    NSString *directoryPath = [self folderPathForType:type];
    NSError *error = nil;
    NSArray<NSURL *> *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:directoryPath]
                                                                includingPropertiesForKeys:@[NSURLNameKey]
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                     error:&error];
    return fileNames;
}

- (NSString *)folderPathForType:(PRESPersistenceType)type {
    NSString *subFolder = @"";
    switch (type) {
        case PRESPersistenceTypeTelemetry: {
            subFolder = kPRESTelemetryDirectory;
            break;
        }
        case PRESPersistenceTypeMetaData: {
            subFolder = kPRESMetaDataDirectory;
            break;
        }
    }
    return [self.appPreSniffSDKDirectoryPath stringByAppendingPathComponent:subFolder];
}

/**
 * Send a PRESPersistenceSuccessNotification to the main thread to notify observers that we have successfully saved a file
 * This is typically used to trigger sending.
 */
- (void)sendBundleSavedNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PRESPersistenceSuccessNotification
                                                            object:nil
                                                          userInfo:nil];
    });
}

- (NSString *)appPreSniffSDKDirectoryPath {
    if (!_appPreSniffSDKDirectoryPath) {
        NSString *appSupportPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByStandardizingPath];
        if (appSupportPath) {
            _appPreSniffSDKDirectoryPath = [appSupportPath stringByAppendingPathComponent:kPRESDirectory];
        }
    }
    return _appPreSniffSDKDirectoryPath;
}

@end
