//
//  SpriteManager.h
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
#import "SynthesizeSingleton.h"
#import "Bundle.h"
#import "CCTexture2D.h"

NSString* getDropboxPath();
void createDropboxPath();

@interface SpritePack : Bundle
{
    BOOL userPack;
}

- (NSUInteger) spriteCount;
- (UIImage*) spriteImageAtIndex:(NSUInteger)index;
- (NSString*) spriteNameAtIndex:(NSUInteger)index;
- (NSString*) spritePathAtIndex:(NSUInteger)index;
- (BOOL) deleteSpriteAtIndex:(NSUInteger)index;
- (BOOL) deleteSpritesAtIndices:(NSIndexSet*)set;

@property (nonatomic, assign) BOOL userPack;

@end

@interface SpriteManager : NSObject
{
    NSArray *includedPacksCache;
    NSMutableArray *userPacksCache;    
    
    NSMutableDictionary *allPacks;
}

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(SpriteManager);

@property (nonatomic, readonly) NSArray *includedSpritePacks;
@property (nonatomic, readonly) NSArray *userSpritePacks;
@property (nonatomic, readonly) NSArray *availableSpritePacks;

- (NSString*) documentsFolder;

- (void) createLookupCache;

- (CCTexture2D*) spriteTextureFromString:(NSString*)spriteString;

- (UIImage*) spriteImageFromString:(NSString*)spriteString;
- (UIImage*) spriteImageFromStringUncached:(NSString*)spriteString;

- (NSString*) spriteFileFromString:(NSString*)spriteString;
- (NSString*) relativeSpriteFileFromString:(NSString*)spriteString;
- (NSString*) spriteFileFromString:(NSString*)spriteString relative:(BOOL*)relative;

@end
