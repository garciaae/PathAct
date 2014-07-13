//
//  mapViewController.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 23/03/14.
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

#import "mapViewController.h"
#import "Punto.h"

@interface mapViewController ()

@end

@implementation mapViewController

@synthesize model;
@synthesize sitioActual;
@synthesize sliderTiempoPaso;
@synthesize labelTiempoPaso;

- (void) pointReachedNotificationReceived:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"pointReachedNotification"])
    {
        NSDictionary *dict = [notification userInfo];
        Punto* puntoAux = (Punto*)[dict objectForKey:@"1"];
        DDLogInfo(@"Recibimos el punto con orden %d", puntoAux.ordenPaso);
        //PACTMapAnnotation* toDelete = nil;
        
        for (id <MKAnnotation> annotationAux in [self.mapView annotations])
        {
            if(![annotationAux isKindOfClass:[MKUserLocation class]] && [(PACTMapAnnotation *)annotationAux pinIndex] == puntoAux.ordenPaso)
            {
                //toDelete = annotationAux;
                [self.mapView removeAnnotation:annotationAux];
                // Creamos una anotación con las coordenadas del punto pasado como parámetro y la añadimos al mapa
                PACTMapAnnotation *toAdd = [[PACTMapAnnotation alloc]init];
                toAdd.coordinate = CLLocationCoordinate2DMake(puntoAux.latitud, puntoAux.longitud);
                
                // Añadimos el orden de paso para después mostrar la imagen adecuada
                toAdd.pinIndex = puntoAux.ordenPaso;
                toAdd.colorDelPin = @"R";
                [self.mapView addAnnotation:toAdd];
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Registramos el método que recibirá la información del paso por el punto
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pointReachedNotificationReceived:)
                                                 name:@"pointReachedNotification"
                                               object:nil];
    
    // Establecemos que esta vista sea el delegado del mapView
    [self.mapView setDelegate:self];
    
    // Mostramos la localización en el mapa
    [self.mapView setShowsUserLocation:YES];
    
    // Recuperamos el modelo
    model = [pathActModel sharedInstance];
    
    // Establecemos el tamaño de la vista del mapa usando el índice que hemos pasado como parámetro
    self.mapView.region = MKCoordinateRegionMakeWithDistance([(CLCircularRegion *)[[[model listaDeSitios] objectAtIndex:[self index]] cerca] center], 500, 500);
    
    // Añadir el gesture recogniser
    [self addGestureRecogniserToMapView];

    // Añadir los pines:
    // Traemos el sitio de la base de datos basándonos en el que hemos picado de la TableView
    sitioActual = [model fetchSitioWithName:[[[model listaDeSitios] objectAtIndex:[self index]] nombre]];
    
    // Recorremos los puntos
    [self addAnnotationsToMapFromSitio:sitioActual];
    
    [self addUISliderToMapView];
    
    // Cargamos el valor de la base de datos
    self.sliderTiempoPaso.value = self.sitioActual.tiempoPaso / 60;
    
    int32_t minutos = truncf(self.sliderTiempoPaso.value);
    int32_t segundos = (self.sliderTiempoPaso.value - minutos) * 60;
    
    labelTiempoPaso.text = [NSString stringWithFormat: @"%02d:%02d", minutos, segundos];
}

// Usamos los puntos del sitio para añadir anotaciones
-(void) addAnnotationsToMapFromSitio:(Sitio*) paramSitio
{
    // Recorremos los puntos
    for (Punto* puntoAuxiliar in [paramSitio listaPuntos])
    {
        // Creamos una anotación y la añadimos al mapa
        PACTMapAnnotation *toAdd = [[PACTMapAnnotation alloc]init];
        CLLocationCoordinate2D coordenadaPin =  CLLocationCoordinate2DMake(puntoAuxiliar.latitud, puntoAuxiliar.longitud);
        toAdd.coordinate = coordenadaPin;
        
        // Ponemos el orden en una propiedad para recuperarlo en el viewForAnnotation y mostrar así la imagen correcta del pin
        if (puntoAuxiliar)
        {
            toAdd.pinIndex = [puntoAuxiliar ordenPaso];
            // Si la distancia al punto es menor a 10m lo coloreamos de rojo
             double distancia =  [[Punto getLocationFromPunto:puntoAuxiliar] distanceFromLocation:[[[self mapView] userLocation] location]];
            if (distancia  < [[[pathActModel sharedInstance] distanceForDetection] doubleValue] && distancia >= 0)
            {
                toAdd.colorDelPin = @"R";
            }
            else
            {
                toAdd.colorDelPin = @"";
            }
            
        }
        // Añadimos la anotación al mapa
        [self.mapView addAnnotation:toAdd];
    }
}

// Preparamos los parámetros para el slider
-(void) addUISliderToMapView{
    // Preparamos los parámetros para el slider
    [[self sliderTiempoPaso] setMaximumValue: 1.0f];
    [[self sliderTiempoPaso] setMaximumValue:10.0f];
    [[self sliderTiempoPaso] setValue:5.0f];
    [[self sliderTiempoPaso] setContinuous:NO];
    [sliderTiempoPaso addTarget:self
                         action:@selector(seleccionSliderTiempoPaso:)
               forControlEvents:UIControlEventValueChanged];
}

- (void) seleccionSliderTiempoPaso:(UISlider *)paramSender{
    // Aquí código para mandar al modelo el valor en segundos
    //NSLog(@"Se ha seleccionado %f", paramSender.value);
    [[self model] setTiempoPaso:paramSender.value * 60  inSitio:sitioActual];
    
    int32_t minutos = truncf(paramSender.value);
    int32_t segundos = (paramSender.value - minutos) * 60;
    
    labelTiempoPaso.text = [NSString stringWithFormat: @"%02d:%02d", minutos, segundos];
    //[self labelTiempoPaso setText:[NSString stringwith] ];
}

#pragma Mark - Gesture recogniser
- (void)addGestureRecogniserToMapView{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(addPinToMap:)];
    lpgr.minimumPressDuration = [[[pathActModel sharedInstance] pulsacionMinima] doubleValue];
    [self.mapView addGestureRecognizer:lpgr];
}

// Implementa la lógica de añadir un pin en el mapa
- (void)addPinToMap:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ){
        // El sitio sobre el que operamos
        Sitio *sitioActualLocal = [[model listaDeSitios] objectAtIndex:[self index]];
        if ([[sitioActualLocal listaPuntos] count] < 3)
        {
            // Traducimos las coordenadas de la pulsación a coordenadas del mapa
            CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
            CLLocationCoordinate2D touchMapCoordinate =
            [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
            
            // Creamos una anotación y la añadimos al mapa
            PACTMapAnnotation *toAdd = [[PACTMapAnnotation alloc]init];
            toAdd.coordinate = touchMapCoordinate;
            
            // Añadimos el orden de paso para después mostrar la imagen adecuada
            toAdd.pinIndex = (int32_t)[[sitioActualLocal listaPuntos] count] + 1;
            
            // Añadimos el color (vacío = por defecto, R = rojo)
            toAdd.colorDelPin = @"";            
            [self.mapView addAnnotation:toAdd];
            
            // Asignar punto al sitio actual (necesitamos las coordenadas del pin)
            Punto *puntoNuevo = [Punto puntoWithContext:[[self model] mainContext]];
            
            // Asignamos las coordenadas del sitio en el que hemos tocado
            [puntoNuevo setLongitud:touchMapCoordinate.longitude];
            [puntoNuevo setLatitud:touchMapCoordinate.latitude];
            
            // El orden de paso será el de creación
            [puntoNuevo setOrdenPaso:(int32_t)[[sitioActualLocal listaPuntos] count] + 1];
            
            // Enlazamos con el sitio
            [puntoNuevo setSitio:sitioActualLocal];
            [model addPunto:puntoNuevo ToSitio:sitioActualLocal];
        }
        else{
            DDLogWarn(@"Ya hay tres pines en el mapa");
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Borra todas las anotaciones
- (IBAction)deleteMapAnnotationsTouchUpInside:(id)sender {
    // Borramos los puntos de la vista
    [self.mapView removeAnnotations: self.mapView.annotations];
    
    // Borramos los puntos enlazados con el sitio
    [model removePuntosFromSitio:[self sitioActual]];
}

// Prepara la anotación que se mostrará en el mapa
- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id) annotation {
    MKAnnotationView * salida = nil;
    
    if (annotation == self.mapView.userLocation) {
        salida = nil;
    }
    else
    {
        PACTMapAnnotation *anotacion1 = (PACTMapAnnotation*)annotation;
        MKAnnotationView *aView = [[MKAnnotationView alloc] initWithAnnotation:anotacion1 reuseIdentifier:@"pinView"];
        
        NSString* colorParaPintar;
        if ([annotation colorDelPin] == nil)
        {
            colorParaPintar = @"";
        }
        else
        {
            colorParaPintar = [annotation colorDelPin];
            [[pathActModel sharedInstance] playSound:[annotation pinIndex]];
        }
        
        NSString *icoName = [NSString stringWithFormat:@"place-%d-32%@.png", [annotation pinIndex], colorParaPintar];
        
        aView.canShowCallout = YES;
        aView.enabled = YES;
        aView.centerOffset = CGPointMake(0, -20);
        
        aView.draggable = YES;
        
        UIImage *imagen = [UIImage imageNamed:icoName];
        
        aView.image = imagen;
        CGRect frame = aView.frame;
        frame.size.width = 32;
        frame.size.height = 32;
        aView.frame = frame;   
        
        salida = aView;
    }
    return salida;
}

// Al descargar la vista, desactivamos el observador
- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
