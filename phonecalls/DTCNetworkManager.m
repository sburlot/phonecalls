//
//  DTCNetworkManager.m
//  phonecalls
//
//  Created by Stephan on 28.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCNetworkManager.h"
#import "STHTTPRequest.h"
#import "DTCAddressBook.h"
#import "Reachability.h"
#import "PRPAlertView.h"

@interface DTCNetworkManager()

@property (nonatomic, strong) Reachability *hostReachability;
@property (nonatomic, strong) Reachability *internetReachability;

@end

@implementation DTCNetworkManager

//==========================================================================================
+ (id)sharedInstance
{
    static DTCNetworkManager* __sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[DTCNetworkManager alloc] init];
    });

    return __sharedInstance;
}

//==========================================================================================
- (id)init
{
    self = [super init];

    // http://stackoverflow.com/questions/12490578/should-i-listen-for-reachability-updates-in-each-uiviewcontroller#12490864

    self.networkCallInProgress = NO;
    self.hostReachability = [Reachability reachabilityWithHostName:SERVER_URL];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    self.status = UnknownStatus;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self.internetReachability startNotifier];

    return self;
}

//==========================================================================================
- (void)loadFromServerWithSuccess:(void (^)(id responseObject))success
                          failure:(void (^)(NSDictionary *storedObject, NSError* error))failure
{
    if (self.networkCallInProgress)
        return;

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"calls.plist"];

    STHTTPRequest *r = [STHTTPRequest requestWithURL:[NSURL URLWithString:SERVER_URL]];
    self.networkCallInProgress = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    r.completionBlock = ^(NSDictionary *headers, NSString *body)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSError* error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&error];
        if ((json == nil) || (error)) {
            NSLog(@"Error: %@", error);
            if (failure)
                failure(nil, error);
            return;
        } else {
        //        NSLog(@"JSON: %@", responseObject);
        NSDictionary* responseDict = [[DTCAddressBook sharedInstance] checkPhoneCalls:json];
        [(NSDictionary*)responseDict writeToFile:path
                                      atomically:YES];
        [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970]
                                                  forKey:@"last_update"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.networkCallInProgress = NO;
        if (success)
            success(responseDict);
        }
    };
    r.errorBlock = ^(NSError * error)
    {
        NSString *errorMessage;
        NetworkStatus internetStatus = [self.internetReachability currentReachabilityStatus];
        NetworkStatus netStatus = [self.hostReachability currentReachabilityStatus];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[NSUserDefaults standardUserDefaults] setDouble:0.0f
                                                  forKey:@"last_update"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.networkCallInProgress = NO;
        NSDictionary* responseDict = [[NSDictionary alloc] initWithContentsOfFile:path];
        if (internetStatus == NotReachable) {
            errorMessage = @"L'accès internet n'est pas disponible.";
        } else {
            if (netStatus == NotReachable) {
                errorMessage = @"Le serveur n'est pas accessible.";
            } else {
                errorMessage = [NSString stringWithFormat:@"Erreur lors de l'accès aux données (%@).", [error localizedDescription]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [PRPAlertView showWithTitle:@"Erreur" message:errorMessage buttonTitle:@"OK"];
        });

        if (failure)
            failure(responseDict, error);
    };
    [r startAsynchronous];
}

//==========================================================================================
- (void)getCallsForceReload:(BOOL)force
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSDictionary *storedObject, NSError* error))failure

{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"calls.plist"];
    NSTimeInterval timeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:@"last_update"];
    NSDate* last_update = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSLog(@"last_update: %@", last_update);
    NSLog(@"interval: %.2f", [[NSDate date] timeIntervalSinceDate:last_update]);
    NSDictionary* responseDict = [[NSDictionary alloc] initWithContentsOfFile:path];
#ifdef DEMO
    return success(responseDict);
#endif
    if (force || (responseDict == nil) || ([[NSDate date] timeIntervalSinceDate:last_update] > 5 * 60)) {
        [[DTCAddressBook sharedInstance] reloadAllAddressBookRecords];
        [self loadFromServerWithSuccess:success
                                failure:failure];
    } else {
        success(responseDict);
    }
}

//==========================================================================================
- (void)reachabilityChanged:(NSNotification*)note
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus) {
        case NotReachable:
            NSLog(@"Internet is not reachable");
            self.status = InternetNotReachableStatus;
            break;
        case ReachableViaWiFi:
            NSLog(@"Internet is reachable via Wifi");
            self.status = ReachableStatus;
            break;
        case ReachableViaWWAN:
            NSLog(@"Internet is reachable via WWAN");
            self.status = ReachableStatus;
            break;
        default:
            break;
    }
    if (self.status == ReachableStatus) {
        [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_NOTIFICATION object:nil];
    }
}

@end
