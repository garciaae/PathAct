//
//  _Punto.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 12/04/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class _Sitio;

@interface _Punto : NSManagedObject

@property (nonatomic) NSTimeInterval horaPaso;
@property (nonatomic) double latitud;
@property (nonatomic) double longitud;
@property (nonatomic) int32_t ordenPaso;
@property (nonatomic, retain) _Sitio *sitio;

@end
