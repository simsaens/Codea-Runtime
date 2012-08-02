//
//  ProjectManager.h
//  Codea
//
//  Created by Simeon Nasilowski on 17/09/11.
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

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "Bundle.h"
#import "Project.h"


@interface ProjectManager : NSObject
{
    NSArray *templateProjectsCache;
    NSArray *exampleProjectsCache;
    NSArray *userProjectsCache;    
}
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(ProjectManager);

@property (nonatomic,readonly) NSArray *templateProjects;
@property (nonatomic,readonly) NSArray *exampleProjects;
@property (nonatomic,readonly) NSArray *userProjects;

- (Project*) userProjectNamed:(NSString*)projectName;

- (void) reloadUserProjects;

- (BOOL) doesUserProjectExist:(NSString*)projectName;
- (BOOL) saveUserProject:(Project*)project;
- (BOOL) deleteUserProject:(Project*)project;

- (void) convertUsersCodifyProjectsToCodea;

- (Project*) createProject:(NSString*)name withTemplate:(Project*)projectTemplate;

@end
