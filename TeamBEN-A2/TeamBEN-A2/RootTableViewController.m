//
//  RootTableViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "RootTableViewController.h"

@implementation RootTableViewController

-(void)viewDidLoad {
    
}

-(IBAction)onModuleAPressed:(UITableViewCell*)sender {
    
}
/*
@IBAction func onViewTimelinePressed(sender: UIButton)
{
    var storyboard = UIStoryboard(name: "timeline", bundle: nil)
    var controller = storyboard.instantiateViewControllerWithIdentifier("InitialController") as UIViewController
    
    self.presentViewController(controller, animated: true, completion: nil)
}
*/



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = nil;
    
    if(indexPath.section==0){
        // this is for section 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell_ModuleA" forIndexPath:indexPath];
        
        cell.textLabel.text = @"Module A";
        cell.detailTextLabel.text = @"Frequency Detection";
    }
    else if(indexPath.section==1){
        
        // this is for section 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell_ModuleB" forIndexPath:indexPath];
        
        cell.textLabel.text = @"Module B";
        cell.detailTextLabel.text = @"Dopplar Gestures";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyBoard;
    UIViewController *controller;
    
    if(indexPath.section == 0) {
        NSLog(@"row 0 selected");
        storyBoard = [UIStoryboard storyboardWithName:@"Main_ModuleA" bundle:nil];
        NSLog(@"found storyboard a");
        controller = [storyBoard instantiateViewControllerWithIdentifier:@"ModuleA_MasterViewController"];
        NSLog(@"ModuleA_MasterViewController");
        
        //[controller setModalPresentationStyle:UIModalPresentationFullScreen];
        [self presentViewController:controller animated:YES completion:nil];
        NSLog(@"presented view");
    }
    
    else if(indexPath.section == 1) {
        NSLog(@"row 1 selected");
        storyBoard = [UIStoryboard storyboardWithName:@"Main_ModuleB" bundle:nil];
        NSLog(@"found storyboard b");
        controller = [storyBoard instantiateViewControllerWithIdentifier:@"ModuleB_MasterViewController"];
        NSLog(@"ModuleB_MasterViewController");
        
        //[controller setModalPresentationStyle:UIModalPresentationFullScreen];
        [self presentViewController:controller animated:YES completion:nil];
        NSLog(@"presented view");
    }
}

@end
