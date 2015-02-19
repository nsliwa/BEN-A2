//
//  ModuleB_MasterVIewControllerViewController.h
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


// for callback: http://stackoverflow.com/questions/1015608/how-to-perform-callbacks-in-objective-c
@interface ModuleB_MasterVIewControllerViewController : UIViewController
{
    void (^_frequencyHandler)(int freq);
}

//@property (weak, nonatomic) IBOutlet UILabel *label_Frequency;

- (void) getFrequencyHandler:(void(^)(int))handler;


@end
