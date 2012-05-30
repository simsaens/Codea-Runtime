//
//  CodeaScriptExecute.m
//  Codea
//
//  Created by Simeon Nasilowski on 9/20/11.
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

#import "CodifyScriptExecute.h"
#import "Project.h"
#import "SharedRenderer.h"
#import "EditorBuffer.h"
#import "LuaState.h"

@implementation CodifyScriptExecute
@synthesize errorDelegate;
SYNTHESIZE_SINGLETON_FOR_CLASS(CodifyScriptExecute);

#define SCRIPT_STRING(name) [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@name ofType:@"lua"] usedEncoding:NULL error:NULL]

- (id) init
{
    self = [super init];
    if( self )
    {
        preloadScripts = [[NSMutableArray array] retain];
        
        /*
        //Lua Socket        
        [preloadScripts addObject:[SCRIPT_STRING("socket") retain]];
        [preloadScripts addObject:[SCRIPT_STRING("ltn12") retain]];             
        [preloadScripts addObject:[SCRIPT_STRING("mime") retain]]; 
        [preloadScripts addObject:[SCRIPT_STRING("url") retain]];         
        [preloadScripts addObject:[SCRIPT_STRING("tp") retain]];    
        [preloadScripts addObject:[SCRIPT_STRING("http") retain]];                
        [preloadScripts addObject:[SCRIPT_STRING("ftp") retain]];    
        [preloadScripts addObject:[SCRIPT_STRING("smtp") retain]];            
        */
        
        //Pre-load classes and sandbox lua files
        [preloadScripts addObject:SCRIPT_STRING("LuaSandbox")];             
        [preloadScripts addObject:SCRIPT_STRING("Class")];             
        //luaSandbox = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LuaSandbox" ofType:@"lua"] usedEncoding:NULL error:NULL] retain];
        //luaClasses = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Class" ofType:@"lua"] usedEncoding:NULL error:NULL] retain];        
        
        //Pre-load any other interesting libraries
    }
    return self;
}

- (void) dealloc
{
    [preloadScripts release];
    
    [super dealloc];
}

- (BOOL) loadAdditionalCode
{
    LuaState *scriptState = [LuaState sharedInstance];
    BOOL containsErrors = NO;
    
    for( NSString *script in preloadScripts )
    {
        LuaError internalError;
        internalError = [scriptState loadString:script];
        if( internalError.lineNumber != NSNotFound )
        {
            DBLog(@"SANDBOX ERROR - %d: %@ (REFERRING TO LINE: %d)",internalError.lineNumber,internalError.errorMessage,internalError.referringLine);              
            
            containsErrors = YES;
        }        
    }
    
    return !containsErrors;
}

- (BOOL) validateProject:(Project*)project
{
    //Get the script state
    LuaState *scriptState = [LuaState sharedInstance];
    BasicRendererViewController *renderController = [SharedRenderer renderer];
    
    [scriptState close];
    [scriptState createWithFakeLibs];
    [renderController setupRenderGlobals];
    
    BOOL containsErrors = ![self loadAdditionalCode];    
    
    for( EditorBuffer *buffer in project.buffers )
    {
        //Check here because the open source EditorBuffer doesnt have this message
        if ([buffer respondsToSelector:@selector(clearErrorMessage)])
        {
            [buffer performSelector:@selector(clearErrorMessage)];
        }
        
        //Attempt to load this buffer into the Lua state
        LuaError error = [scriptState loadString:buffer.text];
        
        if( error.lineNumber != NSNotFound )
        {
            DBLog(@"%d: %@ (REFERRING TO LINE: %d)",error.lineNumber,error.errorMessage,error.referringLine);              
            
            [errorDelegate error:error inBuffer:buffer];
            
            containsErrors = YES;
        }
    }
    
    return !containsErrors;
}

- (BOOL) runProject:(Project*)project
{
    //Get the script state
    LuaState *scriptState = [LuaState sharedInstance];
    BasicRendererViewController *renderController = [SharedRenderer renderer];
    
    [scriptState close];
    [scriptState create];
    [renderController setupRenderGlobals];    
    [renderController setupPhysicsGlobals];
    [renderController setupAccelerometerValues];
    
    if( ![self loadAdditionalCode] )
    {
        return NO;
    }
    
    for( EditorBuffer *buffer in project.buffers )
    {
        LuaError error = [scriptState loadString:buffer.text];
        
        if( error.lineNumber != NSNotFound )
        {
            return NO;
        }
    }

    [scriptState disableInstructionLimit];
    //[scriptState callSimpleFunction:@"setup"];   
    
    return YES;
}

@end
