//
//  HGPurchaseTool.m
//  Pinnacle
//
//  Created by qianjianeng on 15/12/23.
//  Copyright © 2015年 The Third Rock Ltd. All rights reserved.
//
//
#import "HGPurchaseTool.h"
#import <StoreKit/StoreKit.h>
#import "PXAlertView.h"
#import "SVProgressHUD.h"
#import "SVProgressHUD.h"
@interface HGPurchaseTool ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>

@property (nonatomic, copy) NSString *productID;
@property (nonatomic, copy) NSString *order_number;
@property (nonatomic, copy) NSString *charge_action;
@end

@implementation HGPurchaseTool

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static HGPurchaseTool *_sInstance;
    dispatch_once(&onceToken, ^{
        _sInstance = [[HGPurchaseTool alloc] init];
    });
    
    return _sInstance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (NSString *)shopIdWithProductId:(NSNumber *)productId
{
    NSInteger number = [productId integerValue];
    switch (number) {
        case 1:
            return @"zengzhifuwu1";
            break;
        case 2:
            return @"zengzhifuwu1";
            break;
        case 3:
            return @"zengzhifuwu1";
            break;
        case 4:
            return @"zengzhifuwu1";
            break;
        case 5:
            return @"zengzhifuwu1";
            break;
        default:
            return @"zengzhifuwu1";
            break;
    }
}

- (void)setOrder_number:(NSString *)order_number
{
    _order_number = order_number;
}
- (void)setCharge_action:(NSString *)charge_action
{
    _charge_action = charge_action;
}
- (void)requestProductWithId:(NSNumber *)productID
{
    [SVProgressHUD show];
    if ([self isJailbroken]) {
        
        [PXAlertView showAlertWithTitle:@"越狱设备不能进行充值" message:@"温馨提示"];
        return;
    }
    _productID = [self shopIdWithProductId:productID];
    
    if([SKPaymentQueue canMakePayments]){
        [self requestProductArr:@[_productID]];
    }else{
        
        [PXAlertView showAlertWithTitle:@"不允许程序内付费" message:@"温馨提示"];
    }
    
}

//请求商品
- (void)requestProductArr:(NSArray *)arr{
    
    //NSLog(@"-------------请求对应的产品信息----------------");
    NSSet *nsset = [NSSet setWithArray:arr];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
    
}

//收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    //NSLog(@"--------------收到产品反馈消息---------------------");
    NSArray *product = response.products;
    if([product count] == 0){
        //NSLog(@"--------------没有商品------------------");

        [PXAlertView showAlertWithTitle:@"没有请求到数据，请稍后再试" message:@"温馨提示" ];

        return;
    }
    
    //NSLog(@"productID:%@", response.invalidProductIdentifiers);
    //NSLog(@"产品付费数量:%ld",(long)[product count]);
    
    for (SKProduct *pro in product) {
//        NSLog(@"%@", [pro description]);
//        NSLog(@"%@", [pro localizedTitle]);
//        NSLog(@"%@", [pro localizedDescription]);
//        NSLog(@"%@", [pro price]);
//        NSLog(@"%@", [pro productIdentifier]);
        
        if([pro.productIdentifier isEqualToString:_productID]){

            
        SKPayment *payment = [SKPayment paymentWithProduct:pro];
            
            //NSLog(@"把商品放入购买队列");
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    
    
}

//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    [SVProgressHUD dismiss];
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
                NSLog(@"transactionIdentifier = %@", transaction.transactionIdentifier);
                [self completeTransaction:transaction];
                NSLog(@"交易完成");
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self failedTransaction:transaction];
                NSLog(@"交易失败");
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                NSLog(@"已经购买过商品");
                break;
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
                NSLog(@"商品添加进列表");
                break;
            default:
                break;
        }
    }
}


- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    [SVProgressHUD showWithStatus:@"Generating orders..."];
    NSString * productIdentifier = transaction.payment.productIdentifier;
    
    //NSString * receipt = [transaction.transactionReceipt base64EncodedDataWithOptions:0];
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (!_order_number || !transaction || !receiptURL) {
        return;
    }
    [dict setObject:_order_number forKey:@"order_number"];
    if (_charge_action.length > 0) {
        [dict setObject:_charge_action forKey:@"charge_action"];
    }
    
    [dict setObject:[receipt base64EncodedStringWithOptions:0] forKey:@"transfer_token"];
    [dict setObject:@"f07be5e08fad4eeb8864542549129645" forKey:@"password"];
    if ([productIdentifier length] > 0) {
        __weak __typeof(self)weakSelf = self;
        
        [[HGAppData sharedInstance].userApiClient FIVEMILES_POST:USER_CLIENT_USER_PAYMENT parameters:dict success:^(NSURLSessionDataTask *task, id responseObject) {
            
            [SVProgressHUD dismiss];
            if ([weakSelf.delegate respondsToSelector:@selector(success:)]) {
                [weakSelf.delegate success:(NSDictionary *)responseObject];
            }
            // Remove the transaction from the payment queue.
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [SVProgressHUD dismiss];
            if ([weakSelf.delegate respondsToSelector:@selector(failure:)]) {
                [weakSelf.delegate failure:@"buyError"]; //如果到这里，苹果内购成功，生成订单失败
            }
            //NSLog(@"get me(%@) likes failed:%@", [HGUserData sharedInstance].fmUserID, error.userInfo);
        }];

        
        
        
    }
    
    
}





- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"购买失败-%@", transaction.error.userInfo);
        NSDictionary *dict = transaction.error.userInfo;
        
        NSString *error = [dict valueForKey:@"NSLocalizedDescription"];
        if ([self.delegate respondsToSelector:@selector(failure:)]) {
            [self.delegate failure:error];
        }
    } else {
        NSLog(@"用户取消交易");
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    [SVProgressHUD dismiss];
   // NSLog(@"------------------错误-----------------:%@", error);
}

- (void)requestDidFinish:(SKRequest *)request{
    
    [SVProgressHUD dismiss];
   // NSLog(@"------------请求商品反馈信息结束-----------------");
}


- (BOOL)isJailbroken {
    
    FILE *f = fopen("/bin/bash", "r");
    BOOL isJailbroken = NO;
    if (f != NULL)
        isJailbroken = YES;
    else
        isJailbroken = NO;
    
    fclose(f);
    
    return isJailbroken;
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    
}



#pragma mark - 本地二次验证
- (void)checkInappStore:(NSData *)repit
                success:(void (^)(NSDictionary *response, NSString *message))successBlock
                failure:(void (^)(NSInteger errorCode, NSString *message, NSDictionary *response))failureBlock
{
    NSString *test = @"https://sandbox.itunes.apple.com/verifyReceipt";
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:repit forKey:@"receipt-data"];
    [dic setObject:@"1ef3ecc8844f4f35a82a9a82ff59d806" forKey:@"password"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer.timeoutInterval = 100.0;
    
    [manager POST:test parameters:dic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
    
}



@end
