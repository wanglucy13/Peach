//
//  LoginViewController.m
//  Peach
//
//  Created by Lucy Wang on 4/18/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "LoginViewController.h"
#import "UserModel.h"
@import Firebase;

@interface LoginViewController () <FBSDKLoginButtonDelegate>
@property (weak, nonatomic) IBOutlet UIButton *peachLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) FIRDatabaseReference *fbRef;
@property (strong, nonatomic) FBSDKLoginButton *loginButton;
@property (strong, nonatomic) UserModel* userModel;



@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"peach_background.png"]];
    
    //setting up buttons and making them pretty
    self.loginButton = [[FBSDKLoginButton alloc] init];
    self.loginButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/4);
    [self.view addSubview:self.loginButton];
    self.loginButton.delegate = self;
    self.loginButton.readPermissions = @[@"public_profile", @"email"];
    
    self.userModel = [UserModel sharedModel];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in, do work such as go to next view controller.
        [self performSegueWithIdentifier:@"showChat" sender:self];

    }
    
    self.fbRef = [[FIRDatabase database] reference];
    
    self.peachLoginButton.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:0.5];
    self.peachLoginButton.layer.cornerRadius = 10.0f;
    
    self.cancelButton.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:0.5];
    self.cancelButton.layer.cornerRadius = 10.0f;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    //if regular login button pressed
    [[FIRAuth auth] signInWithEmail:self.emailTextField.text
                           password:self.passwordTextField.text
                         completion:^(FIRUser * _Nullable user,
                                      NSError * _Nullable error) {
                             if(error)
                             {
                                 [self showAlert:[error localizedDescription]];
                             }
                             else
                             {
                                 //if a user exists
                                 NSString *userID = [FIRAuth auth].currentUser.uid;
                                 [[[self.fbRef child:@"Users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                     
                                     if(snapshot.value)
                                     {
                                         [self.userModel loadUser:snapshot.value];
                                         [self performSegueWithIdentifier:@"showChat" sender:self];
                                     }
                                     else
                                     {
                                         // else there is no user under this id so must create new one
                                         [self showAlert:[error localizedDescription]];
                                     }

                                     
                                 } withCancelBlock:^(NSError * _Nonnull error) {
                                     NSLog(@"%@", error.localizedDescription);
                                 }];
                             }
                         }];
}

- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

// log in through facebook
- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error{
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
                                      NSString *userID = [FIRAuth auth].currentUser.uid;
                                      [[[self.fbRef child:@"Users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * snapshot) {
                                          NSLog(@"%@", userID);
                                          NSLog(@"%@", snapshot);
                                          //if there exists a user with this facebook id then load the user
                                          if(snapshot.value)
                                          {
                                              [self.userModel loadUser:snapshot.value];
                                              [self performSegueWithIdentifier:@"showChat" sender:self];
                                          }
                                          else
                                          {
                                              // else there is no user under this id so must create new one
                                              [self showAlert:@"No Facebook user found\nPlease create an account."];
                                              [self loginButtonDidLogOut:self.loginButton];
                                          }
                                      } withCancelBlock:^(NSError * _Nonnull error) {
                                          NSLog(@"%@", error.localizedDescription);
                                      }];
                                  }
                              }];
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
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
   
}
*/


@end
