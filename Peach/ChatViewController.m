//
//  ChatViewController.m
//  Peach
//
//  Created by Lucy Wang on 4/20/17.
//  Copyright © 2017 Yi Wang. All rights reserved.
//

#import "ChatViewController.h"
#import "LoginViewController.h"
#import "ApiAI/ApiAI.h"
#import "FoodModel.h"
#import "UserModel.h"

@interface ChatViewController ()

@property (weak, nonatomic) NSMutableArray* messages;
@property (weak, nonatomic) ApiAI* apiai;
@property (weak, nonatomic) FoodModel* foodModel;
@property (strong, nonatomic) UserModel* userModel;

@end

NS_ENUM(NSUInteger, QMMessageType) {
    QMMessageTypeText = 0,
    QMMessageTypeCreateGroupDialog = 1,
    QMMessageTypeUpdateGroupDialog = 2,
    
    QMMessageTypeContactRequest = 4,
    QMMessageTypeAcceptContactRequest,
    QMMessageTypeRejectContactRequest,
    QMMessageTypeDeleteContactRequest
};

@implementation ChatViewController

- (NSTimeInterval)timeIntervalBetweenSections {
    return 300.0f;
}

- (CGFloat)heightForSectionHeader {
    return 40.0f;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"peach_background.png"]];
    
    self.foodModel = [FoodModel sharedModel];
    
    self.userModel = [UserModel sharedModel];

    
    self.senderID = 2000;
    self.senderDisplayName = @"user1";
    
    [QBSettings setAuthKey:@"xxx"];
    [QBSettings setAccountKey:@"xxx"];
    
    QBChatMessage *welcomeMessage = [QBChatMessage message];
    welcomeMessage.senderID = QMMessageTypeText;
    welcomeMessage.text = @"Welcome to Peach! What did you eat today?";
    welcomeMessage.dateSent = [NSDate dateWithTimeInterval:-12.0f sinceDate:[NSDate date]];
    
    self.apiai = [ApiAI sharedApiAI];

    [self.chatDataSource addMessages:@[welcomeMessage]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(![self.userModel getIsLoggedIn])
    {
//        [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    
}

#pragma mark Tool bar Actions
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSUInteger)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    
    QBChatMessage *message = [QBChatMessage message];
    message.text = text;
    message.senderID = senderId;
    message.dateSent = [NSDate date];
    
    [self.chatDataSource addMessage:message];

    AITextRequest *request = [self.apiai textRequest];
    request.query = @[message.text];
    [request setCompletionBlockSuccess:^(AIRequest *request, AIResponse* response) {
        // Handle success ...
        QBChatMessage *responseMessage = [QBChatMessage message];
        if([[[[response valueForKey:@"result"] valueForKey:@"metadata"] valueForKey:@"intentName"] isEqual: @"drink"] || [[[[response valueForKey:@"result"] valueForKey:@"metadata"] valueForKey:@"intentName"] isEqual: @"food"])
            {
                NSDictionary* parameters = [[response valueForKey:@"result"] valueForKey:@"parameters"];
                if([parameters count] == 1)
                {
                    NSString* message = [[[response valueForKey:@"result"] valueForKey:@"fulfillment"] valueForKey:@"speech"];
                    NSString* item;
                    if([[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"food"] != nil)
                    {
                        item = [[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"food"];
                    }
                    else
                    {
                        item = [[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"drink"];
                        
                    }
                    NSString* nutrition = [self.foodModel getNutritionOfItem:item];
                    responseMessage.text = [NSString stringWithFormat:@"%@ (%@) %@ %@ %@", message, [self.foodModel getNameOfItem], @"contains", nutrition, @"calories."];
                    responseMessage.dateSent = [NSDate date];
                    responseMessage.senderID = 1;
                    [self.chatDataSource addMessage:responseMessage];
                }
                else
                {
                    NSLog(@"%@", parameters);
                    for(id key in parameters)
                    {
                        AITextRequest *tRequest = [self.apiai textRequest];
                        tRequest.query = @[[parameters valueForKey:key]];
                        QBChatMessage *responseMessage = [QBChatMessage message];
                        [tRequest setCompletionBlockSuccess:^(AIRequest *request, AIResponse* response) {
                            NSString* message = [[[response valueForKey:@"result"] valueForKey:@"fulfillment"] valueForKey:@"speech"];
                            NSString* item;
                            if([[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"food"] != nil)
                            {
                                item = [[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"food"];
                            }
                            else
                            {
                                item = [[[response valueForKey:@"result"] valueForKey:@"parameters"] valueForKey: @"drink"];
                                
                            }
                            NSString* nutrition = [self.foodModel getNutritionOfItem:item];
                            responseMessage.text = [NSString stringWithFormat:@"%@ (%@) %@ %@ %@", message, [self.foodModel getNameOfItem], @"contains", nutrition, @"calories."];
                            responseMessage.dateSent = [NSDate date];
                            responseMessage.senderID = 1;
                            [self.chatDataSource addMessage:responseMessage];
                        } failure:^(AIRequest *request, NSError *error) {
                            // Handle error ...
                        }];
                        [self.apiai enqueue:tRequest];
                    }
                }
           }
        else
        {
            NSString* message = [[[response valueForKey:@"result"] valueForKey:@"fulfillment"] valueForKey:@"speech"];
            responseMessage.text = message;
            responseMessage.dateSent = [NSDate date];
            responseMessage.senderID = 1;
            [self.chatDataSource addMessage:responseMessage];

        }
    } failure:^(AIRequest *request, NSError *error) {
        // Handle error ...
    }];
    
    [self.apiai enqueue:request];
    
    [self finishSendingMessageAnimated:YES];
}


- (Class)viewClassForItem:(QBChatMessage *)item {
    
    if (item.senderID == QMMessageTypeContactRequest) {
        
        if (item.senderID != self.senderID) {
            
            return [QMChatContactRequestCell class];
        }
    }
    
    else if (item.senderID == QMMessageTypeRejectContactRequest) {
        
        return [QMChatNotificationCell class];
    }
    
    else if (item.senderID == QMMessageTypeAcceptContactRequest) {
        
        return [QMChatNotificationCell class];
    }
    else {
        
        if (item.senderID != self.senderID) {
            if ((item.attachments != nil && item.attachments.count > 0)) {
                return [QMChatAttachmentIncomingCell class];
            } else {
                return [QMChatIncomingCell class];
            }
        } else {
            if ((item.attachments != nil && item.attachments.count > 0)) {
                return [QMChatAttachmentOutgoingCell class];
            } else {
                return [QMChatOutgoingCell class];
            }
        }
    }
    
    return nil;
}

- (CGSize)collectionView:(QMChatCollectionView *)collectionView dynamicSizeAtIndexPath:(NSIndexPath *)indexPath maxWidth:(CGFloat)maxWidth {
    
    QBChatMessage *item = [self.chatDataSource messageForIndexPath:indexPath];
    Class viewClass = [self viewClassForItem:item];
    CGSize size;
    
    if (viewClass == [QMChatAttachmentIncomingCell class] || viewClass == [QMChatAttachmentOutgoingCell class]) {
        size = CGSizeMake(MIN(200, maxWidth), 200);
    } else {
        NSAttributedString *attributedString = [self attributedStringForItem:item];
        
        size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString
                                                withConstraints:CGSizeMake(maxWidth, MAXFLOAT)
                                         limitedToNumberOfLines:0];
    }
    
    return size;
}

- (CGFloat)collectionView:(QMChatCollectionView *)collectionView minWidthAtIndexPath:(NSIndexPath *)indexPath {
    
    QBChatMessage *item = [self.chatDataSource messageForIndexPath:indexPath];
    
    CGSize size;
    
    if (item != nil) {
        
        NSAttributedString *attributedString =
        [item senderID] == self.senderID ?  [self bottomLabelAttributedStringForItem:item] : [self topLabelAttributedStringForItem:item];
        
        size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString
                                                withConstraints:CGSizeMake(1000, 10000)
                                         limitedToNumberOfLines:1];
    }
    
    return size.width;
}

- (void)collectionView:(QMChatCollectionView *)collectionView configureCell:(UICollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    
    if ([cell conformsToProtocol:@protocol(QMChatAttachmentCell)]) {
        QBChatMessage* message = [self.chatDataSource messageForIndexPath:indexPath];
        
        if (message.attachments != nil) {
            QBChatAttachment* attachment = message.attachments.firstObject;
            NSData *imageData = [NSData dataWithContentsOfFile:attachment.url];
            [(UICollectionViewCell<QMChatAttachmentCell> *)cell setAttachmentImage:[UIImage imageWithData:imageData]];
            
            [cell updateConstraints];
        }
    }
    
    [super collectionView:collectionView configureCell:cell forIndexPath:indexPath];
}

- (QMChatCellLayoutModel)collectionView:(QMChatCollectionView *)collectionView layoutModelAtIndexPath:(NSIndexPath *)indexPath {
    
    QMChatCellLayoutModel layoutModel = [super collectionView:collectionView layoutModelAtIndexPath:indexPath];
    QBChatMessage *item = [self.chatDataSource messageForIndexPath:indexPath];
    
    layoutModel.avatarSize = CGSizeMake(0.0f, 0.0f);
    
    if (item!= nil) {
        
        NSAttributedString *topLabelString = [self topLabelAttributedStringForItem:item];
        CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:topLabelString
                                                       withConstraints:CGSizeMake(CGRectGetWidth(self.collectionView.frame), CGFLOAT_MAX)
                                                limitedToNumberOfLines:1];
        layoutModel.topLabelHeight = size.height;
    }
    
    return layoutModel;
}

- (NSAttributedString *)attributedStringForItem:(QBChatMessage *)messageItem {
    
    UIColor *textColor = [messageItem senderID] == self.senderID ? [UIColor whiteColor] : [UIColor colorWithWhite:0.290 alpha:1.000];
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:15];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor,
                                 NSFontAttributeName : font};
    
    NSMutableAttributedString *attrStr;
    
    if ([messageItem.text length] > 0) {
        
        attrStr = [[NSMutableAttributedString alloc] initWithString:messageItem.text attributes:attributes];
    }
    
    return attrStr;
}

- (NSAttributedString *)topLabelAttributedStringForItem:(QBChatMessage *)messageItem {
    
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:14];
    
    if ([messageItem senderID] == self.senderID) {
        return nil;
    }
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName:[UIColor colorWithRed:0.184 green:0.467 blue:0.733 alpha:1.000], NSFontAttributeName:font};
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"Peach" attributes:attributes];
    
    return attrStr;
}

- (NSAttributedString *)bottomLabelAttributedStringForItem:(QBChatMessage *)messageItem {
    
    UIColor *textColor = [messageItem senderID] == self.senderID ? [UIColor colorWithWhite:1.000 alpha:0.510] : [UIColor colorWithWhite:0.000 alpha:0.490];
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:12];
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName:textColor, NSFontAttributeName:font};
    NSMutableAttributedString *attrStr =
    [[NSMutableAttributedString alloc] initWithString:[self timeStampWithDate:messageItem.dateSent]
                                           attributes:attributes];
    
    return attrStr;
}

- (NSString *)timeStampWithDate:(NSDate *)date {
    
    static NSDateFormatter *dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm";
    });
    
    NSString *timeStamp = [dateFormatter stringFromDate:date];
    
    return timeStamp;
}

- (UIImage *)resizedImageFromImage:(UIImage *)image
{
    CGFloat largestSide = image.size.width > image.size.height ? image.size.width : image.size.height;
    CGFloat scaleCoefficient = largestSide / 560.0f;
    CGSize newSize = CGSizeMake(image.size.width / scaleCoefficient, image.size.height / scaleCoefficient);
    
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:(CGRect){0, 0, newSize.width, newSize.height}];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

- (IBAction)menuBarButtonPressed:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"showMenu" sender:sender];
}

/*
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
 }

*/
@end
