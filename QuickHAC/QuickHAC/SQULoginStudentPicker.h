//
//  SQULoginStudentPicker.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@class SQULoginStudentPicker;
@class SQUStudent;
@protocol SQULoginStudentPickerDelegate <NSObject>

@required
- (void) studentPickerCancelled:(SQULoginStudentPicker *) picker;
- (void) studentPickerDidSelect:(SQULoginStudentPicker *) picker withStudent:(SQUStudent *) student;

@end

@interface SQULoginStudentPicker : UITableViewController {
	NSMutableArray *_students;
	
	id<SQULoginStudentPickerDelegate> _delegate;
}

@property (readwrite, nonatomic) NSMutableArray *students;
@property (readwrite, nonatomic) id<SQULoginStudentPickerDelegate> delegate;

@end
