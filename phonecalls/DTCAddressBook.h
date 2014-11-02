//
//  DTCAddressBook.h
//  phonecalls
//
//  Created by Stephan on 27.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface DTCAddressBook : NSObject

@property(nonatomic, assign) ABAddressBookRef addressBook;
@property(nonatomic) NSDictionary* contactList;

+ (id)sharedInstance;
- (void)fetchAllAddressBookRecords;
- (void)checkAddressBookAccess;
- (NSDictionary*)checkPhoneCalls:(NSDictionary*)phoneCalls;
- (void)reloadAllAddressBookRecords;

@end
