//
//  DTCNetworkManager.h
//  phonecalls
//
//  Created by Stephan on 28.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DTCNetworkManagerRequestDone;

@interface DTCNetworkManager : NSObject

@property (nonatomic) BOOL networkCallInProgress;
+ (id)sharedInstance;
- (void) loadFromServerWithSuccess:(void (^)(id responseObject))success
                           failure:(void (^)(NSError *error))failure;
- (void) getCallsForceReload:(BOOL)force
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure;


@end
