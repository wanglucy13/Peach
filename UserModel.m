//
//  UserModel.m
//  Peach
//
//  Created by Lucy Wang on 4/28/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "UserModel.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@implementation UserModel

+ (instancetype) sharedModel{
    static UserModel *userModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userModel = [[UserModel alloc] init];
    });
    
    return userModel;
}

- (instancetype) init{
    self = [super init];
    
    if (self){
        self.fbRef = [[FIRDatabase database] reference];
        
    }
    return self;
}

- (void) loadUser:(NSDictionary*) result{ //loads the user
    self.mUser = [result valueForKey:@"user"];
    self.isLoggedIn = YES;
}

- (NSDictionary* ) getUser
{
    return self.mUser;
}

//creates the user
- (void) createUser:(NSDictionary*) result{
    //calculating age
    NSDictionary* user;
    if([result objectForKey:@"id"])
    {
        //if its a facebook user creation
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        NSDate *birthday = [dateFormatter dateFromString:[result valueForKey:@"birthday"]];
        
        NSDate* now = [NSDate date];
        NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                           components:NSCalendarUnitYear
                                           fromDate:birthday
                                           toDate:now
                                           options:0];
        NSInteger age = [ageComponents year];
        
        
        //create the user dictionary to store into database
        user = @{@"name": [result valueForKey:@"name"],
                 @"email": [result valueForKey:@"email"],
                 @"birthday": [result valueForKey:@"birthday"],
                 @"age": [NSString stringWithFormat: @"%ld", age],
                 @"picture": [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=1000", [result valueForKey:@"id"]]
                 };
    }
    else
    {
        //create user if it's signup through peach
        user = @{@"name": [result valueForKey:@"name"],
                 @"email": [result valueForKey:@"email"],
                 @"birthday": [result valueForKey:@"birthday"],
                 @"age": [result valueForKey:@"age"],
                 @"picture": [result valueForKey:@"picture"]
                 };
    }
    self.mUser = user;
    [[[self.fbRef child:@"Users"] child:[FIRAuth auth].currentUser.uid] setValue:@{@"user": user}];
    self.isLoggedIn = YES;
}

- (BOOL) getIsLoggedIn{
    return self.isLoggedIn;
}

- (void) setLoggedIn:(BOOL)loggedIn{
    self.isLoggedIn = loggedIn;
}

@end
