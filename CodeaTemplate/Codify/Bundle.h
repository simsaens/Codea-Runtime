//
//  Bundle.h
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

#import <Foundation/Foundation.h>

@interface Bundle : NSObject
{
    NSString            *bundlePath;
    NSArray             *validFileTypes;
    NSMutableArray      *files;    
    NSString            *name;
    NSMutableDictionary *info;    
}

@property (nonatomic, readonly) NSString            *bundlePath;
@property (nonatomic, readonly) NSArray             *files;
@property (nonatomic, readonly) NSMutableDictionary *info;
@property (nonatomic, readonly) NSString            *name;

+ (id) bundleWithPath:(NSString*)path validFileTypes:(NSArray*)validExt;
- (id) initWithPath:(NSString*)path validFileTypes:(NSArray*)validExt;
- (id) initWithData:(NSData*)data validFileTypes:(NSArray*)validExt;

- (NSString*) fileNameAtIndex:(NSUInteger)index;

- (void) reloadFilesFromBundlePath;
- (NSMutableDictionary*) defaultInfoDictionary;

- (NSData*) serializedRepresentation;

- (BOOL) isFileValid:(NSString*)path;

@end
