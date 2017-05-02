//
//  GGAAudioRecordViewController.m
//  GGAAudioRecord
//
//  Created by Derek Carter on 1/14/16.
//  Copyright © 2016 Derek Carter. All rights reserved.
//

#import "DCAudioRecordViewController.h"
#import "DCAudioRecordAnimationController.h"
#import "DCAudioRecordCircleButton.h"
#import "JZMp3RecordingClient.h"
#import <AVFoundation/AVFoundation.h>

static float const kContainerViewHeight   = 190.0f;
static float const kProgressViewHeight    = 20.0f;
static float const kSmallButtonHeight     = 65.0f;
static float const kLargeButtonHeight     = 80.0f;
static float const kButtonSidePadding     = 20.0f;
static float const kCancelButtonHeight    = 44.0f;
static double const kDefaultRecordingTime = 10.0;
static double const kCountdownInterval    = 0.001;

@interface DCAudioRecordViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) DCAudioRecordCircleButton *playButton;
@property (nonatomic, strong) DCAudioRecordCircleButton *recordButton;
@property (nonatomic, strong) DCAudioRecordCircleButton *sendButton;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *usageTipLabel;
@property (nonatomic, strong) UILabel *timerLabel;

@property (nonatomic, strong) UIImage *playImage;
@property (nonatomic, strong) UIImage *stopImage;
@property (nonatomic, strong) UIImage *recordImage;
@property (nonatomic, strong) UIImage *sendImage;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSURL *soundFileURL;
@property (nonatomic, strong) JZMp3RecordingClient *recordClient;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL hasRecording;

@property (nonatomic, strong) NSDate *recordingStartDate;
@property (nonatomic, strong) NSTimer *recordingTimer;
@property (nonatomic, strong) NSTimer *audioPlayTimer;
@property (nonatomic, strong) NSTimer *progressTimer;

@end


@implementation DCAudioRecordViewController

- (id)init
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        
        // Defaults
        self.themeColor = [UIColor colorWithRed:4.0/255.0 green:141.0/255.0 blue:186.0/255.0 alpha:1.0];
        self.maxAudioSeconds = kDefaultRecordingTime;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup audio path
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths.firstObject;
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"attachment-audio.mp3"];
    self.soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    // Setup recording client
    self.recordClient = [JZMp3RecordingClient sharedClient];
    [self.recordClient setCurrentMp3File:soundFilePath];
    
    // General view properties
    self.view.backgroundColor = [UIColor clearColor];
    
    // Set button images
    self.playImage = [UIImage imageNamed:@"DCAudioPlay"];
    self.stopImage = [UIImage imageNamed:@"DCAudioStop"];
    self.recordImage = [UIImage imageNamed:@"DCAudioRecord"];
    self.sendImage = [UIImage imageNamed:@"DCAudioSend"];
    
    // Background view
    self.backgroundView = [UIView new];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2723];
    [self.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)]];
    [self.view addSubview:self.backgroundView];
    
    // Container view
    self.containerView = [UIView new];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.containerView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.userInteractionEnabled = NO;
        blurEffectView.frame = self.containerView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.containerView addSubview:blurEffectView];
    } else {
        self.containerView.backgroundColor = [UIColor whiteColor];
    }
    self.containerView.layer.cornerRadius = 15.0f;
    self.containerView.layer.masksToBounds = YES;
    [self.view addSubview:self.containerView];
    
    // Progress view
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressViewStyle = UIProgressViewStyleDefault;
    self.progressView.progressTintColor = [UIColor blueColor];
    self.progressView.trackTintColor = [UIColor clearColor]; //[UIColor colorWithWhite:1.0 alpha:0.33];
    UIView *bottomProgressViewBorder = [[UIView alloc] initWithFrame:CGRectMake(0, kProgressViewHeight, MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width), 1)];
    bottomProgressViewBorder.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.progressView addSubview:bottomProgressViewBorder];
    [self.containerView addSubview:self.progressView];
    
    // Tool-tip Label
    self.usageTipLabel = [UILabel new];
    self.usageTipLabel.hidden = YES;
    self.usageTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.usageTipLabel.font = [UIFont systemFontOfSize:15.0];
    self.usageTipLabel.text = NSLocalizedString(@"Tap and hold to record audio.", @"Audio Recording Tool Tip");
    self.usageTipLabel.textAlignment = NSTextAlignmentCenter;
    [self.progressView addSubview:self.usageTipLabel];
    
    // Tool-tip Label
    self.timerLabel = [UILabel new];
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timerLabel.font = [UIFont systemFontOfSize:13.0];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.timerLabel];
    
    // Button container
    UIView *buttonContainer = [UIView new];
    buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    buttonContainer.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:buttonContainer];
    
    // Play button
    self.playButton = [[DCAudioRecordCircleButton alloc] initWithFrame:CGRectMake(0, 0, kSmallButtonHeight, kSmallButtonHeight)];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.playButton.labeledIconButtonLayout = DCAudioCircleButtonLayoutDefault;
    self.playButton.labeledIconButtonBufferMagnitude = 0;
    self.playButton.borderWidth = 1.5;
    [self.playButton setCircleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
    [self.playButton setCircleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.playButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.playButton setBorderColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.playButton setImage:self.playImage forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.playButton.enabled = NO;
    [buttonContainer addSubview:self.playButton];
    
    // Start/Stop button
    self.recordButton = [[DCAudioRecordCircleButton alloc] initWithFrame:CGRectMake(0, 0, kLargeButtonHeight, kLargeButtonHeight)];
    self.recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordButton.labeledIconButtonLayout = DCAudioCircleButtonLayoutDefault;
    self.recordButton.labeledIconButtonBufferMagnitude = 0;
    self.recordButton.borderWidth = 1.5;
    [self.recordButton setCircleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
    [self.recordButton setCircleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.recordButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.recordButton setBorderColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.recordButton setImage:self.recordImage forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(recordButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.recordButton addTarget:self action:@selector(recordButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton addTarget:self action:@selector(recordButtonTouchUp:) forControlEvents:UIControlEventTouchCancel];
    [buttonContainer addSubview:self.recordButton];
    
    // Send button
    self.sendButton = [[DCAudioRecordCircleButton alloc] initWithFrame:CGRectMake(0, 0, kSmallButtonHeight, kSmallButtonHeight)];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendButton.labeledIconButtonLayout = DCAudioCircleButtonLayoutDefault;
    self.sendButton.labeledIconButtonBufferMagnitude = 0;
    self.sendButton.borderWidth = 1.5;
    [self.sendButton setCircleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
    [self.sendButton setCircleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.sendButton setBorderColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.sendButton setImage:self.sendImage forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.enabled = NO;
    [buttonContainer addSubview:self.sendButton];
    
    // Cancel button
    self.cancelButton = [UIButton new];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addStyleToButton:self.cancelButton];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIView *topCancelButtonBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width), 1)];
    topCancelButtonBorder.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.cancelButton addSubview:topCancelButtonBorder];
    [self.containerView addSubview:self.cancelButton];
    
    
    
    // Constraint views
    NSDictionary *views = NSDictionaryOfVariableBindings(_backgroundView, _containerView, _progressView, _usageTipLabel, _timerLabel, buttonContainer, _playButton, _recordButton, _sendButton, _cancelButton);
    NSDictionary *metrics = @{
                              @"containerViewHeight" : @(kContainerViewHeight),
                              @"sidePadding"         : @(10),
                              @"progressViewHeight"  : @(kProgressViewHeight),
                              @"cancelButtonHeight"  : @(kCancelButtonHeight),
                              @"toolTipHeight"       : @(21),
                              @"toolTipPadding"      : @(4)
                              };
    
    // Horizontal constraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundView]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(sidePadding)-[_containerView]-(sidePadding)-|" options:0 metrics:metrics views:views]];
    
    [self.progressView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_usageTipLabel]|" options:0 metrics:metrics views:views]];
    
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_progressView]|" options:0 metrics:metrics views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_timerLabel]|" options:0 metrics:metrics views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[buttonContainer]|" options:0 metrics:metrics views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_cancelButton]|" options:0 metrics:metrics views:views]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.recordButton
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:buttonContainer
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.recordButton
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:-(kSmallButtonHeight+kButtonSidePadding)]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.sendButton
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.recordButton
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:(kSmallButtonHeight+kButtonSidePadding)]];
    
    // Vertical constraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundView]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_containerView(==containerViewHeight)]-(sidePadding)-|" options:0 metrics:metrics views:views]];
    
    [self.progressView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_usageTipLabel]|" options:0 metrics:metrics views:views]];
    
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_progressView(==progressViewHeight)]-(toolTipPadding)-[_timerLabel(==toolTipHeight)]-(toolTipPadding)-[buttonContainer]-[_cancelButton(==cancelButtonHeight)]|" options:0 metrics:metrics views:views]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:buttonContainer
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1
                                                                 constant:0]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.recordButton
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:buttonContainer
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1
                                                                 constant:0]];
    
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.sendButton
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:buttonContainer
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1
                                                                 constant:0]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self checkMicPermissions];
    
    [super viewWillAppear:animated];
    [self setUITheme];
}

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self stopTimers];
}


#pragma mark - Permission Methods

- (void)checkMicPermissions
{
    switch ([AVAudioSession sharedInstance].recordPermission) {
        case AVAudioSessionRecordPermissionGranted:
            break;
            
        case AVAudioSessionRecordPermissionDenied: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAppPermissionsWithAlert];
            });
            break;
        }
        case AVAudioSessionRecordPermissionUndetermined: {
            // Request permission
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (!granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self requestAppPermissionsWithAlert];
                    });
                }
            }];
            
            break;
        }
    }
}

- (void)requestAppPermissionsWithAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Microphone permissions are needed."
                                                                             message:@"To give permissions tap on 'Change Settings' button" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Change Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertController addAction:settingsAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Action Methods

- (void)playButtonTapped:(id)sender
{
    if (self.audioPlayer != nil && self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
        
        [self updateUI];
        [self.playButton setImage:self.playImage forState:UIControlStateNormal];
        
        [self stopTimers];
        
        return;
    }
    
    if (!self.recordClient.recorder.isRecording) {
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.soundFileURL error:&error];
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
        
        if (error) {
            [self updateUI];
            return;
        }
        
        [self updateUI];
        [self.playButton setImage:self.stopImage forState:UIControlStateNormal];
        
        self.audioPlayTimer = [NSTimer scheduledTimerWithTimeInterval:kCountdownInterval
                                                               target:self
                                                             selector:@selector(updateProgressViewForAudioPlayback)
                                                             userInfo:nil
                                                              repeats:YES];
        [self.audioPlayer play];
    }
}

- (void)recordButtonTouchDown:(id)sender
{
    self.recordButton.borderWidth = 2.0;
    [UIView animateWithDuration:0.24f animations:^{
        [self.recordButton setTransform:CGAffineTransformMakeScale(1.2, 1.2)];
    }];
    
    self.playButton.enabled = NO;
    self.sendButton.enabled = NO;
    
    if (self.usageTipLabel.hidden == NO) {
        self.usageTipLabel.hidden = YES;
    }
    
    if (!self.recordClient.recorder.isRecording) {
        self.isRecording = YES;
        self.hasRecording = NO;
        [self.recordClient start];
        
        self.recordingStartDate = [NSDate date];
        self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:self.maxAudioSeconds
                                                               target:self
                                                             selector:@selector(recordButtonTouchUp:)
                                                             userInfo:nil
                                                              repeats:NO];
        
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:kCountdownInterval
                                                              target:self
                                                            selector:@selector(updateProgressView)
                                                            userInfo:nil
                                                             repeats:YES];
    }
}

- (void)recordButtonTouchUp:(id)sender
{
    [UIView animateWithDuration:0.2f animations:^{
        [self.recordButton setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
    }];
    self.recordButton.borderWidth = 1.5;
    
    self.isRecording = NO;
    NSTimeInterval timeDiff = [self.recordingTimer.fireDate timeIntervalSinceDate:[NSDate date]];
    [self updateTimerLabelText:(self.maxAudioSeconds - timeDiff)];
    self.hasRecording = YES;
    
    [self stopTimers];
    [self.recordClient stop];
    
    double milliseconds = [[NSDate date] timeIntervalSinceDate:self.recordingStartDate] * 1000.0;
    if (milliseconds < 500.0f) {
        self.usageTipLabel.hidden = NO;
        self.isRecording = NO;
        self.hasRecording = NO;
        [self.progressView setProgress:0.0f animated:NO];
        [self updateTimerLabelText:-1];
    }
    
    [self updateUI];
}

- (void)sendButtonTapped:(id)sender
{
    if (self.hasRecording) {
        if ([self.audioPlayer isPlaying]) {
            [self.audioPlayer stop];
        }
        
        if (self.soundFileURL && self.audioRecordedBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *audioData = [NSData dataWithContentsOfFile:self.soundFileURL.path];
                self.audioRecordedBlock(audioData, nil);
            });
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:self.soundFileURL.path]) {
            NSError *error = [NSError errorWithDomain:self.soundFileURL.path
                                                 code:9000
                                             userInfo:@{ NSLocalizedDescriptionKey : @"The audio URL resource does not contain a local file." }];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.audioRecordedBlock(nil, error);
            });
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)cancelButtonTapped:(id)sender
{
    if (self.recordClient.recorder.isRecording) {
        [self.recordClient stop];
    }
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    
    self.usageTipLabel.hidden = YES;
    
    if (!self.hasRecording) {
        [self dismissViewControllerAnimated:YES completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.audioRecordedBlock(nil, nil);
            });
        }];
    }
    else {
        [self.playButton setImage:self.playImage forState:UIControlStateNormal];
        self.isRecording = NO;
        self.hasRecording = NO;
        [self stopTimers];
        [self updateUI];
        [self updateTimerLabelText:-1];
        [self.progressView setProgress:0 animated:NO];
    }
}

- (void)backgroundTapped:(id)sender
{
    if (self.recordClient.recorder.isRecording) {
        [self.recordClient stop];
    }
    
    if (!self.hasRecording) {
        [self dismissViewControllerAnimated:YES completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.audioRecordedBlock(nil, nil);
            });
        }];
    }
}


#pragma mark - User Interface Methods

- (void)addStyleToButton:(UIButton *)button
{
    static UIImage *normalImage;
    static UIImage *selectedImage;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, rect);
        
        selectedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, rect);
        
        normalImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    });
    
    [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
}

- (void)setUITheme
{
    if (self.themeColor) {
        [self.playButton setCircleColor:[self.themeColor colorWithAlphaComponent:0.3] forState:UIControlStateHighlighted];
        [self.playButton setBorderColor:self.themeColor forState:UIControlStateNormal];
        [self.playButton setBorderColor:self.themeColor forState:UIControlStateHighlighted];
        
        [self.recordButton setCircleColor:[self.themeColor colorWithAlphaComponent:0.3] forState:UIControlStateHighlighted];
        [self.recordButton setBorderColor:self.themeColor forState:UIControlStateNormal];
        [self.recordButton setBorderColor:self.themeColor forState:UIControlStateHighlighted];
        
        [self.sendButton setCircleColor:[self.themeColor colorWithAlphaComponent:0.3] forState:UIControlStateHighlighted];
        [self.sendButton setBorderColor:self.themeColor forState:UIControlStateNormal];
        [self.sendButton setBorderColor:self.themeColor forState:UIControlStateHighlighted];
        
        [self.cancelButton setTitleColor:self.themeColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:self.themeColor forState:UIControlStateHighlighted];
        
        [self.usageTipLabel setTextColor:self.themeColor];
        [self.timerLabel setTextColor:self.themeColor];
        [self.progressView setProgressTintColor:self.themeColor];
        
        self.playImage = [self updateIconColor:self.themeColor forImage:self.playImage];
        self.stopImage = [self updateIconColor:self.themeColor forImage:self.stopImage];
        [self.playButton setImage:self.playImage forState:UIControlStateNormal];
        self.recordImage = [self updateIconColor:self.themeColor forImage:self.recordImage];
        [self.recordButton setImage:self.recordImage forState:UIControlStateNormal];
        self.sendImage = [self updateIconColor:self.themeColor forImage:self.sendImage];
        [self.sendButton setImage:self.sendImage forState:UIControlStateNormal];
    }
    
    if (self.buttonFont) {
        [self.playButton.titleLabel setFont:self.buttonFont];
        [self.recordButton.titleLabel setFont:self.buttonFont];
        [self.sendButton.titleLabel setFont:self.buttonFont];
        [self.cancelButton.titleLabel setFont:self.buttonFont];
    }
}

- (void)updateUI
{
    if (self.hasRecording) {
        self.playButton.enabled = YES;
        self.recordButton.enabled = NO;
        self.sendButton.enabled = YES;
        
        [self.cancelButton setTitle:@"Delete" forState:UIControlStateNormal];
    }
    else {
        self.playButton.enabled = NO;
        self.recordButton.enabled = YES;
        self.sendButton.enabled = NO;
        
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    }
}

- (UIImage *)updateIconColor:(UIColor*)color forImage:(UIImage*)image
{
    UIImage *newImage;
    if (color) {
        UIGraphicsBeginImageContextWithOptions([image size], NO, 0.0);
        CGRect rect = CGRectZero;
        rect.size = [image size];
        [image drawInRect:rect];
        [color set];
        UIRectFillUsingBlendMode(rect, kCGBlendModeScreen);
        [image drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newImage;
}


#pragma mark - Timer Methods

- (void)stopTimers
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    [self.audioPlayTimer invalidate];
    self.audioPlayTimer = nil;
    [self.recordingTimer invalidate];
    self.recordingTimer = nil;
}

- (void)updateProgressView
{
    NSTimeInterval timeDiff = [self.recordingTimer.fireDate timeIntervalSinceDate:[NSDate date]];
    float progress = (self.maxAudioSeconds - timeDiff) / self.maxAudioSeconds;
    [self.progressView setProgress:progress];
    [self updateTimerLabelText:(self.maxAudioSeconds - timeDiff)];
}

- (void)updateProgressViewForAudioPlayback
{
    float progress = self.audioPlayer.currentTime / self.maxAudioSeconds;
    [self.progressView setProgress:progress];
    [self updateTimerLabelText:self.audioPlayer.currentTime];
}

- (void)updateTimerLabelText:(CGFloat)value
{
    if (self.isRecording) {
        self.timerLabel.text = [NSString stringWithFormat:@"%.1f sec - %ld sec", value, (long)self.maxAudioSeconds];
    }
    else {
        if (value < 0) {
            self.timerLabel.text = [NSString stringWithFormat:@"%ld sec", (long)self.maxAudioSeconds];
        }
        else {
            self.timerLabel.text = [NSString stringWithFormat:@"%.1f sec", value];
        }
    }
}


#pragma mark - AVAudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self updateUI];
    [self updateTimerLabelText:self.audioPlayer.duration];
    [self.playButton setImage:self.playImage forState:UIControlStateNormal];
    
    [self stopTimers];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"DCAudioRecord | Decode Error occurred");
}


#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    self.hasRecording = YES;
    self.isRecording = NO;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"DCAudioRecord | Encode Error occurred");
}


#pragma mark - UIViewControllerTransitioningDelegate Methods

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[DCAudioRecordAnimationController alloc] initWithViewController:self isPresenting:YES];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[DCAudioRecordAnimationController alloc] initWithViewController:self isPresenting:NO];
}

@end
