//
//  Bundle.m
//  Codea
//
//  Created by Simeon Nasilowski on 2/10/11.
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

@implementation Bundle

@synthesize name, info, files, bundlePath;

+ (id) bundleWithPath:(NSString*)path validFileTypes:(NSArray*)validExt
{
    return [[[self alloc] initWithPath:path validFileTypes:validExt] autorelease];
}

- (void) reloadFilesFromBundlePath
{
    NSArray *bundleContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath error:NULL];        
       
    [name release];
    name = [[[bundlePath lastPathComponent] stringByDeletingPathExtension] retain];
    [files release];
    files = [[NSMutableArray arrayWithCapacity:[bundleContents count]] retain];
    
    if (info == nil)
    {
        self.info = [self defaultInfoDictionary];    
    }    
    
    for( NSString *file in bundleContents )
    {
        if( [validFileTypes containsObject:[file pathExtension]] && [self isFileValid:file] )
        {
            NSString *filePath = [bundlePath stringByAppendingPathComponent:file];
            [files addObject:filePath];
        }
        
        if( [file isEqualToString:@"Info.plist"] )
        {
            self.info = [NSMutableDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:file]];
        }
    }
}

- (BOOL) isFileValid:(NSString*)path
{
    return YES;
}

- (id) initWithPath:(NSString*)path validFileTypes:(NSArray*)validExt
{
    self = [super init];
    if (self) 
    {
        bundlePath = [path retain];        
        validFileTypes = [validExt copy];
        
        [self reloadFilesFromBundlePath];
    }
    
    return self;
}

- (id) initWithData:(NSData*)data validFileTypes:(NSArray*)validExt
{
    self = [super init];
    if( self )
    {
        validFileTypes = [validExt copy];
        
        //[self reloadFilesFromBundlePath];
    }
    
    return self;
}

- (NSData*) serializedRepresentation
{
    DBLog(@"Creating file wrapper with location: %@", [NSURL fileURLWithPath:bundlePath isDirectory:YES]);
    
    NSError *error = nil;
    NSFileWrapper *wrapper = [[[NSFileWrapper alloc] initWithURL:[NSURL fileURLWithPath:bundlePath isDirectory:YES] options:NSFileWrapperReadingImmediate|NSFileWrapperReadingWithoutMapping error:&error] autorelease];        
    
    if( error )
    {
        NSLog(@"Error creating file wrapper for project: %@", error);
    }
    
    return [wrapper serializedRepresentation];
}

- (void) dealloc
{
    [validFileTypes release];
    [bundlePath release];
    [name release];
    [info release];
    [files release];
    
    [super dealloc];
}

- (NSString*) fileNameAtIndex:(NSUInteger)index
{
    NSString *fileName = [self.files objectAtIndex:index];
    fileName = [fileName stringByReplacingOccurrencesOfString:bundlePath withString:@""];
    
    return [fileName lastPathComponent];
}

- (NSMutableDictionary*) defaultInfoDictionary
{
    return [NSMutableDictionary dictionary];
}

@end
