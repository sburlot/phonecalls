//
//  DTCCallViewController.m
//  phonecalls
//
//  Created by Stephan on 29.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCCallViewController.h"
#import "DTCCell.h"
#import "PRPAlertView.h"
#import "DTCNetworkManager.h"
#import "Reachability.h"

@interface DTCCallViewController ()

@property(strong, nonatomic) NSArray* phoneCalls;
@property(strong, nonatomic) NSDateFormatter* dateFormatter;
@property(nonatomic, assign) BOOL lastCallSuccessful;

@end

@implementation DTCCallViewController

//==========================================================================================
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    DTCConnectionStatus dtcStatus = [[DTCNetworkManager sharedInstance] status];

    NSLog(@"%s :%@, %@", __PRETTY_FUNCTION__, self.lastCallSuccessful ? @"lastCallSuccessful: YES":@"lastCallSuccessful: NO", dtcStatus == InternetNotReachableStatus ? @"InternetNotReachableStatus: YES":@"InternetNotReachableStatus: NO");
    // The fix below doesn't work:

    //  Fix UITableViewController offset due to UIRefreshControl in iOS 7
    // http://stackoverflow.com/questions/19240915/fix-uitableviewcontroller-offset-due-to-uirefreshcontrol-in-ios-7
    /*
     self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Rafraichir"
     attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
     NSUnderlineStyleAttributeName : @1 ,
     NSStrokeColorAttributeName : [UIColor blackColor]}
     ];
     */
    // Setting the string inside viewDidLoad: messes up iOS's layout of the control+tableview,
    // but it's ok within viewWillAppear: or later once the geometry is set.

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

    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

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
- (void)forceReload
{
    [self.refreshControl beginRefreshing];
    [self refreshData:YES];
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

#pragma mark - TableView datasource

//==========================================================================================
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];

    return rightUtilityButtons;
}

//==========================================================================================
- (CGFloat)tableView:(UITableView*)aTableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 65.0f;
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
    NSString* name = [dict objectForKey:@"name"];
    if (name != NULL) {
        name = @"Inconnu";
    }
    cell.nameLabel.text = [dict objectForKey:@"name"];
    cell.rightUtilityButtons = [self rightButtons];
    return cell;
}

//==========================================================================================
#pragma mark - TableView delegates
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath
                                  animated:YES];

    NSDictionary* dict = [self.phoneCalls objectAtIndex:indexPath.row];
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

#pragma mark - SWTableViewDelegate

//==========================================================================================
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    switch (state) {
        case 0:
            NSLog(@"utility buttons closed");
            break;
        case 1:
            NSLog(@"left utility buttons open");
            break;
        case 2:
            NSLog(@"right utility buttons open");
            break;
        default:
            break;
    }
}

//==========================================================================================
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            NSLog(@"left button 0 was pressed");
            break;
        case 1:
            NSLog(@"left button 1 was pressed");
            break;
        case 2:
            NSLog(@"left button 2 was pressed");
            break;
        case 3:
            NSLog(@"left btton 3 was pressed");
        default:
            break;
    }
}

//==========================================================================================
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSLog(@"More button was pressed");
            UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Hello" message:@"More more more" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles: nil];
            [alertTest show];

            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];

            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            break;
        }
        default:
            break;
    }
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
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            return YES;
            break;
        case 2:
            // set to NO to disable all right utility buttons appearing
            return YES;
            break;
        default:
            break;
    }

    return YES;
}

@end
