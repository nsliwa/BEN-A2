//
//  ModuleA_PianoToneController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "ModuleA_PianoToneController.h"
#import "ModuleA_MasterViewController.h"
#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUFFTHelper.h"
#import "SMUGraphHelper.h"

#define kSamplingRate 44100.00
#define kBufferLength 8820 //14700 //4096
#define kframesPerSecond 30
#define knumDataArraysToGraph 1
#define kWindowLength 10
#define kNumOfMaximums 2
#define kdf kSamplingRate/kBufferLength

@interface ModuleA_PianoToneController ()

@property (strong, nonatomic) Novocaine *audioManagerPiano;
@property (nonatomic)GraphHelper *graphHelperPiano;
@property (nonatomic)float *audioDataPiano;

@property (nonatomic)SMUFFTHelper *fftHelperPiano;
@property (nonatomic)float *fftMagnitudeBufferPiano;
@property (nonatomic)float *fftPhaseBufferPiano;

@property (nonatomic)float *dilationLocalMaxFrequencyPiano;
@property (nonatomic)float *localMaximumsPiano;

@property (weak, nonatomic) IBOutlet UILabel *noteLabel;

@end

@implementation ModuleA_PianoToneController

RingBuffer *ringBufferPiano;

-(Novocaine*) audioManagerPiano {
    if(!_audioManagerPiano)
        _audioManagerPiano = [Novocaine audioManager];
    return _audioManagerPiano;
}

-(GraphHelper*) graphHelperPiano {
    if(!_graphHelperPiano) {
        _graphHelperPiano = new GraphHelper(self,
                                       kframesPerSecond,
                                       knumDataArraysToGraph,
                                       PlotStyleSeparated);
    }
    return _graphHelperPiano;
}

-(float*) audioDataPiano {
    if(!_audioDataPiano)
        _audioDataPiano = (float*)calloc(kBufferLength,sizeof(float));
    return _audioDataPiano;
}

-(SMUFFTHelper*) fftHelperPiano {
    if(!_fftHelperPiano)
        _fftHelperPiano = new SMUFFTHelper(kBufferLength,kBufferLength,WindowTypeRect);
    return _fftHelperPiano;
}

-(float*) fftMagnitudeBufferPiano {
    if(!_fftMagnitudeBufferPiano)
        _fftMagnitudeBufferPiano = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftMagnitudeBufferPiano;
}

-(float*) fftPhaseBufferPiano {
    if(!_fftPhaseBufferPiano)
        _fftPhaseBufferPiano = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftPhaseBufferPiano;
}

-(float*) dilationLocalMaxFrequencyPiano {
    if(!_dilationLocalMaxFrequencyPiano)
        _dilationLocalMaxFrequencyPiano = (float *)calloc(kWindowLength,sizeof(float));
    return _dilationLocalMaxFrequencyPiano;
}

-(float*) localMaximumsPiano {
    if(!_localMaximumsPiano)
        _localMaximumsPiano = (float *)calloc(kNumOfMaximums, sizeof(float));
    return _localMaximumsPiano;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    [self.audioManagerPiano play];
    
    [self.audioManagerPiano setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(ringBufferPiano!=nil)
             ringBufferPiano->AddNewFloatData(data, numFrames);
     }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ringBufferPiano = new RingBuffer(kBufferLength,2);
    
    self.graphHelperPiano->SetBounds(-0.8,0.8,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)
}

#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    // stop opengl from running
    self.graphHelperPiano->tearDownGL();
    [self.audioManagerPiano pause];
}

-(void)dealloc{
    self.graphHelperPiano->tearDownGL();
    
    free(self.audioDataPiano);
    
    free(self.fftMagnitudeBufferPiano);
    free(self.fftPhaseBufferPiano);
    
    delete self.fftHelperPiano;
    delete ringBufferPiano;
    delete self.graphHelperPiano;
    
    ringBufferPiano = nil;
    self.fftHelperPiano  = nil;
    self.audioManagerPiano = nil;
    self.graphHelperPiano = nil;
    
    
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    
}


#pragma mark - OpenGL and Update functions
//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    self.graphHelperPiano->draw(); // draw the graph
}


//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    // plot the audio
    ringBufferPiano->FetchFreshData2(self.audioDataPiano, kBufferLength, 0, 1);
    
    //take the FFT
    self.fftHelperPiano->forward(0,self.audioDataPiano, self.fftMagnitudeBufferPiano, self.fftPhaseBufferPiano);
    //[self convertToDecibels];
    
    // plot the FFT
    self.graphHelperPiano->setGraphData(0,self.fftMagnitudeBufferPiano,kBufferLength/4,sqrt(kBufferLength)); // set graph channel
    
}

#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)findMaxUsingDilation{
    
    float max = 0.0;
    float secondMax = 0.0;
    float tempMax = 0.0;
    int tempMaxIndex = 0;
    int maxIndex = 0;
    int maxIndex2 = 0;
    
    int interpolatedMax;
    int interpolatedMax2;
    
    //Turn to decibels and look for max using dilation
    for(int i = 0; i < kBufferLength/2; i++){
        
        self.fftMagnitudeBufferPiano[i] = 20 * log10f(self.fftMagnitudeBufferPiano[i]);
        
        for(int j = 0; j < kWindowLength; j++){
            
            if(self.fftMagnitudeBufferPiano[i+j] >= tempMax && self.fftMagnitudeBufferPiano[i+j] > 30){
                tempMax = self.fftMagnitudeBufferPiano[i+j];
                tempMaxIndex = j;
                
            }
            
        }
        
        
        if(tempMaxIndex == kWindowLength/2){
            
            if(tempMax >= max){
                secondMax = max;
                maxIndex2 = maxIndex;
                max = tempMax;
                maxIndex = tempMaxIndex + i;
            }else if(tempMax >= secondMax){
                secondMax = tempMax;
                maxIndex2 = tempMaxIndex + i;
            }
        }
        
        tempMax = 0.0;
        
    }
    if(maxIndex != 0 && maxIndex2 != 0){
        
        interpolatedMax = [self peakInterpolation:(maxIndex)];
        interpolatedMax2 = [self peakInterpolation:(maxIndex2)];
        
        NSLog(@"1st max: %d at %d \n 2nd max: %d at %d", interpolatedMax, maxIndex, interpolatedMax2, maxIndex2);
        //self.firstFrequency.text = [NSString stringWithFormat:@"1st frequency: %d",interpolatedMax];
        //self.secondFrequency.text = [NSString stringWithFormat:@"2nd frequency: %d",interpolatedMax2];
        self.noteLabel.text = [self determineNote:(interpolatedMax)];
        
    }
}



-(int)peakInterpolation: (int) index{
    
    int f2 = index*kdf;
    
    float m3 = self.fftMagnitudeBufferPiano[index+1];
    float m2 = self.fftMagnitudeBufferPiano[index];
    float m1 = self.fftMagnitudeBufferPiano[index-1];
    
    //int interpolated = f2 + ((m3-m2)/(2*m2-m1-m2))*(kdf/2);
    int interpolated = f2 + ((m3 - m1)/(2*m2 - m1 - m3))*(kdf/2);
    
    //NSLog(@"Interpolated %d to %d ", old, interpolated);
    
    return interpolated;
    
}

-(NSString*)determineNote: (int) frequency{
    
    NSString* note;
    
    if (frequency >= 0 && frequency < 110.000)
        note = @"Note is below threshold";
    else if (frequency >= 110.00 && frequency < 116.54)
        note = @"A2";
    else if (frequency >= 116.54 && frequency < 123.47)
        note = @"A#2";
    else if (frequency >= 123.47 && frequency < 130.81)
        note = @"B2";
    else if (frequency >= 130.81 && frequency < 138.59)
        note = @"C3";
    else if (frequency >= 138.59 && frequency < 146.83)
        note = @"C#3";
    else if (frequency >= 146.83 && frequency < 155.56)
        note = @"D3";
    else
        note = @"Note is above threshold";
    
    return note;

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
