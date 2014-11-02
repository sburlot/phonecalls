//
//  DTCCell.h
//  phonecalls
//
//  Created by Stephan on 27.12.13.
//  Copyright (c) 2013 Stephan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface DTCCell : SWTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end
