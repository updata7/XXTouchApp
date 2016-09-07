//
//  XXArchiveService.m
//  XXTouchApp
//
//  Created by Zheng on 9/7/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXArchiveService.h"

@implementation XXArchiveService
+ (NSArray <NSString *> *)supportedArchiveFileExtensions {
    return @[ @"zip" ];
}

+ (BOOL)unArchiveZip:(NSString *)filePath
         toDirectory:(NSString *)path
parentViewController:(UIViewController <SSZipArchiveDelegate> *)viewController {
    NSString *fileExt = [filePath pathExtension];
    if ([[self supportedArchiveFileExtensions] indexOfObject:fileExt] != NSNotFound) { // Zip Archive
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Unarchive"
                                                         andMessage:NSLocalizedStringFromTable(@"Extract to the current directory?\nItem with the same name will be overwritten.", @"XXTouch", nil)];
        [alertView addButtonWithTitle:NSLocalizedStringFromTable(@"Yes", @"XXTouch", nil) type:SIAlertViewButtonTypeDestructive handler:^(SIAlertView *alertView) {
            __block UINavigationController *navController = viewController.navigationController;
            navController.view.userInteractionEnabled = NO;
            [navController.view makeToastActivity:CSToastPositionCenter];
            __block NSError *error = nil;
            __block NSString *destination = path;
            [FCFileManager createDirectoriesForPath:destination error:&error];
            if (error) {
                navController.view.userInteractionEnabled = YES;
                [navController.view hideToastActivity];
                [navController.view makeToast:[error localizedDescription]];
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [SSZipArchive unzipFileAtPath:filePath
                                    toDestination:destination
                                        overwrite:YES
                                         password:nil
                                            error:&error
                                         delegate:viewController];
                    dispatch_async_on_main_queue(^{
                        navController.view.userInteractionEnabled = YES;
                        [navController.view hideToastActivity];
                        if (error) {
                            [navController.view makeToast:[error localizedDescription]];
                        }
                    });
                });
            }
        }];
        [alertView addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"XXTouch", nil) type:SIAlertViewButtonTypeCancel handler:^(SIAlertView *alertView) {
            
        }];
        [alertView show];
        return YES;
    }
    return NO;
}

+ (BOOL)archiveItems:(NSArray <NSString *> *)items
         toDirectory:(NSString *)path
parentViewController:(UIViewController <SSZipArchiveDelegate> *)viewController {
    if (items.count <= 0) {
        return NO;
    }
    
    __block NSError *error = nil;
    __block UINavigationController *navController = viewController.navigationController;
    navController.view.userInteractionEnabled = NO;
    [navController.view makeToastActivity:CSToastPositionCenter];
    
    NSString *destination = path;
    NSString *archiveName = nil;
    NSString *archivePath = nil;
    if (items.count == 1) {
        archiveName = [[items[0] lastPathComponent] stringByAppendingPathExtension:@"zip"];
        archivePath = [destination stringByAppendingPathComponent:archiveName];
    } else {
        archiveName = @"Archive.zip";
        if ([FCFileManager existsItemAtPath:[destination stringByAppendingPathComponent:archiveName]]) {
            NSUInteger testIndex = 2;
            do {
                archivePath = [destination stringByAppendingPathComponent:[NSString stringWithFormat:@"Archive %lu.zip", (unsigned long)testIndex]];
                testIndex++;
            } while ([FCFileManager existsItemAtPath:archivePath]);
        } else {
            archivePath = [destination stringByAppendingPathComponent:archiveName];
        }
    }
    CYLog(@"%@", archivePath);
    
    NSMutableArray *allPaths = [[NSMutableArray alloc] init];
    for (NSString *itemPath in items) {
        if ([FCFileManager isDirectoryItemAtPath:itemPath error:&error]) {
            [allPaths addObjectsFromArray:[FCFileManager listFilesInDirectoryAtPath:itemPath deep:YES]];
        } else {
            [allPaths addObject:itemPath];
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL result = [SSZipArchive createZipFileAtPath:archivePath
                                       withFilesAtPaths:allPaths
                                           withPassword:nil
                                               delegate:viewController];
        dispatch_async_on_main_queue(^{
            navController.view.userInteractionEnabled = YES;
            [navController.view hideToastActivity];
            if (!result) {
                [navController.view makeToast:NSLocalizedStringFromTable(@"Cannot create zip file", @"XXTouch", nil)];
            }
        });
    });
    return YES;
}

@end