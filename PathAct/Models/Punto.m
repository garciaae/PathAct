//
//  Punto.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 30/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import "Punto.h"
#import "Sitio.h"


@implementation Punto

+(id)puntoWithContext:(NSManagedObjectContext *)context {
    Punto *punto = [NSEntityDescription
                    insertNewObjectForEntityForName:@"Punto"
                    inManagedObjectContext:context];
    return punto;
}

// Devuelve una instancia de CLLocation dado un Punto
+(CLLocation*) getLocationFromPunto:(Punto *) paramPunto{
    CLLocation* salida;
    if (paramPunto && paramPunto.longitud && paramPunto.latitud) {
        salida =  [[CLLocation alloc] initWithLatitude:paramPunto.latitud longitude:paramPunto.longitud];
    }
    return salida;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Punto: Orden: %d Lat: %f Lon: %f Hora: %f", self.ordenPaso, self.latitud, self.longitud ,self.horaPaso];
}

@end
