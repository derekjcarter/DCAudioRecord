//
//  DemoViewController.m
//  DCAudioRecord
//
//  Created by Derek Carter on 1/14/16.
//  Copyright © 2016 Derek Carter. All rights reserved.
//

#import "DemoViewController.h"
#import "DCAudioRecordViewController.h"

@interface DemoViewController ()

@property (nonatomic, strong) DCAudioRecordViewController *audioRecordView;

@end


@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Action Methods

- (IBAction)audioPickerTapped:(id)sender
{
    _audioRecordView = [[DCAudioRecordViewController alloc] init];
    _audioRecordView.themeColor = [UIColor colorWithRed:64.0/255.0 green:180.0/255.0 blue:229.0/255.0 alpha:1.0];
    _audioRecordView.buttonFont = [UIFont systemFontOfSize:18.0f];
    _audioRecordView.maxAudioSeconds = 3.0f;
    _audioRecordView.audioRecordedBlock = ^(NSData *audioData, NSError *error) {
        NSLog(@"DemoViewController | audioRecordedBlock");
        if (audioData) {
            NSLog(@"DemoViewController | You can do something with the audio here..");
        }
        _audioRecordView = nil;
    };
    
    [self presentViewController:_audioRecordView animated:YES completion:nil];
}

@end
