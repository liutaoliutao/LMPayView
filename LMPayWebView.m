//
//  LMPayItem.m
//  PandoraLive
//
//  Created by LiMuyun on 2018/1/29.
//  Copyright © 2018年 ICSOFT. All rights reserved.
//

#import "LMPayWebView.h"
#import <WebKit/WebKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <AppsFlyerLib/AppsFlyerTracker.h>
#import "SFRechargeManager.h"
@import Firebase;
static LMPayWebView * instance = nil;
@interface LMPayWebView ()<WKNavigationDelegate>
@property (strong, nonatomic) WKWebView * webView;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton * closeButton;
@end

@implementation LMPayWebView
+ (LMPayWebView *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMPayWebView alloc] init];
    });
    return instance;
}
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    if (self) {
        self.backgroundColor = RGBA(0, 0, 0, 0.8);
        CGFloat top = self.safeInserts.top;
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, top, SCREEN_WIDTH-20, 2)];
        _progressView.trackTintColor = Main_Gray_Color;
        _progressView.progressTintColor = [UIColor blueColor];
        [self addSubview:_progressView];
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(20, top+10, 40, 40)];
        [_closeButton setImage:[UIImage imageNamed:@"anchor_detail_navigation_back"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeCon:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];
    }
    return self;
}
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:SCREEN_BOUNDS];
        _webView.backgroundColor = Main_Gray_Color;
        _webView.opaque = NO;
        _webView.navigationDelegate = self;
    }
    return _webView;
}
- (void)closeCon:(UIButton *)sender {
    [self webViewHidden];
}
- (void)wkWebViewRequestUrl:(NSString *)url {
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    //    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    request.HTTPShouldHandleCookies = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [_webView loadRequest:request];
    [_progressView setProgress:0.1 animated:YES];
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        BOOL loadFinish = _webView.estimatedProgress == 1.0;
        _progressView.hidden = loadFinish;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = !loadFinish;
        [_progressView setProgress:_webView.estimatedProgress];
    }
}
#pragma mark - WKNavigationDelegate 页面跳转
#pragma mark 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL * url = navigationAction.request.URL;
    LSLog(@"即将跳转：%@",url.absoluteString);
    if ([url.absoluteString rangeOfString:@"p/s"].location != NSNotFound) {
        //统计购买
        [WdysHelper trackPurChaseEventWithItemId:self.payItem.productId AndPrice:[NSString stringWithFormat:@"%f",self.payItem.priceUsd*0.96]];
        [WdysHelper trackKeyTimePurchaseEventWithEmail:[LMUser shareUser].email];
        POST_NTF(SFRechargeSuccessNotification, self.payItem);
        [self webViewHidden];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if ([url.absoluteString rangeOfString:@"p/f"].location != NSNotFound) {
        [self webViewHidden];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}
- (void)dealloc {
    LSLog(@"%s",__FUNCTION__);
    if (_webView) {
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
}
- (void)showInView:(UIView *)view {
    [view addSubview:self];
    [self insertSubview:self.webView atIndex:0];
    [self wkWebViewRequestUrl:_reloadURL];
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    self.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    }];
}
- (void)webViewHidden {
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [_webView removeFromSuperview];
    _webView = nil;
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    }completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
}
- (void)paySucessedAlert {
    // 统计购买
    [WdysHelper trackPurChaseEventWithItemId:self.payItem.productId AndPrice:[NSString stringWithFormat:@"%f",self.payItem.priceUsd*0.96]];
    [WdysHelper trackKeyTimePurchaseEventWithEmail:[LMUser shareUser].email];
}
@end
