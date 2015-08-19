//
//  DTCCallerInfoViewController.h
//  phonecalls
//
//  Created by Stephan on 16/08/15.
//  Copyright (c) 2015 Stephan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DTCCallerInfoViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) NSString *info;

- (IBAction)doneAction:(id)sender;

@end
