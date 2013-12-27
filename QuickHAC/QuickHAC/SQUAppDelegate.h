//
//  SQUAppDelegate.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

#define SQUMinimumFetchInterval 60*30 // seconds

@class SQUGradeOverviewController;

@interface SQUAppDelegate : UIResponder <UIApplicationDelegate> {
    UINavigationController *_navController;
    SQUGradeOverviewController *_rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *) managedObjectContext;

+ (SQUAppDelegate *) sharedDelegate;

@end
