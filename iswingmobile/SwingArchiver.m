//
//  SwingArchiver.m
//  iswingmobile
//
//  Created by Carlos Duran on 1/24/13.
//  Copyright (c) 2013 DashBoardHosting. All rights reserved.
//

#import "SwingArchiver.h"

NSString *const kSwingId = @"swingId";

@implementation SwingArchiver

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.swingId forKey:kSwingId];
}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil) {
        _swingId = [aDecoder decodeObjectForKey:kSwingId];
    }
    return self;
}

@end
