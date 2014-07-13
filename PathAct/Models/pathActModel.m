//
//  pathActModel.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 25/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

//#ifdef DEBUG
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;
//#else
//static const int ddLogLevel = LOG_LEVEL_WARN;
//#endif

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#import "pathActModel.h"
#import "Sitio.h"
#import "Punto.h"

#import <AudioToolbox/AudioToolbox.h>

#import "AFNetworking.h"

@interface pathActModel()

@end


@implementation pathActModel

#pragma Mark - Synthesizes
@synthesize listaDeSitios;
@synthesize sitioMonitorizado;

@synthesize distanceForDetection;
@synthesize pulsacionMinima;
@synthesize urlWebServer;

// Core data objects
@synthesize mainContext = _mainContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

// Un booleano que indica si estamos o no monitorizando la región
@synthesize _didStartMonitoringRegion;

// Un booleano que indica si estamos o no añadiendo un elemento a la lista
@synthesize addingRegionToModel;

// Booleanos para indicar final de carrera apertura y cierre
@synthesize finalCarreraApertura;
@synthesize finalCarreraCierre;

// Un timer para cambiar de color el check
@synthesize timerColorCheck;

#pragma Mark - Cuerpo de los métodos
// Patron singleton
+(id)sharedInstance{
    static pathActModel *_instance = nil;
    if (_instance == nil){
        _instance = [[self alloc] init];
    }
    return _instance;
}

- (NSString *)modelName {
    return @"Model";
}

- (NSString *)pathToModel {
    return [[NSBundle mainBundle] pathForResource:[self modelName]
                                           ofType:@"momd"];
}

- (NSString *)storeFilename {
    return [[self modelName] stringByAppendingPathExtension:@"sqlite"];
}

- (NSString *)pathToLocalStore {
    return [[self documentsDirectory] stringByAppendingPathComponent:[self storeFilename]];
}

// Constructor
-(id)init{
    if((self = [super init])){
        listaDeSitios = [[NSMutableArray alloc]init];
        
        // Al iniciar el objeto, si ya tenemos uno en BD, empezamos a monitorizar
        if (self.listaDeSitios.count > 0)
        {
            _didStartMonitoringRegion = YES;
        }
        addingRegionToModel = NO;        
    }
    return self;
}

- (NSManagedObjectContext *)mainContext {
    if (_mainContext == nil) {
        _mainContext = [[NSManagedObjectContext alloc] init];
        _mainContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    }
    
    return _mainContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel == nil) {
        NSURL *storeURL = [NSURL fileURLWithPath:[self pathToModel]];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:storeURL];
    }
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator == nil) {
        DDLogInfo(@"SQLITE STORE PATH: %@", [self pathToLocalStore]);
        NSURL *storeURL = [NSURL fileURLWithPath:[self pathToLocalStore]];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc]
                                             initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        NSError *e = nil;
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:options
                                       error:&e]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:e forKey:NSUnderlyingErrorKey];
            NSString *reason = @"Could not create persistent store.";
            NSException *exc = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:reason
                                                     userInfo:userInfo];
            @throw exc;
        }
        
        _persistentStoreCoordinator = psc;
    }
    
    return _persistentStoreCoordinator;
}

- (NSString *)documentsDirectory {
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.mainContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Devuelve un array con la lista de sitios que hay en la BD
-(NSMutableArray*) getListaDeSitiosFromDB
{
    NSMutableArray* arraySalida;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sitio" inManagedObjectContext:[self mainContext]];
    [fetchRequest setEntity:entity];
    NSError *error;
    arraySalida = [[NSMutableArray alloc] initWithArray:[[self mainContext] executeFetchRequest:fetchRequest error:&error]];
    
    return arraySalida;
}

// Cargamos en el modelo todos los sitios
-(void) fillListaDeSitiosFromDB{
    //[[self listaDeSitios] arrayByAddingObjectsFromArray:[self getListaDeSitiosFromDB]];
    self.listaDeSitios = [self getListaDeSitiosFromDB];
}

// Añadimos un sitio al modelo y lo persistimos
-(void) addSitio:(CLRegion *)region{
    if (region){
        // Creamos un nuevo sitio
        Sitio *sitio = [Sitio sitioWithContext: [self mainContext]];
        sitio.cerca = region;
        sitio.nombre = region.identifier;
        
        // Lo persistimos
        NSError *error;
        if (![[self mainContext] save:&error]) {
            DDLogError(@"No se ha podido guardar: %@", [error localizedDescription]);
        }
        
        // Lo añadimos a nuestro modelo
        [listaDeSitios addObject:sitio];
        DDLogInfo(@"Añadido un sitio al modelo");
    }
}

// Traemos un sitio de la base de datos conocido su nombre
-(Sitio *)fetchSitioWithName:(NSString *) name
{
    Sitio *salida = nil;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sitio"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"nombre == %@",name];
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedArray = [[self mainContext] executeFetchRequest:fetchRequest error:nil];
    if ([fetchedArray count] > 0) {
        salida = [fetchedArray objectAtIndex:0];
    }
    
    return salida;
}

// Eliminamos un sitio del modelo de datos y persistimos el cambio
-(void) deleteSitio:(CLRegion *)region{
    if (region){
        // Creamos un array temporal de los elementos que hay que borrar
        NSMutableArray *discardedItems = [NSMutableArray array];
        Sitio *item;
        
        // Iteramos por el modelo buscando el elemento a borrar
        for (item in listaDeSitios) {
            if ([[[item cerca] identifier] isEqualToString:[region identifier]]){
                [discardedItems addObject:item];
            }
        }
        
        // Borramos el elemento encontrado en BD
        if (discardedItems) {
            NSError * error = nil;
            [[self mainContext] deleteObject:[discardedItems lastObject]];
            [[self mainContext] save:&error];
        }
        
        // Borramos del modelo
        [listaDeSitios removeObjectsInArray:discardedItems];
        DDLogInfo(@"Borrado un sitio del modelo");
    }
}

// Añadimos un punto a un sitio y actualizamos
-(void) addPunto:(Punto *)paramPuntoActual ToSitio:(Sitio *)paramSitioActual{
    if(paramPuntoActual !=nil && paramSitioActual != nil){
        
        // Un conjunto para los puntos
        NSMutableSet *puntos = [NSMutableSet set];
        
        // Consultamos si el sitio esta en BD
        Sitio * sitioFromDB = [self fetchSitioWithName:[paramSitioActual nombre]];
        
        // Si no está, creamos uno, si sí lo está lo actualizamos
        if (sitioFromDB == nil)
        {
            // Creamos un sitio, le asignamos la cerca y el nombre
            sitioFromDB = [Sitio sitioWithContext: [self mainContext]];
            [sitioFromDB setCerca:[paramSitioActual cerca]];
            [sitioFromDB setNombre:[paramSitioActual nombre]];
            
            // preparamos el conjunto de puntos y añadimos el punto pasado como parámetro
            [puntos setByAddingObjectsFromSet:[paramSitioActual listaPuntos]];
            [puntos addObject:paramPuntoActual];
            
            // Asignamos el conjunto de puntos al sitio
            [sitioFromDB setListaPuntos:puntos];
        }
        else
        {
            puntos = [NSMutableSet setWithSet:[sitioFromDB listaPuntos]];
            [puntos addObject:paramPuntoActual];
            [sitioFromDB setListaPuntos:puntos];
        }
        
        // Persistimos los cambios
        NSError * error = nil;
        [[self mainContext] save:&error];
    }
}

// Borramos un punto de un sitio y actualizamos
-(void) removePuntosFromSitio:(Sitio *) paramSitioActual{
    if (paramSitioActual != nil)
    {
        // Recorremos los puntos
        for (Punto* puntoAuxiliar in [paramSitioActual listaPuntos])
        {
            if (puntoAuxiliar)
            {
                [[self mainContext] deleteObject:puntoAuxiliar];
            }
        }
    }
    
    // Persistimos los cambios
    NSError * error = nil;
    if (![[self mainContext] save:&error])
    {
        DDLogError(@"Problem saving destination: %@", [error localizedDescription]);
    }
    
}

// Ponemos todos las horas a 0 para evitar lanzar la acción desde el modelo repetidamente
-(void)resetSitioPassingTime:(Sitio *) paramSitioActual
{
    for (Punto* puntoAuxiliar in paramSitioActual.listaPuntos)
    {
        [puntoAuxiliar setHoraPaso:0];
    }
    // Persistimos los cambios
    NSError * error = nil;
    if (![[self mainContext] save:&error])
    {
        DDLogError(@"Problem saving destination: %@", [error localizedDescription]);
    }
}

-(void)setTiempoPaso:(NSTimeInterval) paramSeconds inSitio:(Sitio *) paramSitioActual
{
    [paramSitioActual setTiempoPaso:paramSeconds];
    [self saveContext];
}

// Actuamos sobre el sitio actual, sitioMonitorizado y devolvemos true si tenemos éxito
-(BOOL) updateModelWithLocation:(CLLocation *) newLocation
{
    BOOL salida = NO;
    if (sitioMonitorizado)
    {
        // Traemos el punto si está cerca
        Punto* puntoAux = [Sitio getPointReached:sitioMonitorizado
                                    fromLocation:newLocation
                                     andDistance:[[[pathActModel sharedInstance] distanceForDetection] doubleValue]];
        if (puntoAux) {
            // Actualizamos la hora de paso
            int secondsNow =(int)[[NSDate date] timeIntervalSince1970];
            [puntoAux setHoraPaso:secondsNow];
            DDLogInfo(@"Actualizado el punto nº %d con la hora: %@", puntoAux.ordenPaso, [NSDate dateWithTimeIntervalSince1970:[puntoAux horaPaso]]);
                        
            NSDictionary *dictAux = [[NSDictionary alloc] initWithObjectsAndKeys:puntoAux, @"1", nil];
            // Avisamos al mapa
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"pointReachedNotification"
             object:self
             userInfo:dictAux];
            
            // Persistimos los cambios
            NSError * error = nil;
            if ([[self mainContext] save:&error])
            {
                // Marcamos como éxito
                salida = YES;
            }
            else
            {
                DDLogError(@"Ha habido un error al persistir la hora para el punto.");
            }
            
        }
    }
    else {
        DDLogWarn(@"No podemos actualizar un punto sin monitorizar un sitio.");
    }
    return salida;
}

// Devuelve una lista de cercas del modelo previamente cargado. Se usa para rellenar el TableView
-(NSMutableArray *)getListaDeCercas{
    NSMutableArray *salida = [NSMutableArray array];
    
    Sitio *sitio;
    if(listaDeSitios)
    {
        for (sitio in listaDeSitios)
        {
            [salida addObject:[sitio cerca]];
        }
    }
    return salida;
}

-(void) playSound:(int) paramValue
{
    SystemSoundID soundID1;
    SystemSoundID soundID2;
    SystemSoundID soundID3;
    if (paramValue >=0 || paramValue <=3)
    {
        switch (paramValue)
        {
            case 0:
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                break;
            case 1:
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                                            pathForResource:@"1" ofType:@"wav"]], &soundID1);
                AudioServicesPlaySystemSound(soundID1);
                break;
            case 2:
                
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                                            pathForResource:@"2" ofType:@"wav"]], &soundID2);
                AudioServicesPlaySystemSound(soundID2);
                break;
            case 3:
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                                            pathForResource:@"3" ofType:@"wav"]], &soundID3);
                AudioServicesPlaySystemSound(soundID3);
                break;
                
        }
    }
}

#pragma Mark - Acciones sobre la puerta

-(void)pulsacionPuerta
{
    [self puertaOn];
    // Lanzamos un timer para la pulsación OFF en el relé
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(puertaOff)
                                   userInfo:nil
                                    repeats:NO];
    
    // Eliminamos el timer anterior y creamos uno nuevo
    [self.timerColorCheck invalidate];
    self.timerColorCheck = nil;
    DDLogInfo(@"Deteniendo el timer del checkmark");
    
    // Lanzamos otro timer para comprobar si la puerta ha cambiado de estado
    self.timerColorCheck = [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(checkPuerta)
                                   userInfo:nil
                                    repeats:YES];
}

// Manda un ON al relé mediante webservice
-(void)puertaOn
{
    DDLogInfo(@"Puerta On");
    [self playSound:0];
    [self playSound:1];
    [self accionPuerta:1];
}

// Manda un OFF al relé mediante webservice
-(void)puertaOff
{
    DDLogInfo(@"Puerta Off");
    [self accionPuerta:0];
    [self playSound:0];
    [self playSound:3];
}

// Actualiza asíncronamente las propiedades de apertura y cierre avisando a la vista
-(void) checkPuerta
{
    // Consume el servicio con el valor pasado
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"webiopi" password:@"bollullos"];
    
    // Llamamos al servicio de consulta de Apertura
    //http://37.26.251.172:8000
    [manager GET:[[[pathActModel sharedInstance] urlWebServer] stringByAppendingString:@"/sensorA"]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             // Actualizamos el valor del final de carrera de apertura
             BOOL valorAnteriorCarreraApertura = [self finalCarreraApertura];
             int valorCarreraApertura = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] intValue];
             [self setFinalCarreraApertura: valorCarreraApertura == 1];
             // Si cambia el valor, actualizamos el color
             if (valorAnteriorCarreraApertura != self.finalCarreraApertura) {
                 [self updateCheckColor];
             }
             DDLogInfo(@"Sensor Apertura: %d", valorCarreraApertura);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             // Código si no podemos leer el servicio web
             DDLogError(@"Error leyendo el servicio del sensor Apertura");
         }
     ];

    // Llamamos al servicio de consulta de Cierre
    [manager GET:[[[pathActModel sharedInstance] urlWebServer] stringByAppendingString:@"/sensorC"]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         // Actualizamos el valor del final de carrera de apertura
         BOOL valorAnteriorCarreraCierre = [self finalCarreraCierre];
         int valorCarreraCierre = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] intValue];
         [self setFinalCarreraCierre: valorCarreraCierre == 1];
         // Si cambia el valor, actualizamos el color
         if (valorAnteriorCarreraCierre != self.finalCarreraCierre) {
             [self updateCheckColor];
         }
         DDLogInfo(@"Sensor Cierre: %d", valorCarreraCierre);
     }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         // Si no podemos leer el servicio web
         DDLogError(@"Error leyendo el servicio del sensor Cierre");
     }
     ];
}

// Actualizamos el color del check y avisamos a la vista
- (void) updateCheckColor
{
    // 0: gris, 1: ambar, 2: verde
    int colorParaCheckMark = 1;
    
    if (!self.finalCarreraApertura && !self.finalCarreraCierre)
    {
        colorParaCheckMark = 1;
    }
    else if (self.finalCarreraCierre)
    {
        colorParaCheckMark = 0;
        [self.timerColorCheck invalidate];
        self.timerColorCheck = nil;
        DDLogInfo(@"Deteniendo el timer del check mark.");
    }
    else
    {
        colorParaCheckMark = 2;
        [self.timerColorCheck invalidate];
        self.timerColorCheck = nil;
        DDLogInfo(@"Deteniendo el timer del check mark");
    }
    
    NSDictionary *dictAux = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:colorParaCheckMark], @"1", nil];
    // Avisamos a la vista de la tabla
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"doorActionNotification"
     object:self
     userInfo:dictAux];
}

- (void)accionPuerta:(int)valor
{
    // Consume el servicio con el valor pasado
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"webiopi" password:@"bollullos"];
    [manager POST:
     [NSString stringWithFormat:[[[pathActModel sharedInstance] urlWebServer] stringByAppendingString:@"/puerta/%d"], valor] parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject)
          {
              NSLog(@"JSON: %@", responseObject);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error)
          {
              NSLog(@"Error: %@", error);
          }];
}

@end
