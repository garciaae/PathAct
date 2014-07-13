//
//  _Sitio.h
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 12/04/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class _Punto;

@interface _Sitio : NSManagedObject

@property (nonatomic, retain) id cerca;
@property (nonatomic, retain) NSString * nombre;
@property (nonatomic) NSTimeInterval tiempoPaso;
@property (nonatomic, retain) NSSet *listaPuntos;
@end

@interface _Sitio (CoreDataGeneratedAccessors)

- (void)addListaPuntosObject:(_Punto *)value;
- (void)removeListaPuntosObject:(_Punto *)value;
- (void)addListaPuntos:(NSSet *)values;
- (void)removeListaPuntos:(NSSet *)values;

@end
