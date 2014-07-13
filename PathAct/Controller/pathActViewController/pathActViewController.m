//
//  pathActViewController.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 09/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

//#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
//#else
//static const int ddLogLevel = LOG_LEVEL_WARN;
//static const int ddLogLevel = LOG_LEVEL_WARN;
//#endif

#import "pathActViewController.h"
#import "mapViewController.h"
#import "Sitio.h"
#import "Punto.h"

static NSString *GeofenceCellIdentifier = @"GeofenceCell";
@interface pathActViewController (){
    
}
@end

@implementation pathActViewController

#pragma Mark - Synthesizes
@synthesize model = _model;
@synthesize managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Registramos el método que recibirá la información del paso por el punto
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doorActionNotificationReceived:)
                                                 name:@"doorActionNotification"
                                               object:nil];
    
    
    // Establecer el estado inicial de las carreras. Lo habitual es que esté activada la carrera de cierre
    [[pathActModel sharedInstance] checkPuerta];
    
    // Tenemos los servicios de localización activados?
    BOOL locationAllowed = [CLLocationManager locationServicesEnabled];

    if (locationAllowed==NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Servicios de localización desactivados"
                                                        message:@"Para reactivarlos, vaya a ajustes y active la localización.."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        // Initialize Location Manager
        self.locationManager = [[CLLocationManager alloc] init];
        
        // Configure Location Manager
        [self.locationManager setDelegate:self];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setPausesLocationUpdatesAutomatically:false];
        
        // Prepare the model
        [[pathActModel sharedInstance] fillListaDeSitiosFromDB];
        
        // Cargamos las cercas de los sitios del modelo
        self.geofences = [[pathActModel sharedInstance] getListaDeCercas];
        
        // Preparamos la vista: añadimos los botones
        [self setupView];
    }
}

// Añadimos a la interfaz los botones + y editar
- (void)setupView {
    // Create Add Button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCurrentLocation:)];
    
    // Create Edit Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Editar", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(editTableView:)];
}

// Maneja el evento del botón +
- (void)addCurrentLocation:(id)sender {
    // Update Helper
    [[pathActModel sharedInstance] set_didStartMonitoringRegion:NO];
    [[pathActModel sharedInstance] setAddingRegionToModel:YES];
    
    // Start Updating Location
    [self.locationManager startUpdatingLocation];
}

// Para implementar el interfaz UITableViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[pathActModel sharedInstance] listaDeSitios] ? 1 : 0;
}

// Requerido
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.geofences count];
    //return [[[pathActModel sharedInstance] listaDeSitios] count];
}

// Requerido (Enlazamos el UITableFiew con el modelo de datos)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GeofenceCellIdentifier];
    // Traemos el modelo
    [[pathActModel sharedInstance] listaDeSitios];
    
    // Fetch Geofence
    CLRegion *geofence = [self.geofences objectAtIndex:[indexPath row]];
    
    // Configure Cell
    CLLocationCoordinate2D center = [geofence center];
    
    NSString *text = [NSString stringWithFormat:@"%.4f | %.4f", center.latitude, center.longitude];
    [cell.textLabel setText:text];
    [cell.detailTextLabel setText:[geofence identifier]];
    //[cell.imageView setImage:[UIImage imageNamed:@"imagenAMostrar.png"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)editTableView:(id)sender {
    // Update Table View
    [myTableView setEditing:![myTableView isEditing] animated:YES];
    
    // Update Edit Button
    if ([myTableView isEditing]) {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Hecho", nil)];
    } else {
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Editar", nil)];
    }
}

// Borrados en UItableView
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Fetch Monitored Region
        CLRegion *region = [self.geofences objectAtIndex:[indexPath row]];
        
        // Eliminar del modelo
        [[pathActModel sharedInstance] deleteSitio:region];
        
        // Stop Monitoring Region
        [self.locationManager stopMonitoringForRegion:region];
        
        // Update Table View
        [self.geofences removeObject:region];
        [myTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        
        // Update View
        [self updateView];
    }
}

// Si venimos de añadir una zona,
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // Última ubicación conocida
    CLLocation * newLocation = [locations lastObject];
    
    if (locations && [locations count] &&
        [[pathActModel sharedInstance] _didStartMonitoringRegion] &&
        ![[pathActModel sharedInstance] addingRegionToModel] &&
        newLocation.horizontalAccuracy <= 20.0f)
    {
        // Si podemos actualizar el modelo con la posición actual
        if([[pathActModel sharedInstance]sitioMonitorizado] && [[pathActModel sharedInstance] updateModelWithLocation: newLocation])
        {
            // Comprobamos si hemos recorrido el itinerario de forma correcta
            if ([Sitio isSitioProperlyRun:[[pathActModel sharedInstance] sitioMonitorizado]])
            {
                DDLogInfo(@"Lanzamos el webservice");
                // Aquí código para evitar que se lanze una segunda vez
                [[pathActModel sharedInstance] resetSitioPassingTime:[[pathActModel sharedInstance] sitioMonitorizado]];
                [[pathActModel sharedInstance] setSitioMonitorizado:nil];
                [[pathActModel sharedInstance] pulsacionPuerta];
            }
        }
    }
    
    if (locations && [locations count] &&
        [[pathActModel sharedInstance] addingRegionToModel])
    {
        // Si la ubicación es buena, paramos de localizar. (menos de 300 metros)
        if(newLocation.horizontalAccuracy <= 300.0f)
        {
            // Cogemos la última ubicación
            CLLocation *location = [locations objectAtIndex:0];
            
            // Preparamos la región a monitorizar
            CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:[location coordinate] radius:300.0 identifier:[[NSUUID UUID] UUIDString]];
            
            // Añadir la región al modelo y persistirlo
            [[pathActModel sharedInstance] addSitio:region];
            
            // Actualizamos los flags: empezar a monitorizar y dejar de añadir
            [[pathActModel sharedInstance] set_didStartMonitoringRegion:YES];
            [[pathActModel sharedInstance] setAddingRegionToModel:NO];
            
            // Monitorizamos las regiones con precisión de cientos de metros
            [self.locationManager startMonitoringForRegion:region];
            [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
            [self.locationManager startUpdatingLocation];
            
            // Update Table View
            [self.geofences addObject:region];
            [myTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:([self.geofences count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            // Update View
            [self updateView];
            
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusDenied)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Los servicios de localización se han desactivado"
                                                        message:@"Para reactivarlos, vaya a ajustes y active la localización.."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self.locationManager stopUpdatingLocation];
        DDLogInfo(@"Los servicios de localización se han desactivado");
    }
    else if (status == kCLAuthorizationStatusAuthorized)
    {
        [self.locationManager startUpdatingLocation];
        DDLogInfo(@"Los servicios de localización se han reanudado");
    }
    
}

- (void)updateView {
    if (![self.geofences count]) {
        // Update Table View
        [myTableView setEditing:NO animated:YES];
        
        // Update Edit Button
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Editar", nil)];
        
    } else {
        // Update Edit Button
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    
    // Update Add Button
    if ([self.geofences count] < [[[pathActModel sharedInstance] distanceForDetection] doubleValue]) {
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
    }
}

// Ponemos el check del color pasado como parámetro 0 = gris, 1 = verde
-(void) doorActionNotificationReceived:(NSNotification *) notification;
{
    if ([[notification name] isEqualToString:@"doorActionNotification"])
    {
        NSDictionary *dict = [notification userInfo];
        NSUInteger paramValue = [[dict objectForKey:@"1"] unsignedIntegerValue];
        switch (paramValue) {
            case 0:
                [[self labelCheckPuertaAbriendo] setImage:[UIImage imageNamed:@"check-grey"]];
                DDLogInfo(@"Marcamos el check mark de color gris");
                break;
            case 1:
                [[self labelCheckPuertaAbriendo] setImage:[UIImage imageNamed:@"check-orange"]];
                DDLogInfo(@"Marcamos el check mark de color ambar");
                break;
            case 2:
                [[self labelCheckPuertaAbriendo] setImage:[UIImage imageNamed:@"check-green"]];
                DDLogInfo(@"Marcamos el check mark de color verde");
                break;
            default:
                [[self labelCheckPuertaAbriendo] setImage:[UIImage imageNamed:@"check-grey"]];
                DDLogInfo(@"Marcamos el check mark de color GRIS");
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PathAct"
                                                    message:@"Hemos entrado en la zona"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    // Cambiamos la localización a precisión fina
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    DDLogInfo(@"Activando la precisión fina para la región");
    
    // Recuperamos la región que está siendo monitorizada
    Sitio* sitioAuxiliar = [[pathActModel sharedInstance] fetchSitioWithName:region.identifier];
    [[pathActModel sharedInstance] setSitioMonitorizado: sitioAuxiliar];
    
    [[pathActModel sharedInstance] set_didStartMonitoringRegion:YES];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PathAct"
                                                    message:@"Hemos salido de la zona"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    // Cambiamos la localización a cientos de metros
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    DDLogInfo(@"Desactivando la precisión fina");
    
    // Borramos la región que está siendo monitorizada
    [[pathActModel sharedInstance] setSitioMonitorizado:nil];
    [[pathActModel sharedInstance] set_didStartMonitoringRegion:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"No se pudo establecer la ubicación" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"pointSegue"]) {
        NSIndexPath *indexPath = [myTableView indexPathForSelectedRow];
        mapViewController *mapViewController = segue.destinationViewController;
        mapViewController.index = indexPath.row;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Maneja la pulsación manual del icono de la puerta
- (IBAction)botonAccionPuerta:(id)sender
{
    [[pathActModel sharedInstance] pulsacionPuerta];
}
@end
