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

@interface DTCCallViewController ()

@property (strong, nonatomic) NSArray *phoneCalls;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation DTCCallViewController

//==========================================================================================
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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

    [[DTCNetworkManager sharedInstance] getCallsForceReload:NO
                                                    success:^(id responseObject) {
                                                        self.phoneCalls = [responseObject objectForKey:_callKind];
                                                        [self.tableView reloadData];
                                                    } failure:^(NSError *error) {
                                                        self.phoneCalls = [NSArray array];
                                                        [self.tableView reloadData];
                                                    }];
    
}

//==========================================================================================
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.callKind = @"";
    self.title = @"You forgot to set the title!";

    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self
                action:@selector(forceReload)
      forControlEvents:UIControlEventValueChanged];
    
 	[self.tableView registerNib:[UINib nibWithNibName:@"DTCCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"DTCCell"];
    
    self.refreshControl = refresh;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];

    self.tableView.allowsSelection = YES;
    
}

//==========================================================================================
- (void) forceReload
{
    [self.refreshControl beginRefreshing];
    [[DTCNetworkManager sharedInstance] getCallsForceReload:YES
                                                    success:^(id responseObject) {
                                                        self.phoneCalls = [responseObject objectForKey:_callKind];
                                                        [self.tableView reloadData];
                                                        [self.refreshControl endRefreshing];
                                                    } failure:^(NSError *error) {
                                                        self.phoneCalls = [NSArray array];
                                                        [self.tableView reloadData];
                                                        [self.refreshControl endRefreshing];
                                                    }];
}

#pragma mark - TableView datasource

//==========================================================================================
- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

//==========================================================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//==========================================================================================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.phoneCalls.count;
}

//==========================================================================================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"DTCCell";
    
    DTCCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    NSDictionary *dict = [self.phoneCalls objectAtIndex:indexPath.row];
    cell.phoneLabel.text = [dict objectForKey:@"phone"];
    NSDate *date = [self.dateFormatter dateFromString:[dict objectForKey:@"date"]];
    cell.dateLabel.text = [NSDateFormatter localizedStringFromDate:date
                                                         dateStyle:NSDateFormatterShortStyle
                                                         timeStyle:NSDateFormatterShortStyle];
    NSString *name = [dict objectForKey:@"name"];
    if (name != NULL) {
        name = @"Inconnu";
    }
    cell.nameLabel.text = [dict objectForKey:@"name"];
    return cell;
}

//==========================================================================================
#pragma mark - TableView delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [self.phoneCalls objectAtIndex:indexPath.row];
    [PRPAlertView showWithTitle:@"Appels" message:[NSString stringWithFormat:@"Appeler %@?", [dict objectForKey:@"phone"]]
                    cancelTitle:@"Annuler"
                    cancelBlock:nil
                     otherTitle:@"OK" otherBlock:^{
                         NSString *cleanedString = [[[dict objectForKey:@"phone"] componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
                         NSString *phoneNumber = [@"tel://" stringByAppendingString:cleanedString];
                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
                     }];
}

@end
