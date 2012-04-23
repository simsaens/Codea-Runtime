//
//  Project.m
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

#import "Project.h"
#import "EditorBuffer.h"

@implementation Project

@synthesize bufferNames, buffers, userProject;

- (id) initWithPath:(NSString*)path validFileTypes:(NSArray*)validExt
{
    self = [super initWithPath:path validFileTypes:validExt];
    if (self) 
    {
        userProject = NO;
    }
    return self;
}

- (NSMutableDictionary*) defaultInfoDictionary
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:@"No description available", @"Description", 
            @"Unknown", @"Author", 
            [[NSDate date] description], @"Created", 
            nil];
}

- (BOOL) containsBufferNamed:(NSString*)checkName
{
    for( NSString *bufferName in bufferNames )
    {
        if( [[bufferName lowercaseString] isEqualToString:[checkName lowercaseString]] )
        {
            return YES;
        }
    }    
    
    return NO;
}

#pragma mark - Saving

- (BOOL) writeToBundlePath:(NSString*)theBundlePath
{
    if( !self.isLoaded )
    {
        DBLog(@"ERROR Project not loaded, can not write project to path: %@", theBundlePath);
        return NO;
    }
    
#ifndef CODEA_BETA    
    NSArray *bundleContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:theBundlePath error:NULL];
    
    //Delete any files that are not named in the project
    for( NSString *file in bundleContents )
    {
        if ([[file pathExtension] isEqualToString:@"plist"]) 
        {
            continue;
        }
        
        NSString *unadornedName = [file stringByDeletingPathExtension];
        
        if( ![self containsBufferNamed:unadornedName] )
        {
            [[NSFileManager defaultManager] removeItemAtPath:[theBundlePath stringByAppendingPathComponent:file] error:NULL];
        }
    }
#endif
    
    NSAssert([buffers count] == [bufferNames count], @"Buffer count and name count do not match");
    
    //Save all files in this project
    NSMutableArray *bufferOrder = [NSMutableArray array];    
    BOOL hasErrors = NO;
    for( int i = 0; i < [buffers count]; i++ )
    {
        EditorBuffer *buffer = [buffers objectAtIndex:i];                    
        
        NSString *bufferName = [bufferNames objectAtIndex:i];        
        NSString *bufferText = buffer.text;
        
        [bufferOrder addObject:bufferName];
        
        NSString *filePath = [theBundlePath stringByAppendingPathComponent:[bufferName stringByAppendingPathExtension:@"lua"]];
        
        NSError *error = nil;
        if( ![bufferText writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error] )
        {
            DBLog(@"ERROR %@ Failed to write buffer %@ to file: %@", [error description], bufferName, filePath);
            hasErrors = YES;
        }
    }
    
    [info setObject:bufferOrder forKey:@"Buffer Order"];
    
    //Save info plist
    if( ![info writeToFile:[theBundlePath stringByAppendingPathComponent:@"Info.plist"] atomically:YES] )
    {
        hasErrors = YES;
    }
    
    return !hasErrors;
}

#pragma mark - Memory

- (void) dealloc
{
    [buffers release];
    [bufferNames release];
    
    [super dealloc];
}

#pragma mark - Filter for code only files

- (NSArray*) codeFiles
{
    NSMutableArray *filtered = [NSMutableArray array];
    
    for( NSString *path in files )
    {
        if( [[[path pathExtension] lowercaseString] isEqualToString:@"lua"] )
        {
            [filtered addObject:path];
        }
    }
    
    return filtered;
}

#pragma mark - Loading / unloading

- (BOOL) isLoaded
{
    return (buffers != nil);
}

- (void) load
{
    if( self.isLoaded )
    {
        [self unload];
    }
    
    NSMutableArray *unsortedBuffers = [NSMutableArray arrayWithCapacity:[files count]];
    NSMutableArray *unsortedBufferNames = [NSMutableArray arrayWithCapacity:[files count]];    
    
    for( NSString *filePath in self.codeFiles )
    {
        DBLog(@"Loading file %@", filePath);        
        
        NSString *contents = [NSString stringWithContentsOfFile:filePath usedEncoding:NULL error:NULL];
        
        EditorBuffer *buffer = [[EditorBuffer alloc] initWithText:contents];
        
        [unsortedBuffers addObject:buffer];
        [unsortedBufferNames addObject:[[filePath lastPathComponent] stringByDeletingPathExtension]];
        
        DBLog(@"Buffer = \n%@", buffer.text);
        
        [buffer release];
    }
    
    NSArray *bufferOrder = [info objectForKey:@"Buffer Order"];    
    if( bufferOrder != nil )
    {
        buffers = [[NSMutableArray arrayWithCapacity:[files count]] retain];
        bufferNames = [[NSMutableArray arrayWithCapacity:[files count]] retain];        
        
        //Sort buffers by Buffer Order
        for( NSString *bufferName in bufferOrder )
        {
            NSUInteger index = [unsortedBufferNames indexOfObject:bufferName];                        
            
            [buffers addObject:[unsortedBuffers objectAtIndex:index]];
            [bufferNames addObject:[unsortedBufferNames objectAtIndex:index]];            
        }
    }
    else
    {
        buffers = [unsortedBuffers retain];
        bufferNames = [unsortedBufferNames retain];
    }
}

- (void) unload
{    
    [buffers release];
    buffers = nil;
    
    [bufferNames release];
    bufferNames = nil;
}

@end

