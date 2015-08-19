//
//  DTCCallerInfoViewController.m
//  phonecalls
//
//  Created by Stephan on 16/08/15.
//  Copyright (c) 2015 Stephan. All rights reserved.
//

#import "DTCCallerInfoViewController.h"

@interface DTCCallerInfoViewController ()

@end

@implementation DTCCallerInfoViewController

//==========================================================================================
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.infoLabel.text = _info;
}

//==========================================================================================
- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
