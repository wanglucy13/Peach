//
//  FoodModel.h
//  Peach
//
//  Created by Lucy Wang on 4/30/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "FoodModel.h"

@implementation FoodModel

+ (instancetype) sharedModel{
    static FoodModel *foodModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        foodModel = [[FoodModel alloc] init];
    });
    
    return foodModel;
}

- (instancetype) init{
    self = [super init];
    
    if (self){
        
    }
    return self;
}

- (NSString* ) getNutritionOfItem : (NSString* ) itemName{
    //gets the data for the food 
    itemName = [itemName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *url = [NSString stringWithFormat:@"%@%@%@", @"https://api.nutritionix.com/v1_1/search/", itemName, @"?results=2:3&fields=item_name,nf_calories&appId=db6c1ceb&appKey=7e68cafaae67b392a3c5e2c922ab46aa"];
    
    NSError *error;
    NSString *url_string = [NSString stringWithFormat: @"%@", url];
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:url_string]];
    NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    self.name = [[[json valueForKey:@"hits"] valueForKey:@"fields"] valueForKey:@"item_name"][0];
    self.calories = [[[json valueForKey:@"hits"] valueForKey:@"fields"] valueForKey:@"nf_calories"][0];
    
    return self.calories;
}

- (NSString* ) getNameOfItem{
    return self.name;
}

- (NSString* ) getCaloriesOfItem{
    return self.name;
}



@end
