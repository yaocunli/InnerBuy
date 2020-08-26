//
//  ViewController.m
//  afafa
//


#import "ViewController.h"
#import <PassKit/PassKit.h>
#import <AddressBook/AddressBook.h>
#import <PassKit/PKAddPaymentPassViewController.h>

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)buttonClicked:(id)sender {
    [self clickBuy];
}

#pragma mark - 检测环境
-(void)checkEnvironment
{
    if (![PKPaymentAuthorizationViewController class]) {
        //PKPaymentAuthorizationViewController需iOS8.0以上支持
        NSLog(@"操作系统不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return;
    }
    //检查当前设备是否可以支付
    if (![PKPaymentAuthorizationViewController canMakePayments]) {
        //支付需iOS9.0以上支持
        NSLog(@"设备不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return;
    }
    //检查用户是否可进行某种卡的支付，是否支持Amex、MasterCard、Visa与银联四种卡，根据自己项目的需要进行检测
    NSArray *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard,PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay];
    if (![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
        NSLog(@"没有绑定支付卡");
        // 如果没有添加银行卡，创建一个跳转按钮，跳转到添加银行卡的界面
        PKPaymentButton *button=[PKPaymentButton buttonWithType:PKPaymentButtonTypeSetUp style:PKPaymentButtonStyleWhiteOutline];
        button.center=self.view.center;
        [self.view addSubview:button];
        [button addTarget:self action:@selector(jumpAddBank) forControlEvents:UIControlEventTouchUpInside];
        
        return;
    }
}

-(void)clickBuy
{
    [self checkEnvironment];
    
    // 1、创建一个支付请求
    PKPaymentRequest *request=[[PKPaymentRequest alloc]init];
    // 配置支付请求
    //1.1 配置商家ID
    request.merchantIdentifier=@"merchant.com.example";
    
    //1.2 配置国家代码，以及货币代码
    request.countryCode=@"CN";
    request.currencyCode=@"CNY";
    
    
    //送货地址信息，这里设置需要地址和联系方式和姓名，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
    // 1.5 配置购买价格详细
    
    // 12.75 subtotal
    NSDecimalNumber *subtotalAmount = [NSDecimalNumber decimalNumberWithMantissa:1275
                                                                        exponent:-2 isNegative:NO];
    PKPaymentSummaryItem *subtotal = [PKPaymentSummaryItem summaryItemWithLabel:@"小计" amount:subtotalAmount];
    
    // 2.00 discount
    NSDecimalNumber *discountAmount = [NSDecimalNumber decimalNumberWithMantissa:200 exponent:-2 isNegative:YES];
    PKPaymentSummaryItem *discount = [PKPaymentSummaryItem summaryItemWithLabel:@"折扣" amount:discountAmount];
    
    // 12.75 - 2.00 = 10.75 grand total
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    totalAmount = [totalAmount decimalNumberByAdding:subtotalAmount];
    totalAmount = [totalAmount decimalNumberByAdding:discountAmount];
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"test回天无力公司" amount:totalAmount];
    request.paymentSummaryItems = @[subtotal,discount,total];
    
    //设置配送方式
    NSDecimalNumber *freeAmount = [NSDecimalNumber decimalNumberWithString:@"0.00"];
    PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"Free Shipping" amount:freeAmount];
    freeShipping.detail = @"Arrives by July 2";
    freeShipping.identifier = @"free";
    
    NSDecimalNumber *standardAmount = [NSDecimalNumber decimalNumberWithString:@"3.21"];
    PKShippingMethod *standardShipping = [PKShippingMethod summaryItemWithLabel:@"Standard Shipping" amount:standardAmount];
    standardShipping.detail = @"Arrives by June 29";
    standardShipping.identifier = @"standard";
    
    NSDecimalNumber *expressAmount = [NSDecimalNumber decimalNumberWithString:@"24.63"];
    PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"Express Shipping" amount:expressAmount];
    expressShipping.detail = @"Ships within 24 hours";
    expressShipping.identifier = @"express";
    
    request.shippingMethods = @[freeShipping, standardShipping, expressShipping];
    
    // 1.3 支付的银行卡
    request.supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkDiscover, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
    // 1.4配置商户的处理方式//设置支持的交易处理协议，3DS必须支持，EMV为可选，目前国内的话还是使用两者吧
    request.merchantCapabilities=PKMerchantCapability3DS|PKMerchantCapabilityEMV;
    
    //如果需要邮寄账单可以选择进行设置，默认PKAddressFieldNone(不邮寄账单)
    //楼主感觉账单邮寄地址可以事先让用户选择是否需要，否则会增加客户的输入麻烦度，体验不好
    request.requiredBillingAddressFields = PKAddressFieldEmail;
    request.requiredShippingAddressFields = PKAddressFieldPostalAddress|PKAddressFieldPhone|PKAddressFieldName;
    
    //
//    PKContact *contact = [[PKContact alloc] init];
//
//    NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
//    name.givenName = @"John";
//    name.familyName = @"Appleseed";
//
//    contact.name = name;
//
//    CNMutablePostalAddress *address = [[CNMutablePostalAddress alloc] init];
//    address.street = @"1234 Laurel Street";
//    address.city = @"Atlanta";
//    address.state = @"GA";
//    address.postalCode = @"30303";
//
//    contact.postalAddress = address;
//
//    request.shippingContact = contact;
    
    //显示购物信息并进行支付
    PKPaymentAuthorizationViewController *PayVC=[[PKPaymentAuthorizationViewController alloc]initWithPaymentRequest:request];
    if (!PayVC) {
        return;
    }
    PayVC.delegate=self;
    [self presentViewController:PayVC animated:YES completion:nil];
    
}

#pragma mark  -代理方法

- (void) paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingContact:(CNContact *)contact
                                 completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *, NSArray *))completion
{
//    self.selectedContact = contact;
//    [self updateShippingCost];
//    NSArray *shippingMethods = [self shippingMethodsForContact:contact];
//    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, self.summaryItems);
}

- (void) paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                    didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                 completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *))completion
{
//    self.selectedShippingMethod = shippingMethod;
//    [self updateShippingCost];
//    completion(PKPaymentAuthorizationStatusSuccess, self.summaryItems);
}

//支付卡选择回调
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod handler:(void (^)(PKPaymentRequestPaymentMethodUpdate * _Nonnull))completion
API_AVAILABLE(ios(11.0)){
    NSLog(@"%@", paymentMethod);
}

//如果当用户授权成功，就会调用这个方法
/*
 参数一:授权控制器
 参数二：支付对象
 参数三:系统给定的一个回调代码块，我们需要执行这个代码块，来告诉系统当前的的支付状态是否成功
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion
{
    
    NSLog(@"token=%@",payment.token);
    //拿到支付信息，发送给服务器处理，处理完毕之后，服务器返回一个状态，告诉客户端，是否支付成功，然后由客户端进行处理
    PKPaymentToken *payToken = payment.token;
    //支付凭据，发给服务端进行验证支付是否真实有效
    PKContact *billingContact = payment.billingContact;     //账单信息
    PKContact *shippingContact = payment.shippingContact;   //送货信息
    PKContact *shippingMethod = payment.shippingMethod;     //送货方式
    
    BOOL isSuccess=YES;
    if (isSuccess)
        {
        completion(PKPaymentAuthorizationStatusSuccess);
        }
    else
        {
        completion(PKPaymentAuthorizationStatusFailure);
        }
}

// 当用户授权成功，或者取消授权时调用
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 添加银行卡界面
-(void)jumpAddBank
{
    // 跳转到添加银行卡界面
    PKPassLibrary *pl=[[PKPassLibrary alloc]init];
    
    [pl openPaymentSetup];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
