//
//  SignupViewController.m
//  Peach
//
//  Created by Lucy Wang on 4/18/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "SignupViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "UserModel.h"
@import Firebase;


@interface SignupViewController () <FBSDKLoginButtonDelegate>
@property (weak, nonatomic) IBOutlet UIButton *peachSignupButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *ageTextField;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) FIRDatabaseReference *fbRef;
@property (strong, nonatomic) UserModel* userModel;
@property (strong, nonatomic) UIDatePicker *datePicker;



@end

#define kOFFSET_FOR_KEYBOARD 80.0

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [IQKeyboardManager sharedManager].enable = YES;
    
    self.userModel = [UserModel sharedModel];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"peach_background.png"]];
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/5);
    [self.view addSubview:loginButton];
    loginButton.delegate = self;
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_birthday"];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in, do work such as go to next view controller.
        [self performSegueWithIdentifier:@"showChat" sender:self];
    }
    
    self.fbRef = [[FIRDatabase database] reference];
    
    self.cancelButton.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:0.5];
    self.cancelButton.layer.cornerRadius = 10.0f;
    
    self.peachSignupButton.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:0.5];
    self.peachSignupButton.layer.cornerRadius = 10.0f;
    
    // make the textfield its own delegate
    self.birthdayTextField.delegate = self;
    // alloc/init your date picker, and (optional) set its initial date
    self.datePicker = [[UIDatePicker alloc]init];
    [self.datePicker setDate:[NSDate date]]; //this returns today's date
    
    // set the mode
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    
    // update the textfield with the date everytime it changes with selector defined below
    [self.datePicker addTarget:self action:@selector(updateBirthdayTextField) forControlEvents:UIControlEventValueChanged];
    
    // and finally set the datePicker as the input mode of your textfield
    [self.birthdayTextField setInputView:self.datePicker];
    
}

- (void) updateBirthdayTextField
{
    UIDatePicker *picker = (UIDatePicker*)self.birthdayTextField.inputView;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *formattedDate = [dateFormatter stringFromDate:picker.date];
    self.birthdayTextField.text = formattedDate;
}

- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    
    }];
}

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error{
    //signup through facebook
    FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                     credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                     .tokenString];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRUser *user, NSError *error) {
                                  // ...
                                  if (error) {
                                      [self showAlert:[error localizedDescription]];
                                      return;
                                  }
                                  else
                                  {
                                      //get fb parameters for the user
                                      NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
                                      [parameters setValue:@"id,name,email,birthday" forKey:@"fields"];
                                      [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
                                       startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                           if (!error) {
                                               NSLog(@"%@", result);
                                               [self.userModel createUser:result];
                                           }
                                       }];
                                      [self performSegueWithIdentifier:@"showChat" sender:self];
                                  }
                              }];
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    //log out of facbeook
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    else{
        [self.userModel setLoggedIn:NO];
    }
}


- (IBAction)signupButtonPressed:(UIButton *)sender {
    //if the user presses the signup button, create a new user in the usermodel and move to the chat view
    if([self passwordsMatch]) {
        [[FIRAuth auth] createUserWithEmail:self.emailTextField.text
                        password:self.passwordTextField.text
                        completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                            if(error)
                            {
                                [self showAlert:[error localizedDescription]];
                            }
                            else
                            {
                                NSDictionary* result = @{@"name": self.nameTextField.text,
                                                          @"email": self.emailTextField.text,
                                                          @"birthday": self.birthdayTextField.text,
                                                          @"age": self.ageTextField.text,
                                                          @"picture": @""
                                                          };
                                [self.userModel createUser:result];
                                [self performSegueWithIdentifier:@"showChat" sender:self];
                            }
         }];
    }
    else {
        [self showAlert:@"Passwords do not match!"];
    }
}

- (bool)passwordsMatch { //checks if passwords match
    return self.passwordTextField.text == self.confirmPasswordTextField.text;
}

-(void) showAlert:(NSString*) error {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Error!"
                                          message:error
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK clicked");
                               }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


/*
 #pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
