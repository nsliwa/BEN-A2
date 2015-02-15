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

#define kBufferLength 14700 //4096
#define kframesPerSecond 30
#define knumDataArraysToGraph 1
#define kWindowLength 50
#define kNumOfMaximums 2
#define kdf 44100/kBufferLength

@interface FrequenciesViewController ()

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

@property (nonatomic)float *dilationLocalMaxFrequency;
@property (nonatomic)float *localMaximums;

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
    
    self.graphHelper->SetBounds(-0.5,0.8,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)
    
    
    
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
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer2, self.fftPhaseBuffer2);
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer3, self.fftPhaseBuffer3);
    [self removeVarianceInMagnitude];
    [self convertToDecibels];
    [self findMaxUsingDilation];
    
    // plot the FFT
    self.graphHelper->setGraphData(0,self.fftMagnitudeBufferAvg,kBufferLength/8,sqrt(kBufferLength)); // set graph channel
    //self.graphHelper->setGraphData(1,self.fftMagnitudeBuffer2,kBufferLength/8,sqrt(kBufferLength));
    //self.graphHelper->setGraphData(2,self.fftMagnitudeBuffer3,kBufferLength/8,sqrt(kBufferLength));
    
}

#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)removeVarianceInMagnitude{
    
    for(int i = 0; i < kBufferLength/2; i++){
        
        self.fftMagnitudeBufferAvg[i] = (self.fftMagnitudeBuffer[i] + self.fftMagnitudeBuffer2[i] + self.fftMagnitudeBuffer3[i])/3;
        
    }
    
}

-(void)convertToDecibels{
    
    for(int i = 0; i < kBufferLength/2; i++){
        if(self.fftMagnitudeBufferAvg[i] > 1)
            self.fftMagnitudeBufferAvg[i] = 20 * log10f(abs(self.fftMagnitudeBufferAvg[i]));
    }
    
}

-(void)findMaxUsingDilation{
    
    float max = 0.0;
    int maxIndex = 0;
    int interpolatedMax;
    
    for(int i = 0; i < kBufferLength/2 - kWindowLength; i++){
        
        for(int j = 0; j < kWindowLength; j++){
            
            if(self.fftMagnitudeBufferAvg[j+i]){
                max = self.fftMagnitudeBufferAvg[j+i];
                maxIndex = j;
            }
            
        }
        
        if(maxIndex == 24){
            
            //interpolatedMax = [self peakInterpolation:(i)];
            NSLog(@"found a max frequency %d", i*kdf); //interpolatedMax);
        }
        
    }
}

-(int)peakInterpolation: (int) index{
    
    int interpolated = index*kdf + (((self.fftMagnitudeBufferAvg[index+1] - self.fftMagnitudeBufferAvg[index])/(2*self.fftMagnitudeBufferAvg[index] - self.fftMagnitudeBufferAvg[index - 1] - self.fftMagnitudeBufferAvg[index+1])) * (kdf/2));
    
    NSLog(@"Interpolated %d to %d", index*kdf, interpolated);
    
    return interpolated;
    
}

@end
