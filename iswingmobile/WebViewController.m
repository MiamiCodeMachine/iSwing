//
//  ViewController.m
//  iswingmobile
//
//  Created by Carlos Duran on 1/16/13.
//  Copyright (c) 2013 DashBoardHosting. All rights reserved.
//


#import "WebViewController.h"


@interface WebViewController ()

@end

@implementation WebViewController

#pragma mark - Web View delegate mehods
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}
#pragma  mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.urlAddress = @"http://12.190.217.5/ios/index.cfm";
    NSURL *url = [NSURL URLWithString:self.urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
