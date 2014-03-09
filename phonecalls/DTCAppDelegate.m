//
//  DTCAppDelegate.m
//  phonecalls
//
//  Created by Stephan on 22.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCAppDelegate.h"
#import "DTCAnsweredCallsViewController.h"
#import "DTCMissedCallsViewController.h"
#import "DTCAddressBook.h"

@implementation DTCAppDelegate

//==========================================================================================
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIViewController* viewController1 = [[DTCAnsweredCallsViewController alloc] init];
    UINavigationController* navController1 = [[UINavigationController alloc] initWithRootViewController:viewController1];
    navController1.title = @"Appels Reçus";
    navController1.tabBarItem.image = [UIImage imageNamed:@"answered.png"];

    UIViewController* viewController2 = [[DTCMissedCallsViewController alloc] init];
    UINavigationController* navController2 = [[UINavigationController alloc] initWithRootViewController:viewController2];
    navController2.title = @"Appels Manqués";
    navController2.tabBarItem.image = [UIImage imageNamed:@"missed.png"];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[
                                              navController1,
                                              navController2
                                              ];
    self.tabBarController.delegate = self;
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    [DTCAddressBook sharedInstance];

    return YES;
}

//==========================================================================================
- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

//==========================================================================================
- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

//==========================================================================================
- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

//==========================================================================================
- (void)applicationDidBecomeActive:(UIApplication*)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil];
}

//==========================================================================================
- (void)applicationWillTerminate:(UIApplication*)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
