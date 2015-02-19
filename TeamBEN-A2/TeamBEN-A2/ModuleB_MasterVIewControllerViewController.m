//
//  ModuleB_MasterVIewControllerViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "ModuleB_MasterVIewControllerViewController.h"
#import "ModuleB_embeddedFrequencyViewController.h"

#import "Novocaine.h"

@interface ModuleB_MasterVIewControllerViewController ()
// UI properties
@property (weak, nonatomic) IBOutlet UILabel *label_Frequency;
@property (weak, nonatomic) IBOutlet UILabel *label_Gesture;

@property (weak, nonatomic) IBOutlet UISlider *slider_Frequency;

@property (weak, nonatomic) IBOutlet UIView *container_GLKView;

@property (strong, nonatomic) Novocaine *audioManager;

@end

@implementation ModuleB_MasterVIewControllerViewController

float frequencyTone;

-(Novocaine*) audioManager {
    if(!_audioManager)
        _audioManager = [Novocaine audioManager];
    return _audioManager;
}

- (IBAction)didUpdateFrequency:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float frequency = slider.value;
    
    frequencyTone = frequency;
    
    self.label_Frequency.text = [NSString stringWithFormat:@"%.02f kHz", frequency / 1000.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float frequency = self.slider_Frequency.value;
    
    frequencyTone = frequency;
    
    self.label_Frequency.text = [NSString stringWithFormat:@"%.02f kHz", frequency / 1000.0];
    // Do any additional setup after loading the view.
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Segue_EmbeddedGLK"]) {
        ModuleB_embeddedFrequencyViewController *embed = segue.destinationViewController;
        embed.outputFrequency = frequencyTone;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    // create a sine wave and then play it on the speakers!!
    __block float frequency = frequencyTone; //500;//self.slider_Frequency.value; // 261.0; //starting frequency
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         //g(t) = sin(2*PI*frequency*time)
         //time = n/sampling rate
         //n = current frame
         double phaseIncrement = 2*M_PI*frequency/samplingRate;
         double repeatMax = 2*M_PI;
         
         frequency = frequencyTone;
         
         for (int i=0; i < numFrames; ++i)
         {
             for(int j=0;j<numChannels;j++){
                 data[i*numChannels+j] = 0.8*sin(phase);
                 
             }
             phase += phaseIncrement;
             
             if(phase>repeatMax)
                 phase -= repeatMax;
         }
         
         //NSLog(@"in block: %f", frequency);
         
         
     }];
    
    // handle what happens if the view gets loaded again
    if(![self.audioManager playing])
        [self.audioManager play];
    
}

// pause the audio when off screen
-(void) viewWillDisappear:(BOOL)animated{
    
    [self.audioManager pause]; // just pause the playing
    // audio manager is a singleton class, so we do not need to
    // tear it down, in case some other controller may want to use it
    
    // should we do anything here?
    
    
    [super viewWillDisappear:animated];
}

- (void) getFrequencyHandler:(void (^)(int))handler
{
    // NOTE: copying is very important if you'll call the callback asynchronously,
    // even with garbage collection!
    _frequencyHandler = [handler copy];
    
    // Do stuff, possibly asynchronously...
    //int result = 5 + 3;
    
    // Call completion handler.
    _frequencyHandler(frequencyTone);
    
    // Clean up.
    _frequencyHandler = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
