//
//  DTCCallViewController.h
//  phonecalls
//
//  Created by Stephan on 29.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface DTCCallViewController : UITableViewController <SWTableViewCellDelegate, UIPopoverPresentationControllerDelegate>

@property(strong, nonatomic) NSString* callKind;

@end
