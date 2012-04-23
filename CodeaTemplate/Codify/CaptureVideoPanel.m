//
//  CaptureVideoPanel.m
//  Codea
//
//  Created by Simeon Nasilowski on 15/01/12.
//  
//  Copyright 2012 Two Lives Left Pty. Ltd.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "CaptureVideoPanel.h"

@implementation CaptureVideoPanel

@synthesize recordingPanelTitle, completionHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Presentation

- (void) presentInParentVC:(UIViewController*)parent
{
    [parent addChildViewController:self];
    
    [parent.view addSubview:self.view];
    
    self.view.frame = parent.view.bounds;
    self.view.backgroundColor = [UIColor clearColor];
    
    capturePanel.center = CGPointMake(self.view.bounds.size.width * 0.5f, self.view.bounds.size.height + capturePanel.bounds.size.height * 0.5f);
    
    [UIView animateWithDuration:0.3f animations:^
     {
         self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];        
         capturePanel.center = CGPointMake(self.view.bounds.size.width * 0.5f, self.view.bounds.size.height * 0.5f);
     }];    
}

- (void) dismiss
{
    [UIView animateWithDuration:0.3f animations:^
     {
         self.view.backgroundColor = [UIColor clearColor];                 
         capturePanel.center = CGPointMake(self.view.bounds.size.width * 0.5f, self.view.bounds.size.height + capturePanel.bounds.size.height * 0.5f);
     } completion:^(BOOL finished) 
     {
         [self detachFromParentVC];
         
         self.completionHandler( completionType );
     }];       
}

- (void) detachFromParentVC
{
    [self removeFromParentViewController];
    [self.view removeFromSuperview];    
}

#pragma mark - Actions

- (IBAction)discardButtonPressed:(id)sender 
{
    completionType = CapturedVideoCompletionDiscard;
    [self dismiss];
}

- (IBAction)saveButtonPressed:(id)sender 
{
    completionType = CapturedVideoCompletionSave;
    [self dismiss];    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    recordingPanelTitle.font = [UIFont fontWithName:@"MyriadPro-Regular" size:22.0f];
    recordingInfo.font = [UIFont fontWithName:@"MyriadPro-Regular" size:18.0f];    
}

- (void)viewDidUnload
{
    [self setRecordingPanelTitle:nil];
    [recordingInfo release];
    recordingInfo = nil;
    [capturePanel release];
    capturePanel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc 
{
    [completionHandler release];    
    [recordingPanelTitle release];
    [recordingInfo release];
    [capturePanel release];
    [super dealloc];
}
@end
