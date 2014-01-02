//
//  SQUGradebookDriver.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

@class SQUDistrict;

/**
 * Required protocol for all gradebook drivers.
 */
@protocol SQUGradebookDriverProtocol <NSObject>

@required
/**
 * Parses the class averages from the gradebook.
 *
 * @param district: District to use for parsing.
 * @param string: Gradebook HTML.
 * @return Averages for all courses the student is enrolled in.
 */
- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withString:(NSString *) string;
/**
 * Parses the assignments in a class.
 *
 * @param district: District to use in parsing.
 * @param string: Gradebook HTML.
 * @return Categories and assignments for the class.
 */
- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withString:(NSString *) string;
/**
 * @param district: District to use for parsing.
 * @param string: Gradebook HTML.
 * @return Student's name.
 */
- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withString:(NSString *) string;

@end

@interface SQUGradebookDriver : NSObject <SQUGradebookDriverProtocol> {
	NSString *_identifier;
}

@property (nonatomic, readonly) NSString *identifier;

@end
