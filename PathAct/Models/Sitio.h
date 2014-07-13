//
//  Sitio.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 30/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "_Sitio.h"

@class Punto;

@interface Sitio : _Sitio

+(id)sitioWithContext:(NSManagedObjectContext *)context;

+(Punto *) getPointReached:(Sitio *) paramSitioActual fromLocation:(CLLocation *) paramLocation andDistance:(double) paramDistance;
+(BOOL) isSitioProperlyRun:(Sitio *) paramSitioActual;
@end
