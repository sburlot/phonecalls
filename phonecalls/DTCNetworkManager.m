//
//  DTCNetworkManager.m
//  phonecalls
//
//  Created by Stephan on 28.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCNetworkManager.h"
#import "AFNetworking.h"
#import "UIAlertView+AFNetworking.h"
#import "DTCAddressBook.h"

NSString * const DTCNetworkManagerRequestDone = @"ch.coriolis.dtcnetworkmanager.done";

@implementation DTCNetworkManager

//==========================================================================================
+ (id) sharedInstance
{
    static DTCNetworkManager *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[DTCNetworkManager alloc] init];
    });
    
    return __sharedInstance;
}

//==========================================================================================
- (id) init
{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(HTTPOperationDidFinish:)
                                                 name:AFNetworkingOperationDidFinishNotification
                                               object:nil];
    
    self.networkCallInProgress = NO;
    return self;
}

//==========================================================================================
- (void) loadFromServerWithSuccess:(void (^)(id responseObject))success
                           failure:(void (^)(NSError *error))failure
{
    if (self.networkCallInProgress)
        return;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"calls.plist"];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    self.networkCallInProgress = YES;
    [manager GET:SERVER_URL parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
//        NSLog(@"JSON: %@", responseObject);
        NSDictionary *responseDict = [[DTCAddressBook sharedInstance] checkPhoneCalls:responseObject];
        [(NSDictionary *)responseDict writeToFile:path atomically:YES];
        [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:@"last_update"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.networkCallInProgress = NO;
        if (success)
            success(responseDict);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [[NSUserDefaults standardUserDefaults] setDouble:0.0f forKey:@"last_update"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.networkCallInProgress = NO;
        if (failure)
            failure(error);
    }];
}

//==========================================================================================
- (void) HTTPOperationDidFinish:(NSNotification *)notification
{
    AFHTTPRequestOperation *operation = (AFHTTPRequestOperation *)[notification object];
    if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        return;
    }

    if (operation.error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Erreur de connexion"
                                                        message:@"Vous n'êtes pas connecté à internet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}

//==========================================================================================
- (void) getCallsForceReload:(BOOL)force
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure

{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"calls.plist"];
    NSTimeInterval timeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:@"last_update"];
    NSDate *last_update = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSLog(@"last_update: %@", last_update);
    NSLog(@"interval: %.2f", [[NSDate date] timeIntervalSinceDate:last_update]);
    NSDictionary *responseDict = [[NSDictionary alloc] initWithContentsOfFile:path];
    if (force || (responseDict == nil) || ([[NSDate date] timeIntervalSinceDate:last_update] > 5*60)) {
        [self loadFromServerWithSuccess:success
                                failure:failure];
    } else {
        success(responseDict);
    }
}

@end
