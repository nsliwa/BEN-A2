//
//  FrequenciesViewController.m
//  TeamBEN-A2
//
//  Created by ch484-mac5 on 2/14/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "FrequenciesViewController.h"
#import "ModuleA_MasterViewController.h"
#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUFFTHelper.h"
#import "SMUGraphHelper.h"

#define kSamplingRate 44100.00
#define kBufferLength 8192 //14700 //4096
#define kframesPerSecond 30
#define knumDataArraysToGraph 1
#define kWindowLength 10
#define kNumOfMaximums 2
#define kdf kSamplingRate/kBufferLength

@interface FrequenciesViewController ()

@property (strong, nonatomic) Novocaine *audioManager;
@property (nonatomic)GraphHelper *graphHelper;
@property (nonatomic)float *audioData;

@property (nonatomic)SMUFFTHelper *fftHelper;
@property (nonatomic)float *fftMagnitudeBuffer;
@property (nonatomic)float *fftPhaseBuffer;

@property (nonatomic)float *dilationLocalMaxFrequency;
@property (nonatomic)float *localMaximums;
@property (weak, nonatomic) IBOutlet UILabel *firstFrequency;
@property (weak, nonatomic) IBOutlet UILabel *secondFrequency;


@end

@implementation FrequenciesViewController

RingBuffer *ringBuffer;

-(Novocaine*) audioManager {
    if(!_audioManager)
        _audioManager = [Novocaine audioManager];
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    [self.audioManager play];
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
        if(ringBuffer!=nil)
            ringBuffer->AddNewFloatData(data, numFrames);
     }];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ringBuffer = new RingBuffer(kBufferLength,2);
    
    self.graphHelper->SetBounds(-0.8,0.8,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)
    
    
    
}


#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // stop opengl from running
    self.graphHelper->tearDownGL();
    [self.audioManager pause];
}

-(void)dealloc{
    self.graphHelper->tearDownGL();
    
    free(self.audioData);
    
    free(self.fftMagnitudeBuffer);
    free(self.fftPhaseBuffer);
    
    delete self.fftHelper;
    delete ringBuffer;
    delete self.graphHelper;
    
    ringBuffer = nil;
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
    
    // plot the audio
    ringBuffer->FetchFreshData2(self.audioData, kBufferLength, 0, 1);
    
    //take the FFT
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer, self.fftPhaseBuffer);
    //[self convertToDecibels];
    [self findMaxUsingDilation];
    
    // plot the FFT
    self.graphHelper->setGraphData(0,self.fftMagnitudeBuffer,kBufferLength/4,sqrt(kBufferLength)); // set graph channel
    
}
/*
#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}
*/
/*
-(void)convertToDecibels{
    
    for(int i = 0; i < kBufferLength/2; i++){
        self.fftMagnitudeBuffer[i] = 20 * log10f(self.fftMagnitudeBuffer[i]);
    }
    
}
*/

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
        
        self.fftMagnitudeBuffer[i] = 20 * log10f(self.fftMagnitudeBuffer[i]);
        
        for(int j = 0; j < kWindowLength; j++){
            
            if(self.fftMagnitudeBuffer[i+j] >= tempMax && self.fftMagnitudeBuffer[i+j] > 30){
                tempMax = self.fftMagnitudeBuffer[i+j];
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
        self.firstFrequency.text = [NSString stringWithFormat:@"1st frequency: %d",interpolatedMax];
        self.secondFrequency.text = [NSString stringWithFormat:@"2nd frequency: %d",interpolatedMax2];
        
        
    }
}



-(int)peakInterpolation: (int) index{
    
    int f2 = index*kdf;
    
    float m3 = self.fftMagnitudeBuffer[index+1];
    float m2 = self.fftMagnitudeBuffer[index];
    float m1 = self.fftMagnitudeBuffer[index-1];
    
    //int interpolated = f2 + ((m3-m2)/(2*m2-m1-m2))*(kdf/2);
    int interpolated = f2 + ((m3 - m1)/(2*m2 - m1 - m3))*(kdf/2);
    
    //NSLog(@"Interpolated %d to %d ", old, interpolated);
    
    return interpolated;
    
}


@end
