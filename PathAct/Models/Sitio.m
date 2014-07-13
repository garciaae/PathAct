//
//  Sitio.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 30/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import "Sitio.h"
#import "Punto.h"


@implementation Sitio

+(id)sitioWithContext:(NSManagedObjectContext *)context {
    Sitio *sitio = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Sitio"
                        inManagedObjectContext:context];
    return sitio;
}

// Devuelve el punto si estamos cerca de uno de los puntos del sitio
+(Punto *) getPointReached:(Sitio *) paramSitioActual fromLocation:(CLLocation *) paramLocation andDistance:(double) paramDistance{
    Punto* salida = nil;
    if (paramSitioActual != nil && paramLocation != nil)
    {
        // Recorremos los puntos
        for (Punto* puntoAuxiliar in [paramSitioActual listaPuntos])
        {
            if ([[Punto getLocationFromPunto:puntoAuxiliar] distanceFromLocation:paramLocation] < paramDistance)
            {
                salida = puntoAuxiliar;
                NSLog(@"Hemos alcanzado el punto: %d", [puntoAuxiliar ordenPaso]);
            }
            
            //NSLog(@"El punto nº %d (%f, %f) está a %f metros de la ubicación actual(%f, %f)", puntoAuxiliar.ordenPaso, puntoAuxiliar.latitud, puntoAuxiliar.longitud, [[Punto getLocationFromPunto:puntoAuxiliar] distanceFromLocation:paramLocation], paramLocation.coordinate.latitude, paramLocation.coordinate.longitude);
        }
    }
    return salida;
}

// Devuelve true si podemos recorrer el sitio
+(BOOL) isSitioProperlyRun:(Sitio *) paramSitioActual
{
    BOOL salida = YES;
    if (paramSitioActual && [[paramSitioActual listaPuntos] count] == 3)
    {
        // Traemos los puntos ordenados por orden de paso
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"ordenPaso" ascending:YES]];
        NSArray *sortedPuntos = [[paramSitioActual listaPuntos] sortedArrayUsingDescriptors:sortDescriptors];
        
        // La hora anterior para comparar los elementos
        NSTimeInterval horaAnterior = 0;
        // Recorremos los puntos
        for (Punto* puntoAuxiliar in sortedPuntos)
        {
            //NSLog(@"Procesando punto nº %d", puntoAuxiliar.ordenPaso);
            if ([puntoAuxiliar horaPaso] < horaAnterior) {
                salida = NO;
                //NSLog(@"%@ < %@", [NSDate dateWithTimeIntervalSince1970:[puntoAuxiliar horaPaso]], [NSDate dateWithTimeIntervalSince1970:horaAnterior]);
            }
            else
            {
                //NSLog(@"%@ > %@", [NSDate dateWithTimeIntervalSince1970:[puntoAuxiliar horaPaso]], [NSDate dateWithTimeIntervalSince1970:horaAnterior]);
            }
            horaAnterior = [puntoAuxiliar horaPaso];
        }
        // Por último,  comprobamos si los pasos están dentro del rango programado
        if (salida && [(Punto *)sortedPuntos[[sortedPuntos count] -1 ] horaPaso] - [(Punto *)sortedPuntos[0] horaPaso] < [paramSitioActual tiempoPaso])
        {
            NSLog(@"Camino recorrido en %f segundos (programado: %f)", [(Punto *)sortedPuntos[[sortedPuntos count] -1 ] horaPaso] - [(Punto *)sortedPuntos[0] horaPaso], [paramSitioActual tiempoPaso]);
        }
        else
        {
            salida = NO;
        }
    }
    else
    {
        salida = NO;
    }
    return salida;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Nombre: %@ Hora %f", self.nombre, self.tiempoPaso];
}

@end
