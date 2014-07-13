//
//  pathActModel.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 25/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>

@class Sitio;
@class Punto;

@interface pathActModel : NSObject{
    
}

// Lista de los sitios (cerca + listaDePuntos + seconds)
@property (nonatomic, retain) NSMutableArray *listaDeSitios;
@property (nonatomic, retain) Sitio* sitioMonitorizado;

@property (nonatomic, retain) NSNumber* distanceForDetection;
@property (nonatomic, retain) NSNumber* pulsacionMinima;
@property (nonatomic, retain) NSString* urlWebServer;

#pragma Mark - Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

#pragma Mark - Helpers para las acciones
@property (nonatomic) BOOL _didStartMonitoringRegion;
@property (nonatomic) BOOL addingRegionToModel;

#pragma Mark - Core Data
@property (nonatomic) BOOL finalCarreraApertura;
@property (nonatomic) BOOL finalCarreraCierre;

@property (nonatomic, retain) NSTimer *timerColorCheck;

- (void)saveContext;
- (NSString *)documentsDirectory;

// Métodos o funciones

// Para compartir el modelo en toda la aplicación
+(id) sharedInstance;

// Helpers para definir el modelo de datos
- (NSString *)modelName;
- (NSString *)pathToModel;
- (NSString *)storeFilename;
- (NSString *)pathToLocalStore;

-(void) fillListaDeSitiosFromDB;
//-(void) fillListaDeSitiosWithArray:(NSMutableArray *)data;
-(void) deleteSitio:(CLRegion *)region;
-(void) addSitio:(CLRegion *)region;
-(NSMutableArray *)getListaDeCercas;
-(NSMutableArray*) getListaDeSitiosFromDB;
-(void) addPunto:(Punto *)paramPuntoActual ToSitio:(Sitio *)paramSitioActual;
-(void) removePuntosFromSitio:(Sitio *) paramSitioActual;
-(Sitio *) fetchSitioWithName:(NSString *) name;
-(BOOL) updateModelWithLocation:(CLLocation *) newLocation;
-(void) resetSitioPassingTime:(Sitio *) paramSitioActual;
-(void) setTiempoPaso:(NSTimeInterval) paramSeconds inSitio:(Sitio *) paramSitioActual;
//-(void) requestDoorActionWithValue:(int32_t) paramValue;
//-(NSData *)postDataToUrl:(NSString*)urlString:(NSString*)jsonString;
-(void) playSound:(int) paramValue;

// Acciones sobre la puerta
-(void) pulsacionPuerta;
-(void) accionPuerta:(int)valor;
-(void) puertaOn;
-(void) puertaOff;
-(void) checkPuerta;
- (void) updateCheckColor;
@end
