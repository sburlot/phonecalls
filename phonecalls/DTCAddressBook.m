//
//  DTCAddressBook.m
//  phonecalls
//
//  Created by Stephan on 27.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCAddressBook.h"
#import "RegExCategories.h"

@implementation DTCAddressBook

//==========================================================================================
+ (id)sharedInstance
{
    static DTCAddressBook* __sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[DTCAddressBook alloc] init];
    });

    return __sharedInstance;
}

//==========================================================================================
- (id)init
{
    self = [super init];
    _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    _contactList = [NSDictionary dictionary];
    [self checkAddressBookAccess];

    return self;
}

//==========================================================================================
- (void)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus()) {
    // Update our UI if the user has granted access to their Contacts
    case kABAuthorizationStatusAuthorized:
        [self accessGrantedForAddressBook];
        break;
    // Prompt the user for access to Contacts if there is no definitive answer
    case kABAuthorizationStatusNotDetermined:
        [self requestAddressBookAccess];
        break;
    // Display a message if the user has denied or restricted access to Contacts
    case kABAuthorizationStatusDenied:
    case kABAuthorizationStatusRestricted: {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"HammerTime"
                                                        message:@"Vous n'avez pas accès aux contacts."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } break;
    default:
        break;
    }
}

//==========================================================================================
// Prompt the user for access to their Address Book data
- (void)requestAddressBookAccess
{
    DTCAddressBook* __weak weakSelf = self;

    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
                                                 if (granted) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [weakSelf accessGrantedForAddressBook];
                                                     });
                                                 }
    });
}

//==========================================================================================
// This method is called when the user has granted access to their address book data.
- (void)accessGrantedForAddressBook
{
    // Load data from the plist file
    [self fetchAllAddressBookRecords];
}

//==========================================================================================
- (void)fetchAllAddressBookRecords
{
    CFArrayRef all = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    CFIndex n = ABAddressBookGetPersonCount(self.addressBook);
    NSLog(@"There are %ld contacts", n);
    NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionary];

    for (int i = 0; i < n; i++) {
        NSMutableString* displayName = [NSMutableString string];
        ABRecordRef ref = CFArrayGetValueAtIndex(all, i);
        NSString* firstName = (__bridge NSString*)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        NSString* lastName = (__bridge NSString*)ABRecordCopyValue(ref, kABPersonLastNameProperty);
        NSString* companyName = (__bridge NSString*)ABRecordCopyValue(ref, kABPersonOrganizationProperty);
        if ((firstName == NULL) && (lastName == NULL)) {
            [displayName appendString:companyName];
        } else {
            if (firstName != NULL) {
                [displayName appendString:firstName];
                [displayName appendString:@" "];
            }
            if (lastName != NULL) {
                [displayName appendString:lastName];
            }
            displayName = [[displayName replace:RX(@"\\s+$")
                                           with:@""] mutableCopy];
        }

        //        NSLog(@"Name %@ %@ (%@) => %@", firstName, lastName, companyName, displayName);
        ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phones); j++) {
            CFStringRef locLabel1 = ABMultiValueCopyLabelAtIndex(phones, j);
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
            if (phoneNumberRef != NULL) {
                NSString* phoneNumber = (__bridge NSString*)phoneNumberRef;
                phoneNumber = [phoneNumber replace:RX(@"\\s+|\\(|\\)|-|\\/|\\.")
                                              with:@""];
                phoneNumber = [phoneNumber replace:RX(@"^021")
                                              with:@"+4121"];
                phoneNumber = [phoneNumber replace:RX(@"^022")
                                              with:@"+4122"];
                phoneNumber = [phoneNumber replace:RX(@"^079")
                                              with:@"+4179"];
                phoneNumber = [phoneNumber replace:RX(@"^076")
                                              with:@"+4176"];
                phoneNumber = [phoneNumber replace:RX(@"^077")
                                              with:@"+4177"];
                phoneNumber = [phoneNumber replace:RX(@"^00")
                                              with:@"+"];
                NSString* phoneLabel1 = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(locLabel1);
                //                NSLog(@"%@ (%@) => %@", displayName, phoneLabel1, phoneNumber);
                [tempDictionary setObject:[NSString stringWithFormat:@"%@ (%@)", displayName, phoneLabel1]
                                   forKey:phoneNumber];
            }
        }
    }
    self.contactList = [tempDictionary copy];
}

//==========================================================================================
- (NSString*)findNameForPhoneNumber:(NSString*)phoneNumber
{
    __block NSString* personName = nil;
    phoneNumber = [phoneNumber replace:RX(@"\\s+|\\(|\\)|-|\\/|\\.")
                                  with:@""];
    [self.contactList enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *displayName, BOOL *stop)
    {
        if ([key isEqualToString:phoneNumber]) {
            personName = displayName;
            *stop = YES;
        }
    }];
    return personName;
}

//==========================================================================================
- (NSArray*)checkPhoneList:(NSArray*)phoneListArray
{
    NSMutableArray* responseArray = [NSMutableArray array];
    [phoneListArray enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
    {
        NSMutableDictionary* newDict = [dict mutableCopy];
        NSString* person = [self findNameForPhoneNumber:[dict objectForKey:@"phone"]];
        if (person != NULL) {
            [newDict setObject:person
                        forKey:@"name"];
        } else {
            [newDict setObject:@"Inconnu"
                        forKey:@"name"];
        }
        [responseArray addObject:newDict];
    }];
    return responseArray;
}

//==========================================================================================
- (NSDictionary*)checkPhoneCalls:(NSDictionary*)phoneCalls
{
    NSMutableDictionary* responseDict = [phoneCalls mutableCopy];

    [phoneCalls enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *phoneArray, BOOL *stop)
    {
        NSArray* responseArray = [self checkPhoneList:phoneArray];
        [responseDict setObject:responseArray
                         forKey:key];
    }];
    return responseDict;
}

@end
