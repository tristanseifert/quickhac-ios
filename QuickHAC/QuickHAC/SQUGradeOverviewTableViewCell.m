//
//  SQUGradeOverviewTableViewCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUCoreData.h"
#import "SQUDistrictManager.h"
#import "SQUGradeManager.h"
#import "UIColor+SQUColourUtilities.h"

@interface SQUGradeOverviewTableViewCell (PrivateMethods)

- (CATextLayer *) makeRowHeaderWithString:(NSString *) string andFrame:(CGRect) frame;
- (UIColor *) colourizeGrade:(float) grade;
- (void) drawHeaders;
- (void) drawCells;

@end

@implementation SQUGradeOverviewTableViewCell
@synthesize courseInfo = _courseInfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect rect = self.frame;
        rect.size.height = SQUGradeOverviewCellHeight;
        self.frame = rect;
		
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(10, 10, self.frame.size.width - 20, self.frame.size.height - 6);
        _backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
		_backgroundLayer.shadowOpacity = 0.0625;
		_backgroundLayer.shadowRadius = 1.0;
		_backgroundLayer.shadowOffset = CGSizeMake(-8.0, -8.0);
		_backgroundLayer.masksToBounds = NO;
		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.frame cornerRadius:_backgroundLayer.cornerRadius];
		_backgroundLayer.shadowPath = path.CGPath;
        
		// Course title
        _courseTitle = [CATextLayer layer];
        _courseTitle.frame = CGRectMake(62, 8, _backgroundLayer.frame.size.width - 70, 32);
        _courseTitle.contentsScale = [UIScreen mainScreen].scale;
        _courseTitle.foregroundColor = [UIColor blackColor].CGColor;
        _courseTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _courseTitle.fontSize = 20.0f;
		
		// Apply a mask so overly long course titles "fade out"
		CAGradientLayer *courseTitleMask = [CAGradientLayer layer];
		courseTitleMask.bounds = CGRectMake(0, 0, _courseTitle.frame.size.width, _courseTitle.frame.size.height);
		courseTitleMask.position = CGPointMake(_courseTitle.bounds.size.width/2.0, _courseTitle.bounds.size.height/2.0);
		courseTitleMask.locations = @[@(0.85f), @(1.0f)];
		courseTitleMask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
		courseTitleMask.startPoint = CGPointMake(0.0, 0.5);
		courseTitleMask.endPoint = CGPointMake(1.0, 0.5);
		_courseTitle.mask = courseTitleMask;
		
		// Average label
		_currentAverageLabel = [CATextLayer layer];
		_currentAverageLabel.frame = CGRectMake(_backgroundLayer.frame.size.width - 70, 5, 62, 38);
        _currentAverageLabel.contentsScale = [UIScreen mainScreen].scale;
        _currentAverageLabel.foregroundColor = [UIColor grayColor].CGColor;
        _currentAverageLabel.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15.0f];
        _currentAverageLabel.fontSize = 36;
		_currentAverageLabel.alignmentMode = kCAAlignmentRight;
        
		// Period label
        _periodTitle = [CATextLayer layer];
        _periodTitle.frame = CGRectMake(8, 8, 44, 44);
        _periodTitle.contentsScale = [UIScreen mainScreen].scale;
        _periodTitle.foregroundColor = [UIColor grayColor].CGColor;
        _periodTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15.0f];
        _periodTitle.fontSize = 34;
		_periodTitle.alignmentMode = kCAAlignmentCenter;
		_periodTitle.borderColor = [UIColor lightGrayColor].CGColor;
		_periodTitle.borderWidth = 1.0;
		_periodTitle.cornerRadius = _periodTitle.frame.size.width / 2;
				
		// Add sublayers
        [_backgroundLayer addSublayer:_periodTitle];
        [_backgroundLayer addSublayer:_courseTitle];
		[_backgroundLayer addSublayer:_currentAverageLabel];
		
		[self.layer addSublayer:_backgroundLayer];
		
		// Initialise data holders
		_cells = [NSMutableArray new];
		_headers = [NSMutableArray new];
		_shades = [NSMutableArray new];
    
		// Prepare background layer
		self.layer.backgroundColor = [UIColor clearColor].CGColor;
	}
    
	return self;
}

- (void) setSelected:(BOOL) selected animated:(BOOL) animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/**
 * Creates a new row header with the specified text, and returns it.
 */
- (CATextLayer *) makeRowHeaderWithString:(NSString *) string andFrame:(CGRect) frame {
	CATextLayer *new = [CATextLayer layer];
	new.contentsScale = [UIScreen mainScreen].scale;
	new.foregroundColor = [UIColor grayColor].CGColor;
	new.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
	new.fontSize = 10.5;
	new.frame = frame;
	new.alignmentMode = kCAAlignmentCenter;
	new.string = [string uppercaseString];
	return new;
}

/**
 * Draws row headers and background outlines.
 */
- (void) drawHeaders {
	BOOL isElementary = (_courseInfo.semesters.count == 1);
	
	NSArray *semesterStrings = @[NSLocalizedString(@"Exam", nil),
								 NSLocalizedString(@"Average", nil)];
	
	// Elementary students do not have exams, and only four cycles.
	if(isElementary) {
		
	} else {
		CGFloat y = 56;
		NSUInteger cycPerSem = _courseInfo.student.cyclesPerSemester.unsignedIntegerValue;
		NSUInteger heads = cycPerSem + 2;
		
		CGFloat width = _backgroundLayer.frame.size.width / heads;
		CGFloat x = 0;
		CGRect frame;
		NSString *title;
		
		// Iterate through each semester
		for (NSUInteger semester = 0; semester < _courseInfo.semesters.count; semester++) {
			x = 0;
			
			// Iterate for each cycle plus two more
			for(NSUInteger i = 0; i < heads; i++) {
				if(i < cycPerSem) {
					// CYCLE 0 and whatnot
					NSUInteger cyc = i+1;
					cyc += (semester * cycPerSem);
					title = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u", nil), cyc];
				} else {
					// Display either EXAM or AVERAGE
					NSUInteger offset = i - cycPerSem;
					title = semesterStrings[offset];
				}
				
				frame = CGRectMake(x, y+14, width, 14);
				CATextLayer *layer = [self makeRowHeaderWithString:title andFrame:frame];
				[_headers addObject:layer];
				x += width;
			}
			
			// Draw "semester outlines"
			CAGradientLayer *shade = [CAGradientLayer layer];
			shade.frame = CGRectMake(x-(width*2), y, width*2, 75);
			shade.backgroundColor = UIColorFromRGB(0xf2f2f2).CGColor;
			[_shades addObject:shade];
			
			// Draw the "SEMESTER 1" title
			CATextLayer *semesterHeader = [CATextLayer layer];
			semesterHeader.contentsScale = [UIScreen mainScreen].scale;
			semesterHeader.foregroundColor = [UIColor grayColor].CGColor;
			CTFontRef ref = CTFontCreateWithName((CFStringRef)@"HelveticaNeue-Medium", 12, NULL);
			CTFontRef italicFont = CTFontCreateCopyWithSymbolicTraits(ref, 12, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
			semesterHeader.font = italicFont;
			semesterHeader.fontSize = 12;
			semesterHeader.frame = CGRectMake((x-width*2), y, width*2, 14);
			semesterHeader.alignmentMode = kCAAlignmentCenter;
			semesterHeader.string = [NSString stringWithFormat:NSLocalizedString(@"Semester %u", nil), semester+1];
			[_headers addObject:semesterHeader];
			
			y += 75;
		}
	}
}

/**
 * Draws the cells containing the actual data.
 */
- (void) drawCells {
	BOOL isElementary = (_courseInfo.semesters.count == 1);
	
	// Elementary students do not have exams, and only four cycles.
	if(isElementary) {
		
	} else {
		CGFloat y = 56;
		NSUInteger cycPerSem = _courseInfo.student.cyclesPerSemester.unsignedIntegerValue;
		NSUInteger heads = cycPerSem + 2;
		
		CGFloat width = _backgroundLayer.frame.size.width / heads;
		CGFloat x = 0;
		
		// Iterate through each semester
		for (NSUInteger semester = 0; semester < _courseInfo.semesters.count; semester++) {
			SQUSemester *sem = _courseInfo.semesters[semester];
			x = 0;
			
			// Iterate for each cycle plus two more
			for(NSUInteger i = 0; i < heads; i++) {
				CAGradientLayer *bg = [CAGradientLayer new];
				bg.frame = CGRectMake(x, y + 28, width, 47);
				bg.backgroundColor = UIColorFromRGB(0xffffff).CGColor;
				
				// Draw average
				CATextLayer *average = [CATextLayer layer];
				average.frame = CGRectMake(0, 4, width, 47);
				average.contentsScale = [UIScreen mainScreen].scale;
				average.foregroundColor = [UIColor blackColor].CGColor;
				average.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
				average.fontSize = 31;
				average.alignmentMode = kCAAlignmentCenter;
				average.string = @"100";
				[bg addSublayer:average];
				
				if(i < cycPerSem) {
					SQUCycle *cycle = _courseInfo.cycles[i + (semester * cycPerSem)];
					
					if(cycle.average.unsignedIntegerValue != 0) {
						average.string = [NSString stringWithFormat:NSLocalizedString(@"%u", nil), cycle.average.unsignedIntegerValue];
						bg.backgroundColor = [self colourizeGrade:cycle.average.floatValue].CGColor;
					} else {
						average.string = NSLocalizedString(@"-", nil);
						bg.backgroundColor = UIColorFromRGB(0xe0e0e0).CGColor;
					}
				} else {
					NSUInteger offset = i - cycPerSem;
					
					if(offset == 0) {
						if(sem.examIsExempt.boolValue) { // exam
							average.string = NSLocalizedString(@"Exc", nil);
							bg.backgroundColor = UIColorFromRGB(0xe0e0e0).CGColor;
						} else if(sem.examGrade.integerValue == -1) {
							average.string = NSLocalizedString(@"-", nil);
							bg.backgroundColor = UIColorFromRGB(0xe0e0e0).CGColor;
						} else {
							average.string = [NSString stringWithFormat:NSLocalizedString(@"%u", nil), sem.examGrade.unsignedIntegerValue];
							bg.backgroundColor = [self colourizeGrade:sem.examGrade.floatValue].CGColor;
						}
					} else if(offset == 1) { // semester average
						if(sem.average.integerValue == -1) {
							average.string = NSLocalizedString(@"-", nil);
							bg.backgroundColor = UIColorFromRGB(0xe0e0e0).CGColor;
						} else {
							average.string = [NSString stringWithFormat:NSLocalizedString(@"%u", nil), sem.average.unsignedIntegerValue];
							bg.backgroundColor = [self colourizeGrade:sem.average.floatValue].CGColor;
						}
					}
				}
				
				[_cells addObject:bg];
				x += width;
			}
			
			y += 75;
		}
	}
}

- (void) updateUI {
	NSUInteger period = _courseInfo.period.unsignedIntegerValue;
    _periodTitle.string = [NSString stringWithFormat:NSLocalizedString(@"%u", nil), period];
    _courseTitle.string = _courseInfo.title;
	
	// Get rid of all the currently existing layers
	for (CALayer *layer in _cells) {
		[layer removeFromSuperlayer];
	} for (CALayer *layer in _headers) {
		[layer removeFromSuperlayer];
	} for (CALayer *layer in _shades) {
		[layer removeFromSuperlayer];
	}
	
	[_cells removeAllObjects];
	[_headers removeAllObjects];
	[_shades removeAllObjects];
	
	// Re-draw table
	[self drawHeaders];
	[self drawCells];
	
	for (CALayer *layer in _shades) {
		[_backgroundLayer addSublayer:layer];
	} for (CALayer *layer in _headers) {
		[_backgroundLayer addSublayer:layer];
	} for (CALayer *layer in _cells) {
		[_backgroundLayer addSublayer:layer];
	}
	
	// Update average label
	_currentAverageLabel.string = @"";
	
	for (NSUInteger i = 0; i < _courseInfo.semesters.count; i++) {
		SQUSemester *semester = _courseInfo.semesters[i];
		if(semester.average.integerValue != -1) {
			_currentAverageLabel.string = [NSString stringWithFormat:
										   NSLocalizedString(@"%u", nil),
										   semester.average.unsignedIntegerValue];
		}
	}
}

- (UIColor *) colourizeGrade:(float) grade {
    // Makes sure asianness cannot be negative
    NSUInteger asianness_limited = MAX(2, 0);
    
    // interpolate a hue gradient and convert to rgb
    float h, s, v;
    
    // determine color. ***MAGIC DO NOT TOUCH UNDER ANY CIRCUMSTANCES***
    if (grade > 100) {
        h = 0.13055;
        s = 0;
        v = 1;
    } else if (grade < 0) {
        h = 0;
        s = 1;
        v = 0.86945;
    } else {
        h = MIN(0.25 * pow(grade / 100, asianness_limited), 0.13056);
        s = 1 - pow(grade / 100, asianness_limited * 2);
        v = 0.86945 + h;
    }
    
    // apply hue transformation
	//    h += hue;
	//    h %= 1;
	//    if (h < 0) h += 1;
    
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:1.0];
}

@end
