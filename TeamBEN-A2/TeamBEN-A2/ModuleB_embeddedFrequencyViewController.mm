//
//  ModuleB_embeddedFrequencyViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/18/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "ModuleB_embeddedFrequencyViewController.h"
#import "ModuleB_MasterVIewControllerViewController.h"

#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUFFTHelper.h"
#import "SMUGraphHelper.h"

#import <math.h>

#define kSamplingRate 44100.00 //Hz
#define kBufferLength 8192//4096 //14700 needed to get within +/- 3 Hz accuracy
#define kSpectrumLength kBufferLength/2
#define kdf kSamplingRate/kBufferLength

#define kframesPerSecond 30
#define knumDataArraysToGraph 1
#define kWindowLength 50
#define kNumOfMaximums 2
//#define kdf 44100/kBufferLength
#define kSubSetLength 50


@interface ModuleB_embeddedFrequencyViewController ()
// UI properties
@property (weak, nonatomic) IBOutlet UILabel *label_Frequency;
@property (weak, nonatomic) IBOutlet UILabel *label_Gesture;

@property (weak, nonatomic) IBOutlet UISlider *slider_Frequency;


// Audio Processing properties
@property (strong, nonatomic) Novocaine *audioManager;
@property (nonatomic)GraphHelper *graphHelper;
@property (nonatomic)float *audioData;

@property (nonatomic)SMUFFTHelper *fftHelper;
@property (nonatomic)float *fftMagnitudeBuffer;
@property (nonatomic)float *fftPhaseBuffer;


@property (nonatomic)float *fftMagnitudeBuffer2;
@property (nonatomic)float *fftPhaseBuffer2;

@property (nonatomic)float *fftMagnitudeBuffer3;
@property (nonatomic)float *fftPhaseBuffer3;

@property (nonatomic)float *fftMagnitudeBufferAvg;
@property (nonatomic)float *fftMagnitudeBufferSubset;
@property (nonatomic)float *fftMagnitudeBufferSubsetPrevious;

@property (nonatomic)float *fftMagnitudeBufferSubsetDifference;

@property (nonatomic)float outputFrequencyPrevious;
/*
 @property (nonatomic)float *dilationLocalMaxFrequency;
 @property (nonatomic)float *localMaximums;
 */

@end

@implementation ModuleB_embeddedFrequencyViewController

RingBuffer *ringBuff;



-(Novocaine*) audioManager {
    if(!_audioManager)
        _audioManager = [Novocaine audioManager];
    NSLog(@"Sampling rate: %f", _audioManager.samplingRate);
    return _audioManager;
}

-(GraphHelper*) graphHelper {
    if(!_graphHelper) {
        _graphHelper = new GraphHelper(self,
                                       kframesPerSecond,
                                       knumDataArraysToGraph,
                                       PlotStyleSeparated);
    }
    return _graphHelper;
}

-(float*) audioData {
    if(!_audioData)
        _audioData = (float*)calloc(kBufferLength,sizeof(float));
    return _audioData;
}

-(SMUFFTHelper*) fftHelper {
    if(!_fftHelper)
        _fftHelper = new SMUFFTHelper(kBufferLength,kBufferLength,WindowTypeRect);
    return _fftHelper;
}

-(float*) fftMagnitudeBuffer {
    if(!_fftMagnitudeBuffer)
        _fftMagnitudeBuffer = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftMagnitudeBuffer;
}

-(float*) fftPhaseBuffer {
    if(!_fftPhaseBuffer)
        _fftPhaseBuffer = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftPhaseBuffer;
}

-(float*) fftMagnitudeBuffer2 {
    if(!_fftMagnitudeBuffer2)
        _fftMagnitudeBuffer2 = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftMagnitudeBuffer2;
}

-(float*) fftPhaseBuffer2 {
    if(!_fftPhaseBuffer2)
        _fftPhaseBuffer2 = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftPhaseBuffer2;
}

-(float*) fftMagnitudeBuffer3 {
    if(!_fftMagnitudeBuffer3)
        _fftMagnitudeBuffer3 = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftMagnitudeBuffer3;
}

-(float*) fftPhaseBuffer3 {
    if(!_fftPhaseBuffer3)
        _fftPhaseBuffer3 = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftPhaseBuffer3;
}

-(float*) fftMagnitudeBufferAvg {
    if(!_fftMagnitudeBufferAvg)
        _fftMagnitudeBufferAvg = (float *)calloc(kBufferLength/2,sizeof(float));
    return _fftMagnitudeBufferAvg;
}

-(float*) fftMagnitudeBufferSubset {
    if(!_fftMagnitudeBufferSubset)
        _fftMagnitudeBufferSubset = (float *)calloc(kSubSetLength,sizeof(float));
    return _fftMagnitudeBufferSubset;
}

-(float*) fftMagnitudeBufferSubsetPrevious {
    if(!_fftMagnitudeBufferSubsetPrevious)
        _fftMagnitudeBufferSubsetPrevious = (float *)calloc(kSubSetLength,sizeof(float));
    return _fftMagnitudeBufferSubsetPrevious;
}

-(float*) fftMagnitudeBufferSubsetDifference {
    if(!_fftMagnitudeBufferSubsetDifference)
        _fftMagnitudeBufferSubsetDifference = (float *)calloc(kSubSetLength,sizeof(float));
    return _fftMagnitudeBufferSubsetDifference;
}

/*
 -(float*) dilationLocalMaxFrequency {
 if(!_dilationLocalMaxFrequency)
 _dilationLocalMaxFrequency = (float *)calloc(kWindowLength,sizeof(float));
 return _dilationLocalMaxFrequency;
 }
 
 -(float*) localMaximums {
 if(!_localMaximums)
 _localMaximums = (float *)calloc(kNumOfMaximums, sizeof(float));
 return _localMaximums;
 }
 */

-(float) outputFrequency {
    if(!_outputFrequency)
        _outputFrequency = 17500;
    return _outputFrequency;
}

-(float) outputFrequencyPrevious {
    if(!_outputFrequencyPrevious)
        _outputFrequencyPrevious = 17500;
    return _outputFrequencyPrevious;
}

/*
- (IBAction)didUpdateFrequency:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float frequency = slider.value;
    
    self.label_Frequency.text = [NSString stringWithFormat:@"%.02f kHz", frequency / 1000.0];
    
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //float frequency = self.slider_Frequency.value;
    //self.label_Frequency.text = [NSString stringWithFormat:@"%.02f kHz", frequency / 1000.0];
    // Do any additional setup after loading the view.
    
    ringBuff = new RingBuffer(kBufferLength,2);
    
    self.graphHelper->SetBounds(-1,0.5,-0.5,0.5); // bottom, top, left, right, full screen==(-1,1,-1,1)
}

#pragma mark - GLKView

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    [self.audioManager play];
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(ringBuff!=nil)
             ringBuff->AddNewFloatData(data, numFrames);
     }];
    
}


#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    // stop opengl from running
    self.graphHelper->tearDownGL();
    [self.audioManager pause];
}

-(void)dealloc{
    self.graphHelper->tearDownGL();
    
    free(self.audioData);
    
    free(self.fftMagnitudeBuffer);
    free(self.fftPhaseBuffer);
    
    free(self.fftMagnitudeBuffer2);
    free(self.fftPhaseBuffer2);
    
    free(self.fftMagnitudeBuffer3);
    free(self.fftPhaseBuffer3);
    
    free(self.fftMagnitudeBufferAvg);
    free(self.fftMagnitudeBufferSubset);
    
    delete self.fftHelper;
    delete ringBuff;
    delete self.graphHelper;
    
    ringBuff = nil;
    self.fftHelper  = nil;
    self.audioManager = nil;
    self.graphHelper = nil;
    
    
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    
}


#pragma mark - OpenGL and Update functions
//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    self.graphHelper->draw(); // draw the graph
}


//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    //get current Frequency
    ModuleB_MasterVIewControllerViewController *master = [[ModuleB_MasterVIewControllerViewController alloc] init];
    __block float freq = 0;
    
    [master getFrequencyHandler:^(int frequency){
        freq = frequency;
    }];
    self.outputFrequencyPrevious = self.outputFrequency;
    self.outputFrequency = freq;
    
    // plot the audio
    ringBuff->FetchFreshData2(self.audioData, kBufferLength, 0, 1);
    
    //take the FFT
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer, self.fftPhaseBuffer);
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer2, self.fftPhaseBuffer2);
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer3, self.fftPhaseBuffer3);
    [self removeVarianceInMagnitude];
    //[self convertToDecibels];
    //[self findMaxUsingDilation];
    
    float frequencyIndex = self.outputFrequency;
    frequencyIndex /= kdf;
    int frequencyIdx = floor(frequencyIndex);
    
    //NSLog(@"frequencyIndex: %f, frequencyIdx: %d, outputFreq: %d, kdf: %f", frequencyIndex, frequencyIdx, (int)floor(self.outputFrequency), kdf);
    
    for(int i=0; i<kSubSetLength; i++) {
        if(frequencyIdx - kSubSetLength/2 < 0) {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[i];
            //NSLog(@"@1:");
        }
        else if(frequencyIdx + kSubSetLength/2 > kBufferLength/2) {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[ kBufferLength/2 - kSubSetLength + i];
            //NSLog(@"@2:");
        }
        else {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[frequencyIdx - kSubSetLength/2 + i];
            //NSLog(@"@3:");
        }
    }
    
    //NSLog(@"",self.)
    
    
    // plot the FFT
    //self.graphHelper->setGraphData(0,self.fftMagnitudeBufferAvg,kBufferLength/2,sqrt(kBufferLength));
    self.graphHelper->setGraphData(0,self.fftMagnitudeBufferSubset,kSubSetLength,sqrt(kSubSetLength)); // set graph channel
    //self.graphHelper->setGraphData(1,self.fftMagnitudeBuffer2,kBufferLength/8,sqrt(kBufferLength));
    //self.graphHelper->setGraphData(2,self.fftMagnitudeBuffer3,kBufferLength/8,sqrt(kBufferLength));
    
    if(self.outputFrequency == self.outputFrequencyPrevious)
    {
        int nNearestFreq = 10;
        
        for(int i=0; i<kSubSetLength; i++) {
            self.fftMagnitudeBufferSubsetDifference[i] = self.fftMagnitudeBufferSubset[i] - self.fftMagnitudeBufferSubsetPrevious[i];
        }
        float averageDifference_left = 0;
        float averageDifference_right = 0;
        
        for(int i=kSubSetLength/2 - nNearestFreq; i<kSubSetLength/2; i++) {
            averageDifference_left += self.fftMagnitudeBufferSubsetDifference[i];
        }
        averageDifference_left /= nNearestFreq;
        
        for(int i=kSubSetLength/2 + nNearestFreq; i>kSubSetLength/2; i--) {
            averageDifference_right += self.fftMagnitudeBufferSubsetDifference[i];
            //NSLog(@"right");
        }
        averageDifference_right /= nNearestFreq;
        
        /*
        for(int i=kSubSetLength/2 - kSubSetLength/4; i<kSubSetLength/2; i++) {
            averageDifference_left += self.fftMagnitudeBufferSubsetDifference[i];
        }
        averageDifference_left /= (kSubSetLength/4);
        
        for(int i=kSubSetLength-1; i>kSubSetLength/2; i--) {
            averageDifference_right += self.fftMagnitudeBufferSubsetDifference[i];
            //NSLog(@"right");
        }
        averageDifference_right /= (kSubSetLength/4);
        */
        NSLog(@"leftDifference: %.02f, rightDifference: %.02f", averageDifference_left, averageDifference_right);
    }
    else {
        NSLog(@"Frequency Tone Changed");
    }
    
}

-(void)removeVarianceInMagnitude{
    
    for(int i = 0; i < kBufferLength/2; i++){
        
        self.fftMagnitudeBufferAvg[i] = (self.fftMagnitudeBuffer[i] + self.fftMagnitudeBuffer2[i] + self.fftMagnitudeBuffer3[i])/3;
        
    }
    
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
