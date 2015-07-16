//
//  ViewController.m
//  MyWebBrowser
//
//  Created by Tony Dakhoul on 5/13/15.
//  Copyright (c) 2015 Tony Dakhoul. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate, UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (strong, nonatomic) UITextField *urlTextField;
@property (strong, nonatomic) UILabel *pageTitle;

@property CGFloat lastOffsetY;

@end

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 24.0f;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.delegate = self;
    self.webView.scrollView.delegate = self;

    UINavigationBar *navBar = self.navigationController.navigationBar;

    CGRect labelFrame = CGRectMake(kMargin, kSpacer, navBar.bounds.size.width - 2*kMargin, kLabelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [navBar addSubview:label];
    self.pageTitle = label;

    CGRect addressFrame = CGRectMake(kMargin, kSpacer*2.0 + kLabelHeight, labelFrame.size.width, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:17];
    address.keyboardType = UIKeyboardTypeURL;
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
    address.clearButtonMode = UITextFieldViewModeWhileEditing;
    address.placeholder = @"Enter address here";
    [address addTarget:self action:@selector(loadRequestFromAddressField:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [navBar addSubview:address];
    self.urlTextField = address;

    [self gotoUrlString:@"http://www.google.com"];

}

//-(BOOL)textFieldShouldReturn:(UITextField *)textField {
//
//    NSLog(@"Return hit");
//
//    [self gotoUrlString:textField.text];
//
//    return YES;
//}

-(void)loadRequestFromAddressField:(UITextField *)addressField {

    NSString *urlString = addressField.text;
    [self gotoUrlString:urlString];
}

//sends a loadrequest to webview based on urlString
-(void)gotoUrlString:(NSString *)string {

    NSString *urlString;

    if(![string hasPrefix:@"http://"]) {

        urlString = [NSString stringWithFormat:@"http://%@", string];

    } else {

        urlString = string;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [self.webView loadRequest:request];    
//    self.urlTextField.text = urlString;
}

//updates address bar to match current page's URL
- (void)updateAddress:(NSURLRequest*)request {
    NSURL* url = [request mainDocumentURL];
    NSString* updatedURL = [url absoluteString];
    self.urlTextField.text = updatedURL;
}

//updates toolbar buttons
-(void)updateButtons {

    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.stopButton.enabled = self.webView.loading;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [self.spinner startAnimating];
    [self updateButtons];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {

    [self.spinner stopAnimating];
    [self updateButtons];
    [self updateAddress:[webView request]];

    self.pageTitle.text = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

    [self updateButtons];

}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    [self updateAddress:request];
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.navigationController.navigationBar.frame;
    CGFloat size = frame.size.height - 21;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - self.lastOffsetY;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;

    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
        
    }

    [self.navigationController.navigationBar setFrame:frame];
    [self updateBarButtonItems:(1 - framePercentageHidden)];
    self.lastOffsetY = scrollOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {

    if (!decelerate) {
        [self stoppedScrolling];
    }
}

- (void)stoppedScrolling {

    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < -5) {
        [self animateNavBarTo:-(frame.size.height - 21)];
//        [self animateWebView:-(frame.size.height - 21)];
    } else {
        [self animateNavBarTo:(frame.size.height - 21)];
//                [self animateWebView:(frame.size.height - 21)];

    }
}

- (void)updateBarButtonItems:(CGFloat)alpha {

    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
    self.urlTextField.alpha = alpha;
}

- (void)animateNavBarTo:(CGFloat)y {

    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
    }];
}

-(void)animateWebView:(CGFloat)y {

    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.webView.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.webView setFrame:frame];
//        [self updateBarButtonItems:alpha];
    }];
}
@end
