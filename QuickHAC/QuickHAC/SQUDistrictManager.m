//
//  SQUDistrictManager.m
//  QuickHAC
//
//	Management of districts loaded into the app and interfacing with them.
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUCoreData.h"
#import "NSURL+RequestParams.h"
#import "NSMutableURLRequest+POSTGenerator.h"
#import "SQUDistrictManager.h"

#import "AFNetworking.h"

static SQUDistrictManager *_sharedInstance = nil;

@implementation SQUDistrictManager
@synthesize currentDistrict = _currentDistrict, reachabilityManager = _reachabilityManager;
@synthesize HTTPManager = _HTTPManager;

#pragma mark - Singleton

+ (SQUDistrictManager *) sharedInstance {
    @synchronized (self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] init];
        }
    }
    
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone {
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;
        }
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone *) zone {
    return self;
}

- (id) init {
    @synchronized(self) {
        if(self = [super init]) {
			_loadedDistricts = [NSMutableArray new];
			_initialisedDistricts = [NSMutableArray new];
			
			// Set up HTTP manager and response serialiser
			_HTTPManager = [AFHTTPRequestOperationManager manager];
			_HTTPManager.responseSerializer = [AFHTTPResponseSerializer serializer];
			
			// Set string encoding
			NSStringEncoding enc = NSUTF8StringEncoding;
			_HTTPManager.responseSerializer.stringEncoding = enc;
			_HTTPManager.requestSerializer.stringEncoding = enc;
			
			// why please
			[_HTTPManager.requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.117 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        }
		
        return self;
    }
}

#pragma mark - District management
/**
 * Registers the specified district with the manager.
 *
 * @param district: Class to register.
 */
- (void) registerDistrict:(Class) district {
	if([district conformsToProtocol:@protocol(SQUDistrictProtocol)]) {
		[_loadedDistricts addObject:district];
		NSUInteger index = [_loadedDistricts indexOfObject:district];
		
		SQUDistrict *districtInitialised = [[district alloc] init];
		[districtInitialised districtWasSelected:districtInitialised];
		[_initialisedDistricts insertObject:districtInitialised atIndex:index];
		
		// NSLog(@"Loaded district %@ (%@, using driver %@)",  district, districtInitialised.name, districtInitialised.driver);
	} else {
		NSLog(@"Tried to load district %@, but %@ does not conform to SQUDistrictProtocol.", district, NSStringFromClass(district));
	}
}

/**
 * Returns an array of SQUDistrict subclasses that have been registered.
 *
 * @return All districts currently registered.
 */
- (NSArray *) loadedDistricts {
	return [NSArray arrayWithArray:_initialisedDistricts];
}

/**
 * Searches through all loaded districts for one that matches the ID, then sets
 * it as the active district.
 *
 * @param districtID: Numerical identifier of the district.
 * @return YES on success, NO if not found.
 */
- (BOOL) selectDistrictWithID:(NSInteger) districtID {
	/*// Changing districts
	NSArray *munchies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	
	for (NSHTTPCookie *cookie in munchies) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}*/
	
	// This forces a login to happen again
	_lastRequest = nil;
	
	// Select the district
	for(SQUDistrict *district in _initialisedDistricts) {
		if(district.district_id == districtID) {
			// we found the district, activate it
			[self setCurrentDistrict:district];
			
			return YES;
		}
	}
	
	return NO;
}

/**
 * Setter for _currentDistrict.
 */
- (void) setCurrentDistrict:(SQUDistrict *) currentDistrict {
	_currentDistrict = currentDistrict;
	
	_HTTPManager.securityPolicy.allowInvalidCertificates = YES;
	
	// Check if the user disabled certificate validation
	/*if([[NSUserDefaults standardUserDefaults] boolForKey:@"certPinning"]) {
		// Load the district's SSL certs, if they are specified.
		NSArray *certs = [currentDistrict districtSSLCertData];
		
		// If there's no certs, panic
		if((certs.count == 1 && [certs[0] integerValue] == 0) || !certs) {
			_HTTPManager.securityPolicy.SSLPinningMode = AFSSLPinningModeNone;
			_HTTPManager.securityPolicy.allowInvalidCertificates = YES;
			_HTTPManager.securityPolicy.pinnedCertificates = nil;
			
			// NSLog(@"SECURITY POLICY CHANGED: Accepts invalid certs (%@)", currentDistrict.name);
		} else if(certs.count != 0) {
			_HTTPManager.securityPolicy.allowInvalidCertificates = NO;
			_HTTPManager.securityPolicy.SSLPinningMode = AFSSLPinningModeCertificate;
			
			[_HTTPManager.securityPolicy setPinnedCertificates:certs];
			
			// NSLog(@"SECURITY POLICY CHANGED: Rejects invalid certs (%@)", currentDistrict.name);
		}
	} else {
		_HTTPManager.securityPolicy.allowInvalidCertificates = YES;
		// NSLog(@"WARNING: Accepting any certificate!");
	}*/
	
	// Update the reachability manager
//	if(currentDistrict.districtDomain) {
//		_reachabilityManager = [AFNetworkReachabilityManager managerForDomain:currentDistrict.districtDomain];
//	} else {
		_reachabilityManager = [AFNetworkReachabilityManager sharedManager];
//	}
	
	_lastRequest = nil;
}

/**
 * Returns a district for a specific ID.
 *
 * @param districtID: Numerical identifier of the district.
 * @return A SQUDistrict object matching the identifier, or nil if not found.
 */
- (SQUDistrict *) districtWithID:(NSInteger) districtID {
	for(SQUDistrict *district in _initialisedDistricts) {
		if(district.district_id == districtID) {
			return district;
		}
	}
	
	return nil;
}

/**
 * Causes the next request to perform a login request.
 */
- (void) setNeedsRelogon {
	_lastRequest = nil;
}

#pragma mark - Request helper methods
/**
 * Creates a GET request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendGETRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	[_HTTPManager GET:[url absoluteString]
		   parameters:params
			  success:success
			  failure:failure];
}

/**
 * Creates a POST request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendPOSTRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	[_HTTPManager POST:[url absoluteString]
			parameters:params
			   success:success
			   failure:failure];
}

#pragma mark - District interfacing
/**
 * Sends the actual login request.
 */
- (void) performActualLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	__strong __block NSDictionary *loginRequest = [_currentDistrict buildLoginRequestWithUser:username usingPassword:password andUserData:nil];

	if(!loginRequest) {
		NSError *err = [NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorLoginFailure userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"There was an error (-1305) initialising the login process. Ensure that HAC is not down.\n\nIf this problem persists, re-install QuickHAC.", nil)}];
		
		callback(err, nil);
		return;
	}
	
	NSURL *url = loginRequest[@"request"][@"URL"];
	
	// Called on success of the operation (200 OK)
	void (^loginSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSData *data = [self fixData:responseObject];
		
		[_currentDistrict updateDistrictStateWithPostLoginData:data];
		
		// The server accepted our request, now check if the request succeeded
		if([_currentDistrict didLoginSucceedWithLoginData:data]) {
			NSMutableDictionary *response = [NSMutableDictionary new];
			response[@"username"] = username;
			response[@"password"] = password;
			response[@"serverResponse"] = responseObject;
			
			_lastRequest = [NSDate date];
			
			// Does the district have a post-login request to do?
			if([_currentDistrict hasPostLoginRequest]) {
				[_currentDistrict doPostLoginRequestWithCallback:^(NSError *err) {
					// Error with the request?
					if(err) {
						callback(err, nil);
						_lastRequest = nil;
					} else {
						callback(nil, responseObject);
					}
				}];
			} else {
				callback(nil, responseObject);				
			}
		} else {
			callback(nil, responseObject);
		}
	};
	
	// Called if the request fails for some reason (500, network error, etc)
	void (^loginFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
	};
	
	if([loginRequest[@"request"][@"method"] isEqualToString:@"POST"]) {
		[self sendPOSTRequestToURL:url withParameters:loginRequest[@"params"] andSuccessBlock:loginSuccess andFailureBlock:loginFailure];
	} else {
		NSLog(@"Unsupported login method: %@", loginRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Performs a login for the user, handling any pre-login requests if they are
 * required.
 *
 * @param username: The username to log in with.
 * @param password: The password to log in with.
 * @param callback: Callback block to execute in response to login state.
 */
- (void) performLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	// Perform the pre-login request, if it's a thing
	NSDictionary *preLogin = [_currentDistrict buildPreLoginRequestWithUserData:nil];
	
	// Support districts that don't require a pre-login request
	if(preLogin) {
		// Called if the pre-login succeeds
		void (^preLoginSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
			NSData *data = [self fixData:responseObject];
			[_currentDistrict updateDistrictStateWithPreLoginData:data];
			
			// Perform the actual login, as the pre log-in request was success
			[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
		};
		
		// Called on server error
		void (^preLoginFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
			callback(error, nil);
			NSLog(@"Pre log-in error: %@", error);
			
			_lastRequest = nil;
		};
		
		// Set up the request
		NSURL *url = preLogin[@"request"][@"URL"];
		
		if([preLogin[@"request"][@"method"] isEqualToString:@"GET"]) {
			[self sendGETRequestToURL:url withParameters:preLogin[@"params"] andSuccessBlock:preLoginSuccess andFailureBlock:preLoginFailure];
		} else {
			NSLog(@"Unsupported pre-login method: %@", preLogin[@"request"][@"method"]);
			return;
		}
	} else { // We do not have a pre-login request
		[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
	}
}

/**
 * Disambiguates, or selects, a specific student on the account. This is required
 * before accessing any other parts of the gradebook software, especially if the
 * account has multiple students on it.
 *
 * @param sid: Student ID to select.
 * @param callback: Callback block to execute.
 */
- (void) performDisambiguationRequestWithStudentID:(NSString *) sid andCallback:(SQUDistrictCallback) callback {
	// Do not perform disambiguation if there is only a single student on the account.
	if(!_currentDistrict.hasMultipleStudents || !sid) {
		callback(nil, nil);
		return;
	}
	
	NSDictionary *disambiguationRequest = [_currentDistrict buildDisambiguationRequestWithStudentID:sid andUserData:nil];
	
	// Called if the request succeeds
	void (^disambiguateSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSData *data = [self fixData:responseObject];
		
		if([_currentDistrict didDisambiguationSucceedWithLoginData:data]) {
			callback(nil, responseObject);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The disambiguation process failed.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^disambiguateFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		NSLog(@"Disambiguation error: %@", error);
		
		NSLog(@"Response: %@", operation.responseString);
	};
	
	// Set up the request
	NSURL *url = disambiguationRequest[@"request"][@"URL"];
	
	if([disambiguationRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:disambiguationRequest[@"params"] andSuccessBlock:disambiguateSuccess andFailureBlock:disambiguateFailure];
	} else if([disambiguationRequest[@"request"][@"method"] isEqualToString:@"POST"]) {
		[self sendPOSTRequestToURL:url withParameters:disambiguationRequest[@"params"] andSuccessBlock:disambiguateSuccess andFailureBlock:disambiguateFailure];
	} else {
		NSLog(@"Unsupported disambiguation method: %@", disambiguationRequest[@"request"][@"method"]);
		return;
	}
}

/*
 * Data fix
 *
 * A little note about this kludge:
 *
 * AISD is a bunch of dipshits and in their recent GradeSpeed update that
 * displays GPA, they introduced a nice little issue in which there's
 * random \x00's scattered throughout the page.
 *
 * Seriously. If you have \x00 in your damn HTML you should be shot, run
 * over with an SUV, shot again, then drowned in a solution of twelve molar
 * hydrosulphuric acid. And then shot again.
 */
- (NSData *) fixData:(NSData *) in {
	NSMutableData *data = [in mutableCopy];
	uint8_t *bytes = (uint8_t *) data.bytes;
	uint32_t spaces = 0x20202020;
	
	// loop through all bytes
	for (NSUInteger i = 0; i < data.length; i++) {
		if(bytes[i] == 0x00) {
			[data replaceBytesInRange:NSMakeRange(i, 1) withBytes:&spaces length:1];
			// NSLog(@"Fixing 0x00 in response at 0x%X", i);
		}
	}
	
	return [data copy];
}

/**
 * Fetches class averages from the server, parsing the data appropriately and
 * returning it to the callback.
 *
 * @param callback: Callback block to execute with parsed class averages.
 */
- (void) performAveragesRequestWithCallback:(SQUDistrictCallback) callback {
	NSDictionary *avgRequest = [_currentDistrict buildAveragesRequestWithUserData:nil];
	
	SQUStudent *studentToUpdate = [SQUGradeManager sharedInstance].student;
	
	// Called if the request succeeds
	void (^averagesSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSData *data = [self fixData:responseObject];
		
		NSArray *averages = [[SQUGradeManager sharedInstance].currentDriver parseAveragesForDistrict:_currentDistrict withData:data];
		
		if(averages != nil) {
			NSString *studentName = [[SQUGradeManager sharedInstance].currentDriver getStudentNameForDistrict:_currentDistrict withData:data];
			NSString *studentSchool = [[SQUGradeManager sharedInstance].currentDriver getStudentSchoolForDistrict:_currentDistrict withData:data];
			
			performUpdate: ;
			studentToUpdate.name = studentName;
			studentToUpdate.school = studentSchool;
				
			[_currentDistrict updateDistrictStateWithClassGrades:averages];
			
			// Update the display name
			NSArray *components = [studentName componentsSeparatedByString:@", "];
			if(components.count == 2) {
				NSString *firstName = components[1];
				components = [firstName componentsSeparatedByString:@" "];
				
				if(components.count == 0) {
					studentToUpdate.display_name = firstName;
				} else {
					studentToUpdate.display_name = components[0];
				}
			} else {
				studentToUpdate.display_name = studentName;
			}
			
			// NSLog(@"Updated grades for %@ (%@)", [SQUGradeManager sharedInstance].student.name, [SQUGradeManager sharedInstance].student.display_name);
			
			// Run the callback now to appease login process
			callback(nil, averages);
			
			_lastRequest = [NSDate date];
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
			_lastRequest = nil;
			// NSLog(@"Got screwy response from gradebook: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
		}
	};
	
	// Called on server error
	void (^averagesFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
		NSLog(@"Averages error: %@", error);
	};
	
	// Set up the request
	NSURL *url = avgRequest[@"request"][@"URL"];
	
	if([avgRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:avgRequest[@"params"] andSuccessBlock:averagesSuccess andFailureBlock:averagesFailure];
	} else {
		NSLog(@"Unsupported average fetching method: %@", avgRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Performs a request to fetch the grades for a specific class.
 *
 * @param course: Course code whose grades to look up.
 * @param cycle: Cycle to load.
 * @param semester: Semester containing the cycle.
 * @param callback: Callback block to execute.
 */
- (void) performClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle inSemester:(NSUInteger) semester andCallback:(SQUDistrictCallback) callback {
	NSDictionary *classGradesRequest = [_currentDistrict buildClassGradesRequestWithCourseCode:course andSemester:semester andCycle:cycle andUserData:nil];
	
	if(!classGradesRequest) {
		callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorNoDataAvailable userInfo:@{@"localizedDescription" : NSLocalizedString(@"No data is available for the selected cycle.", nil)}], nil);
		return;
	}
	
	// Called if the request succeeds
	void (^callbackSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSData *data = [self fixData:responseObject];
		
		NSDictionary *classGrades = [[SQUGradeManager sharedInstance].currentDriver getClassGradesForDistrict:_currentDistrict withData:data];
		
		if(classGrades != nil) {
			callback(nil, classGrades);
			
			_lastRequest = [NSDate date];
		} else {
			/*
			 * Usually, the error here is "could not decode student id," which
			 * means we just have to log in again and hope everything works.
			 */
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^callbackFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
		NSLog(@"Class grade fetching error: %@", error);
	};
	
	// Set up the request
	NSURL *url = classGradesRequest[@"request"][@"URL"];
	
	if([classGradesRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:classGradesRequest[@"params"] andSuccessBlock:callbackSuccess andFailureBlock:callbackFailure];
	} else {
		callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		NSLog(@"Unsupported class grades fetching method: %@", classGradesRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Calls the login verification method on the district.
 *
 * @param callback: Callback block to execute to validate if the login was
 * successful or not.
 */
- (void) checkIfLoggedIn:(SQULoggedInCallback) callback {
	NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:_lastRequest];
	
	// If there's no last request time, force a login
	if(!_lastRequest) {
		// NSLog(@"No last request date available");
		callback(NO);
	} else if((diff > SQUDistrictManagerMaxRequestDelay)) {
		[_currentDistrict isLoggedInWithCallback:callback];
	} else {
		// NSLog(@"Delay not elapsed: assuming logged in (%f)", diff);
		callback(YES);
	}
}

/**
 * Returns the cycles that data is available for in a specific course.
 *
 * @param course: Course code to check for.
 * @return An array of NSNumbers of cycles that have data available.
 */
- (NSArray *) cyclesWithDataAvailableForCourse:(NSString *) course {
	return [_currentDistrict cyclesWithDataForCourse:course];
}

@end
