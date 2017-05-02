//
//  DCAudioRecordViewController.h
//  DCAudioRecord
//
//  Created by Derek Carter on 1/14/16.
//  Copyright © 2016 Derek Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^DCRecordedAudioBlock)(NSData *audioData, NSError *error);

@interface DCAudioRecordViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) UIView *containerView;

@property (nonatomic, copy) DCRecordedAudioBlock audioRecordedBlock;

@property (nonatomic, assign) NSInteger maxAudioSeconds;
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, strong) UIFont *buttonFont;

@end
