//
//  ModuleA_MasterViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "ModuleA_MasterViewController.h"

@interface ModuleA_MasterViewController ()

@end

@implementation ModuleA_MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onFrequencyClick:(id)sender {
    
}

- (IBAction)onToneClick:(id)sender {
    UIStoryboard* storyBoard;
    UIViewController* controller;
    
    storyBoard = [UIStoryboard storyboardWithName:@"Piano" bundle:nil];
    NSLog(@"found storyboard piano");
    controller = [storyBoard instantiateViewControllerWithIdentifier:
                  //@"ModuleB_NavigationController"];
                  @"ModuleA_PianoToneController"];
    NSLog(@"ModuleA_PianoToneController");
    
    [self.navigationController pushViewController:controller animated:YES];

    
    
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
