//
//  DTCCallViewController.m
//  phonecalls
//
//  Created by Stephan on 29.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "PRPAlertView.h"
#import "DTCNetworkManager.h"
#import "Reachability.h"
#import "STHTTPRequest.h"
#import "DTCCallerInfoViewController.h"
#import "DTCCallViewController.h"
#import "DTCCell.h"

@interface DTCCallViewController ()

@property(strong, nonatomic) NSArray* phoneCalls;
@property(strong, nonatomic) NSDateFormatter* dateFormatter;
@property(nonatomic, assign) BOOL lastCallSuccessful;
@property(strong, nonatomic) STHTTPRequest *localRequest;
@property(nonatomic) BOOL networkCallInProgress;
@property (nonatomic, strong) Reachability *hostReachability;
@property (nonatomic, strong) Reachability *internetReachability;

@end

@implementation DTCCallViewController

//==========================================================================================
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.networkCallInProgress = NO;
    DTCConnectionStatus dtcStatus = [[DTCNetworkManager sharedInstance] status];

    NSLog(@"%s :%@, %@", __PRETTY_FUNCTION__, self.lastCallSuccessful ? @"lastCallSuccessful: YES":@"lastCallSuccessful: NO", dtcStatus == InternetNotReachableStatus ? @"InternetNotReachableStatus: YES":@"InternetNotReachableStatus: NO");

    NSAssert(self.callKind.length != 0, @"You MUST change callKind!");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshNotification:)
                                                 name:REFRESH_NOTIFICATION
                                               object:nil];

    if ((self.lastCallSuccessful == YES) || (dtcStatus == ReachableStatus)) {
        [self refreshData:NO];
    }
}

//==========================================================================================
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.callKind = @"";
    self.title = @"You forgot to set the title!";

    self.lastCallSuccessful = YES;

    self.hostReachability = [Reachability reachabilityWithHostName:SERVER_URL];
    self.internetReachability = [Reachability reachabilityForInternetConnection];

    UIRefreshControl* refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self
                  action:@selector(forceReload)
        forControlEvents:UIControlEventValueChanged];

    [self.tableView registerNib:[UINib nibWithNibName:@"DTCCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"DTCCell"];

    self.refreshControl = refresh;

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];

    self.tableView.allowsSelection = YES;
    self.tableView.rowHeight = 55.f;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 15);

    // Only supported on iOS8
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
}

//==========================================================================================
- (void) refreshData:(BOOL)force
{
    [[DTCNetworkManager sharedInstance] getCallsForceReload:force
                                                    success:^(id responseObject) {
                                                        self.phoneCalls = [responseObject objectForKey:_callKind];
                                                        [self.tableView reloadData];
                                                        [self.refreshControl endRefreshing];
                                                        self.lastCallSuccessful = YES;
                                                    }
                                                    failure: ^(NSDictionary *responseObject, NSError * error) {
                                                        self.phoneCalls = [responseObject objectForKey:_callKind];
                                                        [self.tableView reloadData];
                                                        [self.refreshControl endRefreshing];
                                                        self.lastCallSuccessful = NO;
                                                    }
     ];
}

//==========================================================================================
- (void) getNameFromPhoneBook:(NSString *)phoneNumber indexPath:(NSIndexPath *) indexPath
{
    if (self.networkCallInProgress)
        return;

    // URL to access local.ch
    // MAY CHANGE OR BREAK AT ANYTIME. You've been warned.
    // AND DONT ABUSE THIS URL. PLEASE BE KIND.
    NSString *localURL = @"http://www.local.ch/en/api/as3/suggestwhatwhere?focus=what&hl=markup&lang=en&slot=web&what=%@&where=&wt=json";

    DTCCallViewController* __weak weakSelf = self;

    NSString *cleanedPhoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
    if (![cleanedPhoneNumber hasPrefix:@"+41"]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Non, non."
                                                        message:@"Vous ne pouvez chercher que les numéros suisses."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSString *theURL = [NSString stringWithFormat:localURL, cleanedPhoneNumber];
    self.localRequest = [STHTTPRequest requestWithURL:[NSURL URLWithString:theURL]];
    _localRequest.timeoutSeconds = 5;
    self.networkCallInProgress = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.localRequest.completionBlock = ^(NSDictionary *headers, NSString *body)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSError* error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&error];
        if ((json == nil) || (error)) {
            NSString *errorMessage = nil;
            if (error) {
                errorMessage = [NSString stringWithFormat:@"%@", error];
            } else {
                errorMessage = @"Réponse JSON incorrecte.";
            }
            NSLog(@"Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [PRPAlertView showWithTitle:@"Erreur" message:errorMessage buttonTitle:@"OK"];
            });
        } else {
            NSString *info = @"Pas de nom trouvé";
            if ([[json objectForKey:@"autosuggest"] count] > 0) {
                NSDictionary *response = [[json objectForKey:@"autosuggest"] objectAtIndex:0];
                if (response) {
                     info = [NSString stringWithFormat:@"%@\n%@", [response objectForKey:@"what"], [response objectForKey:@"where"]];
                }
            }
            [weakSelf displayPopOverWithInfo:info indexPath:indexPath];
            _networkCallInProgress = NO;
            // Show the found value, if any.
        }
    };
    self.localRequest.errorBlock = ^(NSError * error)
    {
        NSString *errorMessage = nil;
        NetworkStatus internetStatus = [weakSelf.internetReachability currentReachabilityStatus];
        NetworkStatus netStatus = [weakSelf.hostReachability currentReachabilityStatus];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        weakSelf.networkCallInProgress = NO;
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
    };
    [_localRequest startAsynchronous];

}

//==========================================================================================
- (void)forceReload
{
    [self.refreshControl beginRefreshing];
    [self refreshData:YES];
}

//==========================================================================================
- (void) displayPopOverWithInfo:(NSString *)info indexPath:(NSIndexPath*)indexPath
{
    DTCCallerInfoViewController *vc = [DTCCallerInfoViewController new];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = vc.view.frame.size;
    vc.info = info;
    UIPopoverPresentationController *presentationController = [vc popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionUnknown;
    presentationController.sourceView = self.tableView;
    presentationController.delegate = self;
    CGRect frame = [self.tableView rectForRowAtIndexPath:indexPath];
    presentationController.sourceRect = frame;
    [self presentViewController:vc animated:YES completion:^{
    }];
}

//==========================================================================================
- (void) shouldCallNumberAtRow:(NSInteger) row
{
    // Call button was pressed
    NSDictionary* dict = [self.phoneCalls objectAtIndex:row];
    [PRPAlertView showWithTitle:@"Appels"
                        message:[NSString stringWithFormat:@"Appeler %@?", [dict objectForKey:@"phone"]]
                    cancelTitle:@"Annuler"
                    cancelBlock:nil
                     otherTitle:@"OK"
                     otherBlock:^{
                         NSString *cleanedString = [[[dict objectForKey:@"phone"] componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
                         NSString *phoneNumber = [@"tel://" stringByAppendingString:cleanedString];
                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
                     }];
}

//==========================================================================================
- (void)refreshNotification:(NSNotification*)note
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    DTCConnectionStatus dtcStatus = [[DTCNetworkManager sharedInstance] status];
    if (dtcStatus != InternetNotReachableStatus) {
        [self refreshData:NO];
    }
}

//==========================================================================================
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

#pragma mark - TableView datasource
//==========================================================================================
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.261 green:0.738 blue:0.617 alpha:1.000]
                                                title:@"C'est qui?"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Appeler"];

    return rightUtilityButtons;
}

//==========================================================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

//==========================================================================================
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.phoneCalls.count;
}

//==========================================================================================
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"DTCCell";

    DTCCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    NSDictionary* dict = [self.phoneCalls objectAtIndex:indexPath.row];
    cell.phoneLabel.text = [dict objectForKey:@"phone"];
    NSDate* date = [self.dateFormatter dateFromString:[dict objectForKey:@"date"]];
    cell.dateLabel.text = [NSDateFormatter localizedStringFromDate:date
                                                         dateStyle:NSDateFormatterShortStyle
                                                         timeStyle:NSDateFormatterShortStyle];
    cell.nameLabel.text = [dict objectForKey:@"name"];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;

    return cell;
}

//==========================================================================================
#pragma mark - TableView delegates
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath
                                  animated:YES];

}

#pragma mark - SWTableViewCellDelegate
//==========================================================================================
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
   NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
   switch (index) {
        case 0:
        {
            // Who's that button was pressed
            NSDictionary* dict = [self.phoneCalls objectAtIndex:indexPath.row];
            [self getNameFromPhoneBook:[dict objectForKey:@"phone"] indexPath:indexPath];
            break;
        }
        case 1:
        {
            // Call button was pressed
            [self shouldCallNumberAtRow:indexPath.row];
            break;
        }
        default:
            break;
    }
    [cell hideUtilityButtonsAnimated:YES];
}

//==========================================================================================
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

//==========================================================================================
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    // set to NO to disable all left utility buttons appearing
    return YES;
}

@end
