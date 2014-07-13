//
//  Punto.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 30/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "_Punto.h"

@class Sitio;

@interface Punto : _Punto

+(id)puntoWithContext:(NSManagedObjectContext *)context;
+(CLLocation*) getLocationFromPunto:(Punto *) paramPunto;

@end
