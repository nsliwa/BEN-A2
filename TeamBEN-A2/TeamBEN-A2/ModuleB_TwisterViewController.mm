//
//  ModuleB_TwisterViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/20/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "ModuleB_TwisterViewController.h"

#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUFFTHelper.h"

#import <math.h>

#define kSamplingRate 44100.00 //Hz
#define kBufferLength 8192//4096
#define kSpectrumLength kBufferLength/2
#define kdf kSamplingRate/kBufferLength

#define kframesPerSecond 30
#define kSubSetLength 25
#define kThrowAway 20
#define kCalibrate 20
#define kArchive 4

#define kFrequency 17500.00

@interface ModuleB_TwisterViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *image_spinner;
@property (weak, nonatomic) IBOutlet UIImageView *image_dial;

// Audio Processing properties
@property (strong, nonatomic) Novocaine *audioManager;
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
@property (nonatomic)float *fftMagnitudeBufferSubsetBaseline;

@property (nonatomic)float *fftMagnitudeBufferSubsetDifference;

@property (nonatomic)int throwAwayCount;
@property (nonatomic)float spin;


// idea for "ideal threshold" from Jarret Shook
@property (nonatomic)float leftThreshold;
@property (nonatomic)float rightThreshold;

@property (strong, nonatomic)NSMutableArray *gesturePrevious;

//@property (strong, nonatomic)NSTimer* updateFFT;

@property (nonatomic)int windupCount;
@property (nonatomic)int spinCount;

@end

@implementation ModuleB_TwisterViewController

- (IBAction)didClickCalibrate:(id)sender {
    self.throwAwayCount = 0;
}

RingBuffer *ringBuffT;


-(Novocaine*) audioManager {
    if(!_audioManager)
        _audioManager = [Novocaine audioManager];
    NSLog(@"Sampling rate: %f", _audioManager.samplingRate);
    return _audioManager;
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

-(float*) fftMagnitudeBufferSubsetBaseline {
    if(!_fftMagnitudeBufferSubsetBaseline)
        _fftMagnitudeBufferSubsetBaseline = (float *)calloc(kSubSetLength,sizeof(float));
    return _fftMagnitudeBufferSubsetBaseline;
}

-(float*) fftMagnitudeBufferSubsetDifference {
    if(!_fftMagnitudeBufferSubsetDifference)
        _fftMagnitudeBufferSubsetDifference = (float *)calloc(kSubSetLength,sizeof(float));
    return _fftMagnitudeBufferSubsetDifference;
}

-(int) throwAwayCount {
    if(!_throwAwayCount)
        _throwAwayCount = 0;
    return _throwAwayCount;
}

-(float) leftThreshold {
    if(!_leftThreshold)
        _leftThreshold = 0;
    return _leftThreshold;
}

-(float) rightThreshold {
    if(!_rightThreshold)
        _rightThreshold = 0;
    return _rightThreshold;
}

-(NSMutableArray*) gesturePrevious {
    if(!_gesturePrevious)
        _gesturePrevious = [[NSMutableArray alloc]init];
    return _gesturePrevious;
}

-(int) windupCount {
    if(!_windupCount)
        _windupCount = 0;
    return _windupCount;
}

-(float) spin {
    if(!_spin)
        _spin = 0.0;
    return _spin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //http://www.ioscreator.com/tutorials/auto-layout-in-ios-6-keep-aspect-ratio-of-image
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.image_spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f];
    
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.image_spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f];
    
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.image_spinner attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f];
    
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.image_spinner attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.image_spinner attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f];
    
    [self.image_spinner addConstraint:constraint];
    
    //[self runSpinAnimationOnView:self.image_spinner duration:1 rotations:1 repeat:1];
    //self.image_spinner.backgroundColor = [UIColor greenColor];
    //self.image_spinner.alpha = .5;
    
    ringBuffT = new RingBuffer(kBufferLength,2);
    
    /*
    self.updateFFT = [NSTimer scheduledTimerWithTimeInterval:1 / kframesPerSecond
                                     target:self
                                   selector:@selector(update)
                                   userInfo:nil
                                    repeats:YES];
    */
    
    
    UIBarButtonItem *calibrateButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Calibrate"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(didClickCalibrate:)];
    self.navigationItem.rightBarButtonItem = calibrateButton;
    
}


- (void) runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat;
{
    
    CGFloat rotationTemp = fmodf(rotations, 16) / 16.0;//(float)(rotations%16)/16.0
    
    //self.spin += M_PI * 2.0 * rotations * duration;
    /*
    if(rotations > 0 && repeat > 0 && duration > 0) {
        [UIView animateWithDuration:1.5//duration
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             //CGAffineTransform move = CGAffineTransformMakeTranslation(40, 40);
                             //CGAffineTransform zoom    = CGAffineTransformMakeScale(1.2, 1.2);
                             CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI * 2.0 * rotationTemp * repeat);
                             //CGAffineTransformConcat(zoom, move);
                             self.image_spinner.transform = transform;
                         }
                         completion:^(BOOL finished){
                             NSLog(@"ANIMATED duration:%f windup:%f rotations:%f repeat:%f transform:%f z-position:%f", duration, rotations, rotationTemp, repeat, M_PI * 2.0 * rotations*repeat, view.layer.zPosition);
                         }];
    }
    */
    
    NSLog(@"ANIMATING duration:%f windup:%f rotations:%f repeat:%f transform:%f z-position:%f", duration, rotations, rotationTemp, repeat, M_PI * 2.0 * rotations*repeat, view.layer.zPosition);
    
    
    if(rotations > 0 && repeat > 0 && duration > 0) {
    
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * rotationTemp * duration ];
        rotationAnimation.duration = 1;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = repeat;
        rotationAnimation.removedOnCompletion = NO;
        rotationAnimation.fillMode = kCAFillModeForwards;
        //[view setTransform:[NSValue valueWithCATransform3D:scale4]];
        
        [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        
        NSLog(@"ANIMATING duration:%f windup:%f rotations:%f repeat:%f transform:%f", duration, rotations, rotationTemp, repeat, M_PI * 2.0 * rotations*repeat);
        
    }
    
    
}











-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    // create a sine wave and then play it on the speakers!!
    float frequency = kFrequency; //500;//self.slider_Frequency.value; // 261.0; //starting frequency
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         //g(t) = sin(2*PI*frequency*time)
         //time = n/sampling rate
         //n = current frame
         double phaseIncrement = 2*M_PI*frequency/samplingRate;
         double repeatMax = 2*M_PI;
         
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
    
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(ringBuffT!=nil)
             ringBuffT->AddNewFloatData(data, numFrames);
     }];
    
}

// pause the audio when off screen
-(void) viewWillDisappear:(BOOL)animated{
    
    [self.audioManager pause]; // just pause the playing
    // audio manager is a singleton class, so we do not need to
    // tear it down, in case some other controller may want to use it
    
    // should we do anything here?
    //[self.updateFFT invalidate];
    
    [super viewWillDisappear:animated];
}

#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self.audioManager pause];
}

-(void)dealloc{
    
    free(self.audioData);
    
    free(self.fftMagnitudeBuffer);
    free(self.fftPhaseBuffer);
    
    free(self.fftMagnitudeBuffer2);
    free(self.fftPhaseBuffer2);
    
    free(self.fftMagnitudeBuffer3);
    free(self.fftPhaseBuffer3);
    
    free(self.fftMagnitudeBufferAvg);
    free(self.fftMagnitudeBufferSubset);
    free(self.fftMagnitudeBufferSubsetBaseline);
    free(self.fftMagnitudeBufferSubsetDifference);
    
    delete self.fftHelper;
    delete ringBuffT;
    
    ringBuffT = nil;
    self.fftHelper  = nil;
    self.audioManager = nil;
    
    
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    
}









//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    // plot the audio
    ringBuffT->FetchFreshData2(self.audioData, kBufferLength, 0, 1);
    
    //take the FFT
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer, self.fftPhaseBuffer);
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer2, self.fftPhaseBuffer2);
    self.fftHelper->forward(0,self.audioData, self.fftMagnitudeBuffer3, self.fftPhaseBuffer3);
    [self removeVarianceInMagnitude];
    [self convertToDecibels];
    
    float frequencyIndex = kFrequency;
    frequencyIndex /= kdf;
    int frequencyIdx = floor(frequencyIndex);
    
    
    for(int i=0; i<kSubSetLength; i++) {
        if(frequencyIdx - kSubSetLength/2 < 0) {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[i];
        }
        else if(frequencyIdx + kSubSetLength/2 > kBufferLength/2) {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[ kBufferLength/2 - kSubSetLength + i];
        }
        else {
            self.fftMagnitudeBufferSubset[i] = self.fftMagnitudeBufferAvg[frequencyIdx - kSubSetLength/2 + i];
        }
    }
    
    if(self.throwAwayCount == kCalibrate + kThrowAway)
    {
        int maxIdx = 0;
        float maxFreq = 0;
        
        for(int i=0; i<kSubSetLength; i++) {
            self.fftMagnitudeBufferSubsetDifference[i] = self.fftMagnitudeBufferSubset[i] - self.fftMagnitudeBufferSubsetBaseline[i];
            
            if(self.fftMagnitudeBufferSubsetDifference[i] > maxFreq) {
                maxFreq = self.fftMagnitudeBufferSubsetDifference[i];
                maxIdx = i;
            }
        }
        
        /*
         if(maxIdx > kSubSetLength/2 +2 && self.fftMagnitudeBufferSubsetDifference[maxIdx] > self.rightThreshold*1.1) {
         NSLog(@"maxIdx: %d, difference: %f, trueThreshold: %f", maxIdx, self.fftMagnitudeBufferSubsetDifference[maxIdx], self.rightThreshold);
         NSLog(@"TOWARD");
         dispatch_async(dispatch_get_main_queue(), ^ {parent.label_Gesture.text = @"TOWARD";});
         }
         else if(maxIdx < kSubSetLength/2 -2 && self.fftMagnitudeBufferSubsetDifference[maxIdx] > self.leftThreshold*1.1) {
         NSLog(@"maxIdx: %d, difference: %f, trueThreshold: %f", maxIdx, self.fftMagnitudeBufferSubsetDifference[maxIdx], self.leftThreshold);
         NSLog(@"AWAY");
         dispatch_async(dispatch_get_main_queue(), ^ {parent.label_Gesture.text = @"AWAY";});
         }
         else {
         NSLog(@"maxIdx: %d, difference: %f, rightThreshold: %f, leftThreshold: %f", maxIdx, self.fftMagnitudeBufferSubsetDifference[maxIdx], self.rightThreshold, self.leftThreshold);
         NSLog(@"-----");
         dispatch_async(dispatch_get_main_queue(), ^ {parent.label_Gesture.text = @"STATIONARY";});
         }
         */
        
        NSLog(@"maxIdx: %d, difference: %f, trueThreshold: %f", maxIdx, self.fftMagnitudeBufferSubsetDifference[maxIdx], 4.0);
        
        
        
        if(self.fftMagnitudeBufferSubsetDifference[maxIdx] > 4) {
            if(maxIdx > kSubSetLength/2 +2) {
                if([self.gesturePrevious count] > 1 && [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @1] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @1]) {
                    NSLog(@"TOWARD windup: %d", self.windupCount++);
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        self.image_spinner.alpha = .5;
                    });
                }

                [self.gesturePrevious addObject:@1];
            }
            else if(maxIdx < kSubSetLength/2 -2) {
                if([self.gesturePrevious count] > 1 && [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @-1] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @-1]) {
                    NSLog(@"AWAY spin: %d", self.spinCount++);
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        self.image_spinner.alpha = .75;
                        //[self runSpinAnimationOnView:self.image_spinner duration:1/kframesPerSecond rotations:(float)(self.windupCount%16)/16.0 repeat:1];
                    });
                }
                [self.gesturePrevious addObject:@-1];
            }
        }
        else {
            if([self.gesturePrevious count] > 1 && [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @1] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @1]) {
                NSLog(@"----- windup: %d", self.windupCount++);
                dispatch_async(dispatch_get_main_queue(), ^
                   {
                       self.image_spinner.alpha = .5;
                   });
            }
            else if([self.gesturePrevious count] > 1 && [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @-1] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @-1]) {
                NSLog(@"----- spin: %d", self.spinCount++);
                dispatch_async(dispatch_get_main_queue(), ^
                   {
                       self.image_spinner.alpha = .75;
                       //[self runSpinAnimationOnView:self.image_spinner duration:1/kframesPerSecond rotations:(float)(self.windupCount%16)/16.0 repeat:1];
                   });
                [self.gesturePrevious addObject:@0];
            }
            else if([self.gesturePrevious count] > 1 && [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @0] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @-1]) {
                NSLog(@"------ windup: %d spin: %d", self.windupCount, self.spinCount);
                
                int tempWindup = self.windupCount;
                int tempSpin = self.spinCount;
                
                dispatch_async(dispatch_get_main_queue(), ^
                   {
                       self.image_spinner.alpha = 1;
                       [self runSpinAnimationOnView:self.image_spinner duration:5 rotations:tempWindup repeat:sqrt(tempSpin)];
                   });
                
                self.windupCount = 0;
                self.spinCount = 0;
                
                [self.gesturePrevious addObject:@0];
            }
            else {
                NSLog(@"-----");
            }

            
            /*
            if([self.gesturePrevious count] > 2) {
                if( [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @0] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @0]) {
                    if([self.gesturePrevious[ [self.gesturePrevious count] -3 ]  isEqual: @-1]) {
                        NSLog(@"------ windup: %d spin: %d", self.windupCount, self.spinCount);
                        dispatch_async(dispatch_get_main_queue(), ^
                                       {
                                           self.image_spinner.alpha = 1;
                                           [self runSpinAnimationOnView:self.image_spinner duration:1/kframesPerSecond rotations:(float)(self.windupCount%16)/16.0 repeat:self.spinCount*10];
                                       });
                        self.windupCount = 0;
                        self.spinCount = 0;
                        
                        [self.gesturePrevious addObject:@0];
                    }
                    else if( [self.gesturePrevious[ [self.gesturePrevious count] -1 ]  isEqual: @-1] && [self.gesturePrevious[ [self.gesturePrevious count] - 2]  isEqual: @-1]) {
                        NSLog(@"AWAY spin: %d", self.spinCount++);
                        dispatch_async(dispatch_get_main_queue(), ^
                           {
                               self.image_spinner.alpha = .75;
                               //[self runSpinAnimationOnView:self.image_spinner duration:1/kframesPerSecond rotations:(float)(self.windupCount%16)/16.0 repeat:1];
                           });
                    }
                }
            }
             */
        }
        
        
        if([self.gesturePrevious count] == kArchive) {
            //NSLog(@"removing object");
            [self.gesturePrevious removeObjectAtIndex:0];
        }
    }
    else {
        NSLog(@"Frequency Tone Changed");
        
        if(self.throwAwayCount == kThrowAway + kCalibrate) {
            self.throwAwayCount = 0;
        }
        
        self.throwAwayCount++;
        
        if(self.throwAwayCount > kThrowAway) {
            for(int i=0; i<kSubSetLength; i++) {
                self.fftMagnitudeBufferSubsetBaseline[i] = self.fftMagnitudeBufferSubset[i];
            }
            
            if(self.throwAwayCount <= kThrowAway + kCalibrate) {
                float max = 0;
                for(int j=0; j<kSubSetLength/2; j++) {
                    if(self.fftMagnitudeBufferSubset[j] > max) {
                        max = self.fftMagnitudeBufferSubset[j];
                    }
                }
                self.leftThreshold += max;
                
                max = 0;
                for(int j=kSubSetLength/2 + 3; j<kSubSetLength; j++) {
                    if(self.fftMagnitudeBufferSubset[j] > max) {
                        max = self.fftMagnitudeBufferSubset[j];
                    }
                }
                self.rightThreshold +=max;
            }
            if(self.throwAwayCount == kThrowAway + kCalibrate) {
                self.leftThreshold /= kCalibrate;
                self.rightThreshold /= kCalibrate;
            }
        }
    }
    
}

-(void)removeVarianceInMagnitude{
    
    for(int i = 0; i < kBufferLength/2; i++){
        
        self.fftMagnitudeBufferAvg[i] = (self.fftMagnitudeBuffer[i] + self.fftMagnitudeBuffer2[i] + self.fftMagnitudeBuffer3[i])/3;
        
    }
    
}

-(void)convertToDecibels{
    
    for(int i = 0; i < kBufferLength/2; i++){
        self.fftMagnitudeBufferAvg[i] = 20 * log10f(self.fftMagnitudeBufferAvg[i]);
    }
    
}




@end
