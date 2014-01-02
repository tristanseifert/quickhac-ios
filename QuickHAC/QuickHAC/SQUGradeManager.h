//
//  SQUGradeManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradebookDriver.h"

#import <Foundation/Foundation.h>

#define SQUGradesDataUpdatedNotification @"SQUGradesDataUpdatedNotification"
#define SQUStudentsUpdatedNotification @"SQUStudentsUpdatedNotification"

@class SQUStudent;
@interface SQUGradeManager : NSObject {
	SQUStudent *_student;
	
	NSMutableArray *_gradebookDrivers;
	SQUGradebookDriver *_currentDriver;
	
	NSManagedObjectContext *_coreDataMOContext;
}

@property (nonatomic, readwrite, strong) SQUStudent *student;
@property (nonatomic, readonly) SQUGradebookDriver *currentDriver;
@property (nonatomic, readonly, getter = getCoursesForCurrentStudent) NSOrderedSet *courses;

+ (SQUGradeManager *) sharedInstance;

- (void) registerDriver:(Class) driver;
- (NSArray *) loadedDrivers;
- (BOOL) selectDriverWithID:(NSString *) driverID;

- (NSOrderedSet *) getCoursesForCurrentStudent;

- (void) fetchNewClassGradesFromServerWithDoneCallback:(void (^)(NSError *)) callback;
- (void) updateCurrentStudentWithClassAverages:(NSArray *) classAvgs;

- (void) fetchNewCycleGradesFromServerForCourse:(NSString *) course withCycle:(NSUInteger) cycle andSemester:(NSUInteger) semester andDoneCallback:(void (^)(NSError *)) callback;
- (void) updateCurrentStudentWithClassGrades:(NSDictionary *) classGrades forClass:(NSString *) class andCycle:(NSUInteger) numCycle andSemester:(NSUInteger) numSemester;

- (NSNumber *) calculateGPAWeighted:(BOOL) weighted forCourses:(NSArray *) courses;

@end
