//
//  PACTMapAnnotation.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 01/04/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import "PACTMapAnnotation.h"

@implementation PACTMapAnnotation

@synthesize title;
@synthesize subtitle;
@synthesize coordinate;
@synthesize pinIndex;
@synthesize colorDelPin;

-(id) initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D *)location{
    self = [super init];
    
    if (self) {
        title = newTitle;
        coordinate = *location;
    }
    
    return self;
}

@end
