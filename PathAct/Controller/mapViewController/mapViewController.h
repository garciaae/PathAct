//
//  mapViewController.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 23/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "pathActModel.h"
#import "PACTMapAnnotation.h"
#import "Sitio.h"

@interface mapViewController : UIViewController <MKMapViewDelegate>

#pragma mark - Properties
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLRegion *geofence;
@property NSInteger index;
@property pathActModel* model;
@property Sitio* sitioActual;

#pragma Mark - Controles
@property (weak, nonatomic) IBOutlet UILabel *labelTiempoPaso;
@property (weak, nonatomic) IBOutlet UISlider *sliderTiempoPaso;

#pragma mark - IBActions
- (IBAction)deleteMapAnnotationsTouchUpInside:(id)sender;

#pragma mark - Delegates
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void) pointReachedNotificationReceived:(NSNotification *) notification;

-(void) addAnnotationsToMapFromSitio:(Sitio*) paramSitio;
@end
