//
//  MenuViewController.m
//  Peach
//
//  Created by Lucy Wang on 5/3/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "MenuViewController.h"
#import "UserModel.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface MenuViewController () <FBSDKLoginButtonDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) UserModel* user;
@property (strong, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthdayLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.user = [UserModel sharedModel];
    
    [self.pictureImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapping:)];
    [singleTap setNumberOfTapsRequired:1];
    [self.pictureImageView addGestureRecognizer:singleTap];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"peach_background.png"]];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in add button and such
        FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
        loginButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/1.2);
        [self.view addSubview:loginButton];
        loginButton.delegate = self;
    }
    else
    {
        //if its a peach log in, create custom log out button
        UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(210, 285, 200, 50)];
        [logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
        logoutButton.titleLabel.font = [UIFont fontWithName:@"Raleway" size:20];
        logoutButton.titleLabel.textColor = [UIColor whiteColor];
        logoutButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/1.2);
        logoutButton.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:0.5];
        logoutButton.layer.cornerRadius = 10.0f;
        [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:logoutButton];
    }
    
    [self configureLabels];
}

-(void)singleTapping:(UIGestureRecognizer *)recognizer {
    //for selecting a new image
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];

    NSLog(@"image clicked");
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //Or you can get the image url from AssetsLibrary
    NSURL *path = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSLog(@"%@", path);
    [self.pictureImageView setImage:image];
//    [self.user updateImage:path];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    //log out of fb
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    else
    {
        [self.user setLoggedIn:NO];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)logout{
    [self.user setLoggedIn:NO];
    [self.navigationController popToRootViewControllerAnimated:YES];
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

- (void) configureLabels
{
    //create the labels for initial view load
    NSDictionary* dict = [self.user getUser];
    self.nameLabel.text = [dict valueForKey:@"name"];
    self.emailLabel.text = [dict valueForKey:@"email"];
    self.birthdayLabel.text = [dict valueForKey:@"birthday"];
    self.ageLabel.text = [dict valueForKey:@"age"];
    
    if(![[dict valueForKey:@"picture"] isEqualToString:@""])
    {
        NSURL *url = [NSURL URLWithString:[dict valueForKey:@"picture"]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        [self.pictureImageView setImage:image];
    }
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
