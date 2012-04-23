//
//  ShaderManager.m
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

#import "ShaderManager.h"

@implementation ShaderManager

static ShaderManager *sharedShaderManager;

#pragma mark - Singleton

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedShaderManager = [[ShaderManager alloc] init];
    }
}

+ (id)allocWithZone:(NSZone *)zone 
{ 
	@synchronized(self) 
	{ 
		if (sharedShaderManager == nil) 
		{ 
			sharedShaderManager = [super allocWithZone:zone]; 
			return sharedShaderManager; 
		} 
	} 
  
	return nil; 
} 

- (id)copyWithZone:(NSZone *)zone 
{ 
	return self; 
} 

+ (ShaderManager*) sharedManager
{
    return sharedShaderManager;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (oneway void)release
{
}

- (id)retain
{
    return sharedShaderManager;
}

- (id)autorelease
{
    return sharedShaderManager;
}

#pragma mark - Initialization

- (id) init
{
    self = [super init];
    if(self)
    {
        shaderPrograms = [[NSMutableDictionary dictionary] retain];
        activeProgram = 0;
    }
    return self;
}

#pragma mark - Memory

- (void) dealloc
{
    [shaderPrograms release];
    [super dealloc];
}

#pragma mark - Shader management

- (NSArray*) allShaders
{
    return [shaderPrograms allValues];
}

- (Shader*) currentShader
{
    return currentShader;
}

- (Shader*) useShader:(NSString*)name
{
    currentShader = [self shaderForName:name];
    
    if( activeProgram != currentShader.programHandle )
    {
        glUseProgram(currentShader.programHandle);
    
        activeProgram = currentShader.programHandle;    
    }
    
    return currentShader;
}

- (void) useShaderObject:(Shader*)shader
{
    currentShader = shader;
    
    if( activeProgram != currentShader.programHandle )
    {
        glUseProgram(currentShader.programHandle);
        
        activeProgram = currentShader.programHandle;
    }    
}

- (Shader*) shaderForName:(NSString *)name
{
    return [shaderPrograms objectForKey:name];
}

- (Shader*) createShader:(NSString*)name withSettings:(NSDictionary *)settings
{
    Shader *shader = [[[Shader alloc] initWithShaderSettings:settings] autorelease];
    
    Shader *existingShader = [self shaderForName:name];
    if( existingShader != nil )
    {
        [self removeShader:name];
    }
    
    [shaderPrograms setObject:shader forKey:name];
    
    return shader;
}

- (Shader*) createShader:(NSString*)name withFile:(NSString*)file
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:@""]];
    
    return [self createShader:name withSettings:dict];
}

- (void) reset
{
    glUseProgram(0);
    activeProgram = 0;
}

- (void) removeAllShaders
{
    [shaderPrograms removeAllObjects];
    [self reset];
}

- (void) removeShader:(NSString*)name
{
    Shader *shader = [self shaderForName:name];
    
    if( shader )
    {
        if( shader.programHandle == activeProgram )
        {
            [self reset];
        }
        
        [shaderPrograms removeObjectForKey:name];
    }
}

@end
