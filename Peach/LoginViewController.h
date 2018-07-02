//
//  LoginViewController.h
//  Peach
//
//  Created by Lucy Wang on 4/18/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

typedef void(^CompletionHandler)(NSString *answer, NSString *question);

@interface LoginViewController : UIViewController<UITextFieldDelegate>

@property (copy, nonatomic) CompletionHandler completionHandler;


@end
