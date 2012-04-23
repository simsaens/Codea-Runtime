//
//  Shader.m
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

#import "Shader.h"
#import "ShaderManager.h"

@implementation Shader

@synthesize programHandle;

#pragma mark - Shader compiling and linking

- (BOOL)compileShader:(GLuint *)shader file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    GLenum type = GL_VERTEX_SHADER;
    
    NSString *extension = [file pathExtension];
    if( [extension isEqualToString:@"vsh"] )
    {
        type = GL_VERTEX_SHADER;
    }
    else if( [extension isEqualToString:@"fsh"] )
    {
        type = GL_FRAGMENT_SHADER;
    }
    else 
    {
        NSLog(@"Unknown shader file extension");
        return FALSE;
    }
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;    
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

#pragma mark - Initialization

- (id) initWithShaderSettings:(NSDictionary*)settings
{    
    self = [super init];
    if( self )
    {
        NSArray *shaderFiles = [settings objectForKey:@"Files"];
        NSArray *attributes = [settings objectForKey:@"Attributes"];
        NSArray *uniforms = [settings objectForKey:@"Uniforms"];
        
        attributeHandles = [[NSMutableDictionary dictionary] retain];
        uniformHandles = [[NSMutableDictionary dictionary] retain];
        
        programHandle = glCreateProgram();
                         
        NSMutableArray *shaderList = [NSMutableArray array];
        
        for( NSString *file in shaderFiles )
        {
            GLuint shader;
            
            NSString* extension = [file pathExtension];
            
            if( ![self compileShader:&shader file:[[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] ofType:extension]] )
            {
                NSLog(@"Failed to compile shader: %@", file);
            }
            
            [shaderList addObject:[NSNumber numberWithInt:shader]];
        }
        
        for( NSNumber *shader in shaderList )
        {
            //Attach each shader to the program
            glAttachShader( programHandle, [shader unsignedIntValue] );
        }        
        
        GLuint attribLoc = 1;
        for( NSString *attribute in attributes )
        {
            glBindAttribLocation(programHandle, attribLoc, [attribute UTF8String]);            
            
            [attributeHandles setObject:[NSNumber numberWithInt:attribLoc] forKey:attribute];
            
            attribLoc += 1;
        }
        
        if( ![self linkProgram:programHandle] )
        {
            NSLog(@"Failed to link program: %d", programHandle);
            
            for( NSNumber *shader in shaderList )
            {
                if( [shader unsignedIntValue] )
                {
                    glDeleteShader([shader unsignedIntValue]);
                }
            }

            if (programHandle)
            {
                glDeleteProgram(programHandle);
                programHandle = 0;
            }            
        }    
        
        if( programHandle )
        {
            for( NSString *uniform in uniforms )
            {
                int uniformHandle = glGetUniformLocation(programHandle, [uniform UTF8String]);
                
                [uniformHandles setObject:[NSNumber numberWithInt:uniformHandle] forKey:uniform];
            }
        }
    }
    return self;
}

- (void) dealloc
{
    if( programHandle )
    {
        glDeleteProgram(programHandle);
        programHandle = 0;
    }
    
    [attributeHandles release];
    [uniformHandles release];
    
    [super dealloc];
}

#pragma mark - Using the shader

- (void) useShader
{
    [[ShaderManager sharedManager] useShaderObject:self];
}

#pragma mark - Checking

- (BOOL) hasUniform:(NSString*)name
{
    NSNumber *uniformLoc = [uniformHandles objectForKey:name];
    
    return uniformLoc != nil;
}

- (BOOL) hasAttribute:(NSString*)name
{
    NSNumber *attributeLoc = [attributeHandles objectForKey:name];
    
    return attributeLoc != nil;
}

#pragma mark - Access to uniforms and attributes

- (int) uniformLocation:(NSString*)name
{
    NSNumber *uniformLoc = [uniformHandles objectForKey:name];
    
    if( uniformLoc != nil )
    {
        return [[uniformHandles objectForKey:name] intValue];
    }
    
    return -1;
}

- (GLuint) attributeHandle:(NSString*)name
{
    NSNumber *attributeLoc = [attributeHandles objectForKey:name];
    
    if( attributeLoc != nil )
    {
        return [[attributeHandles objectForKey:name] unsignedIntValue];    
    }
    
    return 0;
}

@end
