//
//  DCAudioRecordAnimationController.m
//  DCAudioRecord
//
//  Created by Derek Carter on 1/14/16.
//  Copyright © 2016 Derek Carter. All rights reserved.
//

#import "DCAudioRecordAnimationController.h"

@interface DCAudioRecordAnimationController()

@property (nonatomic, strong) DCAudioRecordViewController *viewController;
@property (nonatomic) BOOL presenting;

@end


@implementation DCAudioRecordAnimationController

- (id)initWithViewController:(DCAudioRecordViewController *)viewController isPresenting:(BOOL)presenting
{
    self = [super init];
    if (self) {
        self.viewController = viewController;
        self.presenting = presenting;
    }
    return self;
}

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    if (!containerView) {
        return;
    }
    
    [containerView addSubview:self.viewController.view];
    
    CGRect oldFrame = self.viewController.containerView.frame;
    CGRect newFrame = self.viewController.containerView.frame;
    newFrame.origin.y = containerView.bounds.origin.y + containerView.bounds.size.height;
    self.viewController.containerView.frame = newFrame;
    self.viewController.backgroundView.alpha = 0;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.viewController.containerView.frame = oldFrame;
                         self.viewController.backgroundView.alpha = 1;
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
}

- (void)dismissPresentation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    if (!containerView) {
        return;
    }
    
    CGRect newFrame = self.viewController.containerView.frame;
    newFrame.origin.y = containerView.bounds.origin.y + containerView.bounds.size.height;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.viewController.containerView.frame = newFrame;
                         self.viewController.backgroundView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.viewController.view removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
}


#pragma mark - UIViewControllerAnimatedTransitioning Methods

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (self.presenting) {
        return 0.33f;
    }
    return 0.33;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (self.presenting) {
        [self animatePresentation:transitionContext];
    }
    else {
        [self dismissPresentation:transitionContext];
    }
    return;
}

@end

