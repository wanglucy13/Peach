//
//  SignupViewController.h
//  Peach
//
//  Created by Lucy Wang on 4/18/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionHandler)(NSString *username, NSString *password);

@interface SignupViewController : UIViewController <UITextFieldDelegate>

@property (copy, nonatomic) CompletionHandler completionHandler;

@end
