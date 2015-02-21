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
#define kBufferLength 8192 //14700 //4096
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
    
    [super viewDidDisappear:animated];
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
    [self findMaxUsingDilation];
    
    // plot the FFT
    self.graphHelperPiano->setGraphData(0,self.fftMagnitudeBufferPiano,kBufferLength/4,sqrt(kBufferLength)); // set graph channel
    
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
        NSLog(@"Maximum harmonic frequency: %@", [self determineNote:(interpolatedMax) secondFreq:(interpolatedMax2)]);
        self.noteLabel.text = [self determineNote:(interpolatedMax) secondFreq:(interpolatedMax2)];
        
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

-(NSString*)determineNote: (int) max1
               secondFreq: (int) max2{
    
    NSString* note;
    
    if ( ((max1 >= 438 && max1 <= 442) && (max2 >= 218 && max2 <= 220)) ||
        ((max2 >= 438 && max2 <= 442) && (max1 >= 218 && max1 <= 220)) )
            note = @"A2";
    else if ( ((max1 >= 463 && max1 <= 467) && (max2 >= 230 && max2 <= 234)) ||
        ((max2 >= 463 && max2 <= 467) && (max1 >= 230 && max1 <= 234)) )
            note = @"A#2";
    else if ( ((max1 >= 491 && max1 <= 496) && (max2 >= 242 && max2 <= 248)) ||
        ((max2 >= 491 && max2 <= 496) && (max1 >= 242 && max1 <= 248)) )
            note = @"B2";
    else if ( ((max1 >= 521 && max1 <= 525) && (max2 >= 259 && max2 <= 263)) ||
        ((max2 >= 521 && max2 <= 525) && (max1 >= 259 && max1 <= 263)) )
            note = @"C2";
    else if ( ((max1 >= 552 && max1 <= 556) && (max2 >= 274 && max2 <= 278)) ||
        ((max2 >= 552 && max2 <= 556) && (max1 >= 274 && max1 <= 278)) )
            note = @"C#2";
    else if ( ((max1 >= 584 && max1 <= 588) && (max2 >= 291 && max2 <= 295)) ||
        ((max2 >= 584 && max2 <= 588) && (max1 >= 291 && max1 <= 295)) )
            note = @"D2";
    else if ( ((max1 >= 621 && max1 <= 627) && (max2 >= 304 && max2 <= 313)) ||
        ((max2 >= 621 && max2 <= 627) && (max1 >= 304 && max1 <= 313)) )
            note = @"D#2";
    else if ( ((max1 >= 696 && max1 <= 698) && (max2 >= 345 && max2 <= 348)) ||
             ((max2 >= 696 && max2 <= 698) && (max1 >= 345 && max1 <= 348)) )
            note = @"F3";
    else if ( ((max1 >= 735 && max1 <= 740) && (max2 >= 366 && max2 <= 372)) ||
             ((max2 >= 735 && max2 <= 740) && (max1 >= 366 && max1 <= 372)) )
            note = @"F#3";
    else if ( ((max1 >= 1247 && max1 <= 1250) && (max2 >= 410 && max2 <= 348)) ||
             ((max2 >= 1247 && max2 <= 1250) && (max1 >= 410 && max1 <= 348)) )
            note = @"G3";
    else if ( ((max1 >= 1321 && max1 <= 1325) && (max2 >= 436 && max2 <= 442)) ||
             ((max2 >= 1321 && max2 <= 1325) && (max1 >= 436 && max1 <= 442)) )
            note = @"A3";
    else
        note = @"Not yet recognized";
    
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
