//
//  UserModel.h
//  Peach
//
//  Created by Lucy Wang on 4/28/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Firebase;

@interface UserModel : NSObject

@property (strong, nonatomic) NSDictionary* mUser;
@property (strong, nonatomic) FIRDatabaseReference *fbRef;
@property BOOL isLoggedIn;

+ (instancetype) sharedModel;
- (instancetype) init;
- (void) createUser:(NSDictionary*) result;
- (void) loadUser:(NSDictionary*) result;
- (NSDictionary* ) getUser;
- (BOOL) getIsLoggedIn;
- (void) setLoggedIn:(BOOL)loggedIn;

@end
