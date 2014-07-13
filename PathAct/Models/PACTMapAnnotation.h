//
//  PACTMapAnnotation.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 01/04/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PACTMapAnnotation : NSObject<MKAnnotation>{
}

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * subtitle;
@property (nonatomic, assign)CLLocationCoordinate2D coordinate;
@property (nonatomic) int32_t pinIndex;
@property (nonatomic) NSString* colorDelPin;

-(id) initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D *)location;

@end
