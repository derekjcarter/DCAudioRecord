//
//  DCAudioRecordCircleButton.m
//  DCAudioRecord
//
//  Created by Derek Carter on 11/23/15.
//  Copyright © 2015 Derek Carter. All rights reserved.
//

#import "DCAudioRecordCircleButton.h"

@interface DCAudioRecordCircleButton ()

@property (strong, nonatomic) NSMutableDictionary *circleColors;
@property (strong, nonatomic) NSMutableDictionary *borderColors;
@property (strong, nonatomic) UIBezierPath *circlePath;

@end


@implementation DCAudioRecordCircleButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self install];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self install];
}

- (void)install
{
    self.labeledIconButtonLayout = DCAudioCircleButtonLayoutDefault;
    self.labeledIconButtonBufferMagnitude = 6.0f;
    
    self.titleLabel.backgroundColor = [UIColor clearColor];
    _circleColors = [NSMutableDictionary new];
    _borderColors = [NSMutableDictionary new];
    _borderWidth = 0;
    _clipTouchesToCircle = YES;
    _circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize imageSize = self.imageView.frame.size;
    CGSize titleSize = self.titleLabel.frame.size;
    
    CGFloat imagePadding = ceilf(self.labeledIconButtonBufferMagnitude / 2);
    CGFloat titlePadding = floorf(self.labeledIconButtonBufferMagnitude / 2);
    
    switch (_labeledIconButtonLayout) {
        case DCAudioCircleButtonLayoutDefault:
            self.imageEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                    -imagePadding,
                                                    0.0f,
                                                    imagePadding
                                                    );
            
            self.titleEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                    titlePadding,
                                                    0.0f,
                                                    -titlePadding
                                                    );
            break;
            
        case DCAudioCircleButtonLayoutReversed:
            self.imageEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                    (titleSize.width + imagePadding),
                                                    0.0f,
                                                    -(titleSize.width + imagePadding));
            
            self.titleEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                    -(imageSize.width + titlePadding),
                                                    0.0f,
                                                    (imageSize.width + titlePadding));
            break;
            
        case DCAudioCircleButtonLayoutIconTop:
            self.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + self.labeledIconButtonBufferMagnitude),
                                                    0.0f,
                                                    0.0f,
                                                    - titleSize.width);
            
            self.titleEdgeInsets = UIEdgeInsetsMake((imageSize.height + self.labeledIconButtonBufferMagnitude),
                                                    -imageSize.width,
                                                    0.0f,
                                                    0.0f);
            break;
            
        case DCAudioCircleButtonLayoutIconBottom:
            self.imageEdgeInsets = UIEdgeInsetsMake((titleSize.height + self.labeledIconButtonBufferMagnitude),
                                                    0.0f,
                                                    0.0f,
                                                    -titleSize.width);
            
            self.titleEdgeInsets = UIEdgeInsetsMake(-(imageSize.height + self.labeledIconButtonBufferMagnitude),
                                                    -imageSize.width,
                                                    0.0f,
                                                    0.0f);
            break;
            
        default:
            break;
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
}


#pragma mark - Getter/Setter Methods

- (void)setCircleColor:(UIColor *)color forState:(UIControlState)state
{
    self.circleColors[@(state)] = color;
    UIImage *circleImage = [self circleImageWithColor:color borderColor:self.borderColors[@(state)] borderWidth:self.borderWidth];
    [self setBackgroundImage:circleImage forState:state];
}

- (UIColor *)circleColorForState:(UIControlState)state
{
    return self.circleColors[@(state)];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    self.borderColors[@(state)] = color;
    UIImage *circleImage = [self circleImageWithColor:self.circleColors[@(state)] borderColor:color borderWidth:self.borderWidth];
    [self setBackgroundImage:circleImage forState:state];
}

- (UIColor *)borderColorForState:(UIControlState)state
{
    return self.borderColors[@(state)];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    [self refreshAllCircleImages];
}


#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.clipTouchesToCircle) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    if ([self isTouchInside:touch]) {
        [super touchesBegan:touches withEvent:event];
    }
    else {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.clipTouchesToCircle) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    if ([self isTouchInside:touch]) {
        [super touchesEnded:touches withEvent:event];
    }
    else {
        [self.nextResponder touchesEnded:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.clipTouchesToCircle) {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    if ([self isTouchInside:touch]) {
        [super touchesMoved:touches withEvent:event];
    }
    else {
        [super touchesCancelled:touches withEvent:event];
        [self.nextResponder touchesMoved:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.clipTouchesToCircle) {
        [super touchesCancelled:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    if ([self isTouchInside:touch]) {
        [super touchesCancelled:touches withEvent:event];
    }
    else {
        [self.nextResponder touchesCancelled:touches withEvent:event];
    }
}

- (BOOL)isTouchInside:(UITouch *)touch
{
    CGPoint location = [touch locationInView:self];
    if (CGPathContainsPoint(self.circlePath.CGPath, NULL, location, true)) {
        return YES;
    }
    else {
        return NO;
    }
}


#pragma mark - Observer Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        self.circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        [self refreshAllCircleImages];
    }
}


#pragma mark - Helper Methods

- (void)refreshAllCircleImages
{
    [self.circleColors enumerateKeysAndObjectsUsingBlock:^(NSNumber *state, UIColor *color, BOOL *stop) {
        UIImage *circleImage = [self circleImageWithColor:color borderColor:self.borderColors[state] borderWidth:self.borderWidth];
        [self setBackgroundImage:circleImage forState:state.integerValue];
    }];
}

- (UIImage *)circleImageWithColor:(UIColor *)color borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth
{
    if (CGRectEqualToRect(self.bounds, CGRectZero) || !color) {
        return nil;
    }
    if (!borderColor) {
        borderColor = self.borderColors[@(UIControlStateNormal)];
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    [borderColor setStroke];
    CGContextSetLineWidth(context, borderWidth);
    CGRect rect = CGRectMake(borderWidth / 2.0, borderWidth / 2.0, self.bounds.size.width - borderWidth, self.bounds.size.height - borderWidth);
    CGContextFillEllipseInRect(context, rect);
    CGContextStrokeEllipseInRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
