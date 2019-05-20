//
//  LMPayItem.h
//  PandoraLive
//
//  Created by LiMuyun on 2018/1/29.
//  Copyright © 2018年 ICSOFT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PayItem.h"
@interface LMPayWebView : UIView
+ (LMPayWebView *)shared;
@property (strong, nonatomic) NSString * reloadURL;
@property (strong, nonatomic) PayItem * payItem;

- (void)showInView:(UIView *)view;
- (void)paySucessedAlert;
@end
