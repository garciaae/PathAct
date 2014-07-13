//
//  pathActAppDelegate.m
//  PathAct
//
//  Created by Alejandro Garcia Andrade on 09/03/14.
//  Copyright (c) 2014 Alejandro Garcia Andrade. All rights reserved.
//

#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#import "pathActAppDelegate.h"
#import "pathActViewController.h"
#import "pathActModel.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif


@implementation pathActAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configuramos LumberJack
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
    
    // Rota el fichero cada 24 horas (es decir que habrá un fichero por día)
    fileLogger.rollingFrequency = 60 * 60 * 24;
    // Limitamos a 5 ficheros (5 días) el log en disco
    fileLogger.logFileManager.maximumNumberOfLogFiles = 5;
    
    [DDLog addLogger:fileLogger];
    
    NSManagedObjectContext *context = [[pathActModel sharedInstance] mainContext];
    if (context) {
        DDLogVerbose(@"Context is ready!");
    } else {
        DDLogVerbose(@"Context was nil :");
    }
    
    // Leemos las properties del fichero
    [self readPropertiesList];
    
    return YES;
}

-(void) readPropertiesList
{
    if (self) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Properties.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            plistPath = [[NSBundle mainBundle] pathForResource:@"Properties" ofType:@"plist"];
        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                              propertyListFromData:plistXML
                                              mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                              format:&format
                                              errorDescription:&errorDesc];
        if (!temp) {
            DDLogError(@"Error reading plist: %@, format: %u", errorDesc, format);
        }
        
        [[pathActModel sharedInstance] setDistanceForDetection:[temp objectForKey:@"distanceForDetection"]];
        [[pathActModel sharedInstance] setPulsacionMinima:[temp objectForKey:@"minimumPressDuration"]];
        [[pathActModel sharedInstance] setUrlWebServer:[temp objectForKey:@"urlWebServer"]];
        
    }
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
