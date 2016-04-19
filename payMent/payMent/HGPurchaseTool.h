////
////  HGPurchaseTool.h
////  Pinnacle
////
////  Created by qianjianeng on 15/12/23.
////  Copyright © 2015年 The Third Rock Ltd. All rights reserved.
////
//
#import <Foundation/Foundation.h>

@protocol HGPurchaseToolDelegate <NSObject>

@optional
- (void)success:(NSDictionary *)dic;
- (void)failure:(NSString *)error;

@end
@interface HGPurchaseTool : NSObject

+ (instancetype)sharedManager;

- (void)requestProductWithId:(NSNumber *)productID;
- (void)setOrder_number:(NSString *)order_number;
- (void)setCharge_action:(NSString *)charge_action;
@property (nonatomic, weak) id <HGPurchaseToolDelegate> delegate;
@end
