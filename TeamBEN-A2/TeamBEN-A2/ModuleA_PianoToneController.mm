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

@property (strong, nonatomic) Novocaine *audioManager;
@property (nonatomic)GraphHelper *graphHelperPiano;
@property (nonatomic)float *audioData;

@property (nonatomic)SMUFFTHelper *fftHelper;
@property (nonatomic)float *fftMagnitudeBuffer;
@property (nonatomic)float *fftPhaseBuffer;

@property (nonatomic)float *dilationLocalMaxFrequency;
@property (nonatomic)float *localMaximums;

@end

@implementation ModuleA_PianoToneController

RingBuffer *ringBufferPiano;

-(Novocaine*) audioManager {
    if(!_audioManager)
        _audioManager = [Novocaine audioManager];
    return _audioManager;
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
    [self.audioManager pause];
}

-(void)dealloc{
    self.graphHelperPiano->tearDownGL();
    
    free(self.audioData);
    
    free(self.fftMagnitudeBuffer);
    free(self.fftPhaseBuffer);
    
    delete self.fftHelper;
    delete ringBufferPiano;
    delete self.graphHelperPiano;
    
    ringBufferPiano = nil;
    self.fftHelper  = nil;
    self.audioManager = nil;
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
    ringBufferPiano->FetchFreshData2(self.audioData, kBufferLength, 0, 1);
    
    //take the FFT
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer, self.fftPhaseBuffer);
    //[self convertToDecibels];
    
    // plot the FFT
    self.graphHelperPiano->setGraphData(0,self.fftMagnitudeBuffer,kBufferLength/4,sqrt(kBufferLength)); // set graph channel
    
}

#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
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
