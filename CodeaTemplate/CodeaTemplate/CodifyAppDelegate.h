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


#import <Foundation/Foundation.h>

@class LuaState;
@class Project;

@interface CodifyAppDelegate : UIResponder<UIApplicationDelegate>
{
    UIViewController* viewController;

    Project* currentProject;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController* viewController;

@property (nonatomic, readonly) LuaState *scriptState;

+(Project*) currentProject;
+(CodifyAppDelegate*)delegate;

- (void) showRenderView:(BOOL)show animated:(BOOL)animated;

@end
