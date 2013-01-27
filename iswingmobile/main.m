//
//  main.m
//  iswingmobile
//
//  Created by Carlos Duran on 1/16/13.
//  Copyright (c) 2013 DashBoardHosting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

CFAbsoluteTime StartTime;

int main(int argc, char *argv[])
{
    StartTime = CFAbsoluteTimeGetCurrent();
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
