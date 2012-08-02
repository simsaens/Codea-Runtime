//
//  Project.h
//  Codea
//
//  Created by Dylan Sale on 26/01/12.
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

#import "Bundle.h"

@interface Project : Bundle
{
    NSMutableArray *bufferNames;
    NSMutableArray *buffers;
    
    BOOL userProject;
}
@property (nonatomic,assign) BOOL userProject;

@property (nonatomic,readonly) NSMutableArray *bufferNames;
@property (readonly) NSMutableArray *buffers;
@property (nonatomic,readonly) NSArray *codeFiles;
@property (nonatomic,readonly) NSArray *dependencies;

@property (nonatomic,readonly) BOOL isLoaded;

- (BOOL) writeToBundlePath:(NSString*)bundlePath;

- (void) load;
- (void) unload;

- (BOOL) hasDependency:(NSString*)projectName;
- (void) addDependency:(NSString*)projectName;
- (void) removeDependency:(NSString*)projectName;

@end