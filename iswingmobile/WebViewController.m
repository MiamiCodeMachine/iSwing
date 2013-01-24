//
//  ViewController.m
//  iswingmobile
//
//  Created by Carlos Duran on 1/16/13.
//  Copyright (c) 2013 DashBoardHosting. All rights reserved.
//


#import "WebViewController.h"

static NSString *const kUrlAddress = @"http://12.190.217.5/ios/homepage.cfm";
//static NSString *const kUrlAddress = @"http://localhost/dashboardhosting/iostest.html";


@interface WebViewController ()
-(void)getCoordinates;
-(void)loadWebPage;
-(NSString*)generateUUID;

@end

@implementation WebViewController

#pragma mark - Jscript to iOS interface
// This selector is called when something is loaded in our webview
// By something I don't mean anything but just "some" :
//  - main html document
//  - sub iframes document
//
// But all images, xmlhttprequest, css, ... files/requests doesn't generate such events :/
- (BOOL)webView:(UIWebView *)webView2
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *requestString = [[request URL] absoluteString];
    
    //NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
		int callbackId = [((NSString*)[components objectAtIndex:2]) intValue];
        NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSArray *args = (NSArray*)[self.json objectWithString:argsAsString error:nil];
        
        [self handleCall:function callbackId:callbackId args:args];
        
        return NO;
    }
    
    return YES;
}

// Call this function when you have results to send back to javascript callbacks
// callbackId : int comes from handleCall function
// args: list of objects to send to the javascript callback
- (void)returnResult:(int)callbackId args:(id)arg, ...;
{
    va_list argsList;
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    if(arg != nil){
        [resultArray addObject:arg];
        va_start(argsList, arg);
        while((arg = va_arg(argsList, id)) != nil)
            [resultArray addObject:arg];
        va_end(argsList);
    }
    
    NSString *resultArrayString = [self.json stringWithObject:resultArray allowScalar:YES error:nil];
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"NativeBridge.resultForCallback(%d,%@);",callbackId,resultArrayString]];
}

// Implements all you native function in this one, by matching 'functionName' and parsing 'args'
// Use 'callbackId' with 'returnResult' selector when you get some results to send back to javascript
- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args
{
    if ([functionName isEqualToString:@"setBackgroundColor"]) {
        
        if ([args count]!=3) {
            NSLog(@"setBackgroundColor wait exactly 3 arguments!");
            return;
        }
        NSNumber *red = (NSNumber*)[args objectAtIndex:0];
        NSNumber *green = (NSNumber*)[args objectAtIndex:1];
        NSNumber *blue = (NSNumber*)[args objectAtIndex:2];
//        NSLog(@"setBackgroundColor(%@,%@,%@)",red,green,blue);
        [self.webView setBackgroundColor:[UIColor clearColor]];
        [self.webView setOpaque:NO];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView setBackgroundColor:[UIColor colorWithRed:[red floatValue] green:[green floatValue] blue:[blue floatValue] alpha:1.0]];
        });
        [self returnResult:callbackId args:nil];
        
    } else if ([functionName isEqualToString:@"prompt"]) {
        
        if ([args count]!=1) {
            NSLog(@"prompt wait exactly one argument!");
            return;
        }
        
        NSString *message = (NSString*)[args objectAtIndex:0];
        
        _alertCallbackId = callbackId;
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        [alert show];
        
    } else {
        NSLog(@"Unimplemented method '%@'",functionName);
    }
}

// Just one example with AlertView that show how to return asynchronous results
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (!self.alertCallbackId) return;
    
    NSLog(@"prompt result : %d",buttonIndex);
    
    BOOL result = buttonIndex==1?YES:NO;
    [self returnResult:_alertCallbackId args:[NSNumber numberWithBool:result],nil];
    
//    self.alertCallbackId = nil;
}


#pragma mark - Web View delegate mehods
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        NSLog(@"%@", cookie);
    }


}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}
#pragma mark - CLLocation Delegate Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *lastLocation = [locations lastObject];
    self.currentLocation = lastLocation;
    NSDate *eventDate = lastLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        if (lastLocation.horizontalAccuracy < 35.0) {
            NSLog(@"latitude %+.6f, longitude %+.6f\n",
                  lastLocation.coordinate.latitude,
                  lastLocation.coordinate.longitude);
            NSLog(@"Horizontal Accuracy:%f", lastLocation.horizontalAccuracy);
            
            //Optional: turn off location services once we've gotten a good location
            [self.locationManager stopUpdatingLocation];
        }
    }

    // Get unique device identifier
    NSString *swingIdString = [[NSUserDefaults standardUserDefaults] objectForKey:@"swingId"];
    if (swingIdString == nil) {
        swingIdString = [self generateUUID];
        [[NSUserDefaults standardUserDefaults] setObject:swingIdString forKey:@"swingId"];
    }
    NSLog(@"Swing Id : %@\n\n",swingIdString);
    [self.parametersList setObject:swingIdString forKey:@"sku"];

    // Get Coordinates
    CLLocationCoordinate2D coord;
    coord = [self.currentLocation coordinate];
    NSString *currentLatitude = [NSString stringWithFormat:@"%f",
                                 coord.latitude];
    NSString *currentLongitude = [NSString stringWithFormat:@"%f",
                                 coord.longitude];
    NSString *GPSString = [NSString stringWithFormat:@"%@__%@",currentLatitude, currentLongitude];
    [self.parametersList setObject:GPSString forKey:@"gps"];
    
    // Get screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString *screenHeight = [NSString stringWithFormat:@"%d",
                              (int)screenSize.height];
    NSString *screenWidth = [NSString stringWithFormat:@"%d",
                              (int)screenSize.width];
    [self.parametersList setObject:screenHeight forKey:@"pixwidth"];
    [self.parametersList setObject:screenWidth forKey:@"pixheight"];
    
//    [self.parametersList enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        NSLog(@"Key: %@ Object : %@ ", key, obj);
//    }];
    [self loadWebPage];

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if(error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    } else if(error.code == kCLErrorLocationUnknown) {
        // retry
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma  mark - Custom Methods
-(void)getCoordinates
{
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 500;
    
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"*** Error with locationServicesEnabled");
        return;
    }

    [self.locationManager startUpdatingLocation];
    
}
-(void)loadWebPage
{
    self.urlAddress = [NSString stringWithFormat:@"%@?", kUrlAddress];
    self.urlAddress = [NSString stringWithFormat:@"%@sku=%@",self.urlAddress,
                       [self.parametersList objectForKey:@"sku"]];

    self.urlAddress = [NSString stringWithFormat:@"%@&gps=%@",self.urlAddress,
                       [self.parametersList objectForKey:@"gps"]];

    self.urlAddress = [NSString stringWithFormat:@"%@&pixwidth=%@",self.urlAddress,
                       [self.parametersList objectForKey:@"pixwidth"]];
    
    self.urlAddress = [NSString stringWithFormat:@"%@&pixheight=%@",self.urlAddress,
                       [self.parametersList objectForKey:@"pixheight"]];
    
    NSLog(@"url : %@",self.urlAddress);
    NSURL *url = [NSURL URLWithString:self.urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView setDelegate:self];
    [self.webView loadRequest:requestObj];
    
}
-(NSString*)generateUUID
{
//    CFUUIDRef theUUID = CFUUIDCREATE(NULL);
//    NSString *uuidString = (__bridge_transfer NSString *)
//        CFUUIDCreateString(NULL, theUUID);
//    CFRelease(theUUID);
//    return uuidString;
    
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"uniqueID"];
    if (!UUID)
    {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        UUID = [(__bridge NSString*)string stringByReplacingOccurrencesOfString:@"-"withString:@""];
//        [[NSUserDefaults standardUserDefaults] setValue:UUID forKey:@"uniqueID"];
    }
    return UUID;
    
    
}
#pragma  mark - Common Methods
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    dispatch_queue_t concurrentQueue =
//    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(concurrentQueue, ^{
        [self getCoordinates];
    [TestFlight passCheckpoint:@"CHECKPOINT_ViewWillAppear"];

//    });
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc]init];
    self.parametersList = [[NSMutableDictionary alloc] init];
    self.json = [[SBJSON alloc]init];
    [TestFlight passCheckpoint:@"CHECKPOINT_ViewDidLoad"];

}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
    [self setWebView:nil];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
