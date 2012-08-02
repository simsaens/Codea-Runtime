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

//
//  CodifyAppDelegate.h
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

//
//  CodifyAppDelegate.m
//  Codify
//
//  Created by Simeon Nasilowski on 14/05/11.
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

#import "CodifyAppDelegate.h"
#import "CodifyScriptExecute.h"
#import "LuaState.h"
#import "Project.h"
#import "SharedRenderer.h"

#import "OALSimpleAudio.h"

@interface CodifyAppDelegate()
- (BOOL) migrateProjectAtPath:(NSString*)path toPath:(NSString*)destPath;
@property (nonatomic, retain) Project* currentProject;
@end

@implementation CodifyAppDelegate

@synthesize scriptState;
@synthesize window=_window;
@synthesize viewController;
@synthesize currentProject;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Create the Lua scripting state
    scriptState = [[LuaState alloc] init];
        
    self.viewController = [SharedRenderer renderer]; //[[[UIViewController alloc] init] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];    
    if ( [url isFileURL] )
    {
        NSLog(@"Codify opened with file: %@", url);
        
        //[self openNewProject:url];
    }
    
    [OALSimpleAudio sharedInstance];
    
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Project.codea"];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *destPath = [documentsDirectory stringByAppendingPathComponent:@"Project.codea"];
    NSError* error = nil;
    
    //If there was an error copying it means we are upgrading the project rather than just installing it,
    //So we need to ask the user what to do.
    if(![[NSFileManager defaultManager] copyItemAtPath:path toPath:destPath error:&error])
    {
        if(![self migrateProjectAtPath:path toPath:destPath])
        {
            NSLog(@"Error migrating project");
        }
    }
    
        
    self.currentProject = [[[Project alloc] initWithPath:destPath validFileTypes:[NSArray arrayWithObjects:@"lua", @"plist", nil]] autorelease];
    [self showRenderView:YES animated:NO];
    [[CodifyScriptExecute sharedInstance] runProject:self.currentProject];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */    
    if( [SharedRenderer renderer].animating )
    {
        [[SharedRenderer renderer] stopAnimation];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [OALSimpleAudio sharedInstance];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    DBLog(@"Application did become active");
    
    
    [[SharedRenderer renderer] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */    
    if( [SharedRenderer renderer].animating )
    {
        [[SharedRenderer renderer] stopAnimation];
    }    
}

#pragma mark - Show the renderer

- (void)showRenderView:(BOOL)show animated:(BOOL)animated
{    
    if( show )
    {
        [SharedRenderer renderer].project = currentProject;
        [[SharedRenderer renderer] prepareViewForDisplay];        
        //[self.viewController presentModalViewController:renderController animated:animated]; //renderController is viewController
        [[SharedRenderer renderer] startAnimation];
    }
    else
    {
        //[self.viewController dismissModalViewControllerAnimated:animated]; //renderController is viewController
        [[SharedRenderer renderer] stopAnimation];                
    }    
}

#pragma mark - Helper functions

+ (CodifyAppDelegate*) delegate
{
    return (CodifyAppDelegate*)[UIApplication sharedApplication].delegate;
}

+(Project*) currentProject
{
    return [self delegate].currentProject;
}

- (NSString*) versionForProjectAtPath:(NSString*)path
{
    NSString* infoPlistFile = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary* infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistFile];
    NSString* version = [infoPlist objectForKey:@"Version"];
    if (!version) version = @"0";
    return version;
}

- (BOOL) migrateProjectAtPath:(NSString*)path toPath:(NSString*)destPath
{
    NSString* oldVersion = [self versionForProjectAtPath:destPath];
    NSString* newVersion = [self versionForProjectAtPath:path];
    
    if ([oldVersion isEqualToString:newVersion]) 
    {
        return YES;
    }
    
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for(NSString* content in contents)
    {
        NSArray* pathComponents = [content pathComponents];
        NSString* filename = [pathComponents lastObject];
//        if (![filename isEqualToString:@"Data.plist"]) //Just copy all the files across for now,
//        {
        //TODO: call into lua to check if this file should be updated from the previous version to the current one 
            NSString* destPathContent = [destPath stringByAppendingPathComponent:filename];
            NSString* pathContent = [path stringByAppendingPathComponent:filename];
            NSLog(@"Updating project file: %@",destPathContent);
            [[NSFileManager defaultManager] removeItemAtPath:destPathContent error:nil];
            
            if(![[NSFileManager defaultManager] copyItemAtPath:pathContent toPath:destPathContent error:nil])
            {
                return NO;
            }
//        }
    }
    return YES;
}

#pragma mark - Memory

- (void)dealloc
{
    [scriptState release];
    [_window release];
    [super dealloc];
}

@end
