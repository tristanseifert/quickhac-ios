//
//  SQULoginViewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SQULoginViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    UITableView *_authFieldTable;
    
    BOOL _tableMovedAlready;
    
    CALayer *_qLogo;
    CATextLayer *_qText;
    
    UITextField *_emailField;
    UITextField *_passField;
    
    UIButton *_loginButton;
    UIView *_loginButtonContainer;
}

@end
