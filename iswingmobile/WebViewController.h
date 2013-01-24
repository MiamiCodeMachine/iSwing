//
//  ViewController.h
//  iswingmobile
//
//  Created by Carlos Duran on 1/16/13.
//  Copyright (c) 2013 DashBoardHosting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SBJSON.h"

@interface WebViewController : UIViewController <UIWebViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) NSString *urlAddress;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSMutableDictionary *parametersList;

@property (nonatomic) int alertCallbackId;
@property (nonatomic) SBJSON *json;

- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
- (void)returnResult:(int)callbackId args:(id)firstObj, ...;


@end
