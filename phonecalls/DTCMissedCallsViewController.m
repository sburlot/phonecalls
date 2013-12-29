//
//  DTCMissedCallsViewController.h.m
//  phonecalls
//
//  Created by Stephan on 22.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import "DTCMissedCallsViewController.h"

@implementation DTCMissedCallsViewController

//==========================================================================================
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.callKind = @"missed_calls";
    self.title = @"Appels Manqués";
    
}

@end
