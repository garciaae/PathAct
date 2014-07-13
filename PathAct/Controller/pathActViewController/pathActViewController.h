//
//  pathActViewController.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 09/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "pathActModel.h"

@interface pathActViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>{
    BOOL _didStartMonitoringRegion;
    IBOutlet UITableView *myTableView;
    }
- (IBAction)botonAccionPuerta:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *labelCheckPuertaAbriendo;
#pragma Mark - Properties
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *geofences;
// Puntero al modelo
@property (nonatomic,retain) pathActModel *model;

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;

// Marcamos la puerta del color indicado por el parámetro 0 = gris, 1 = verde
-(void) doorActionNotificationReceived:(NSNotification *) notification;
@end
