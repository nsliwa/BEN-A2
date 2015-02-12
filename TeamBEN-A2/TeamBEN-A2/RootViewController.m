//
//  RootViewController.m
//  TeamBEN-A2
//
//  Created by Nicole Sliwa on 2/11/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController
-(void)viewDidLoad {
    
}

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
    else {// if(indexPath.section==1){
        
        // this is for section 1:
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell_ModuleB" forIndexPath:indexPath];
        
        cell.textLabel.text = @"Module B";
        cell.detailTextLabel.text = @"Dopplar Gestures";
    }
    
    return cell;
}

@end
