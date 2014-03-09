//
//  DTCNetworkManager.h
//  phonecalls
//
//  Created by Stephan on 28.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
	UnknownStatus = 0,
    InternetNotReachableStatus,
	HostNotReachableStatus,
    ReachableStatus
} DTCConnectionStatus;

@interface DTCNetworkManager : NSObject

@property(nonatomic) BOOL networkCallInProgress;
@property(nonatomic) DTCConnectionStatus status;

+ (id)sharedInstance;
- (void)loadFromServerWithSuccess:(void (^)(id responseObject))success
                          failure:(void (^)(NSDictionary *storedObject, NSError* error))failure;
- (void)getCallsForceReload:(BOOL)force
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSDictionary *storedObject, NSError* error))failure;

@end
