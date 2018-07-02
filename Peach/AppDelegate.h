//
//  AppDelegate.h
//  Peatchy
//
//  Created by Lucy Wang on 4/17/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <ApiAI/ApiAI.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property(nonatomic, strong) ApiAI *apiAI;

- (void)saveContext;


@end

