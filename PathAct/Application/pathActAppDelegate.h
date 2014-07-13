//
//  pathActAppDelegate.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 09/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface pathActAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;

// Al cargar la aplicación cargamos la lista de propiedades
-(void) readPropertiesList;

@end
