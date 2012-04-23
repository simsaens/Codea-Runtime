//
//  Shader.h
//  TwoLivesLeft.com
//
//  Created by Simeon Nasilowski on 29/05/11.
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

//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>	

@interface Shader : NSObject 
{
    GLuint programHandle;
    
    NSMutableDictionary *attributeHandles;
    NSMutableDictionary *uniformHandles;
}

@property (nonatomic,readonly) GLuint programHandle;

- (id) initWithShaderSettings:(NSDictionary*)settings;

- (void) useShader;

- (BOOL) hasUniform:(NSString*)name;
- (BOOL) hasAttribute:(NSString*)name;

- (int) uniformLocation:(NSString*)name;
- (GLuint) attributeHandle:(NSString*)name;

@end
