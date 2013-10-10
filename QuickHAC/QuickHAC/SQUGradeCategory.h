//
//  SQUGradeCategory.h
//  QuickHAC
//
//  Created by Tristan Seifert on 10/09/2013.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUClassAssignment;

@interface SQUGradeCategory : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) NSSet *grades;
@end

@interface SQUGradeCategory (CoreDataGeneratedAccessors)

- (void)addGradesObject:(SQUClassAssignment *)value;
- (void)removeGradesObject:(SQUClassAssignment *)value;
- (void)addGrades:(NSSet *)values;
- (void)removeGrades:(NSSet *)values;

@end