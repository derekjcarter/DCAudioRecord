//
//  DCAudioRecordAnimationController.h
//  DCAudioRecord
//
//  Created by Derek Carter on 1/14/16.
//  Copyright © 2016 Derek Carter. All rights reserved.
//

#import "DCAudioRecordViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DCAudioRecordAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

- (id)initWithViewController:(DCAudioRecordViewController *)viewController isPresenting:(BOOL)presenting;

@end
