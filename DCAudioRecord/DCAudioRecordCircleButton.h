//
//  DCAudioRecordCircleButton.h
//  DCAudioRecord
//
//  Created by Derek Carter on 11/23/15.
//  Copyright © 2015 Derek Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DCAudioCircleButtonLayout) {
    DCAudioCircleButtonLayoutDefault,
    DCAudioCircleButtonLayoutReversed,
    DCAudioCircleButtonLayoutIconTop,
    DCAudioCircleButtonLayoutIconBottom,
};


@interface DCAudioRecordCircleButton : UIButton

@property (assign, nonatomic) CGFloat    borderWidth;
@property (assign, nonatomic) BOOL       clipTouchesToCircle;
@property (assign, nonatomic) NSUInteger labeledIconButtonLayout;
@property (assign, nonatomic) CGFloat    labeledIconButtonBufferMagnitude;

- (void)setCircleColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)circleColorForState:(UIControlState)state;

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)borderColorForState:(UIControlState)state;

@end
