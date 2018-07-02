//
//  FoodModel.h
//  Peach
//
//  Created by Lucy Wang on 4/30/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FoodModel : NSObject
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* calories;



+ (instancetype) sharedModel;
- (instancetype) init;
- (NSString* ) getNutritionOfItem: (NSString* ) itemName;
- (NSString* ) getNameOfItem;
- (NSString* ) getCaloriesOfItem;


@end
