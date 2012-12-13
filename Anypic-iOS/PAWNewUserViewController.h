//
//  PAWNewUserViewController.h
//  AnyWall
//
//  Created by Christopher Bowns on 2/1/12.
//  Copyright (c) 2012 Parse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAPEditPhotoViewController.h"

@interface PAWNewUserViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UITextField *passwordAgainField;
@property (nonatomic, strong) IBOutlet UIImageView *profileImageCaptureButton;
@property (nonatomic, strong) IBOutlet UIImage *profileImage;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
