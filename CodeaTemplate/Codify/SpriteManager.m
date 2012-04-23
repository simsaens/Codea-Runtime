//
//  SpriteManager.m
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

#import "SpriteManager.h"
#import "TextureCache.h"
#import "Persistence.h"

@implementation SpritePack

@synthesize userPack;

- (id) initWithPath:(NSString*)path validFileTypes:(NSArray*)validExt
{
    self = [super initWithPath:path validFileTypes:validExt];
    if( self )
    {
        userPack = NO;        
    }
    
    return self;
}

- (BOOL) isFileValid:(NSString*)path
{
    //Ensure @2x files are not noticed by sprite packs
    // They will still be loaded by UIImage
    NSString *fileName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    if( [fileName hasSuffix:@"@2x"] )
        return NO;
    
    return YES;
}

- (NSUInteger) spriteCount
{
    return [self.files count];
}

- (UIImage*) spriteImageAtIndex:(NSUInteger)index
{
    NSString *filePath = [self.files objectAtIndex:index];
    
    if( userPack == NO )
    {
        //Remove resource path prefix from file            
        filePath = [filePath stringByReplacingOccurrencesOfString:[NSBundle mainBundle].resourcePath withString:@""];
        return [UIImage imageNamed:filePath];            
    }
    else
    {
        //Remove documents path prefix from file
        //TODO: This is an uncached UIImage, probably slow
        return [UIImage imageWithContentsOfFile:filePath];
    }
}

- (NSString*) spriteNameAtIndex:(NSUInteger)index
{
    NSString *spriteName = [self fileNameAtIndex:index];
    
    return [spriteName stringByDeletingPathExtension];
}

@end

@implementation SpriteManager

SYNTHESIZE_SINGLETON_FOR_CLASS(SpriteManager);

- (id)init
{
    self = [super init];
    if (self) 
    {
        allPacks = [[NSMutableDictionary dictionary] retain];
    }
    
    return self;
}

- (void) dealloc
{
    [allPacks release];
    [userPacksCache release];
    [includedPacksCache release];
    [super dealloc];
}

- (void) createLookupCache
{
    [allPacks removeAllObjects];
    
    NSArray *availPacks = self.availableSpritePacks;
    
    for( SpritePack *pack in availPacks )
    {
        [allPacks setObject:pack forKey:pack.name];
    }
}

- (CCTexture2D*) spriteTextureFromString:(NSString*)spriteString
{
//    NSString *relFile = [self relativeSpriteFileFromString:spriteString];
//    
//    if( relFile )
//    {
//        return [[TextureCache sharedInstance] textureForSprite:[@"SpritePacks" stringByAppendingPathComponent:relFile]];
//    }

    BOOL relative = NO;
    NSString* file = [self spriteFileFromString:spriteString relative:&relative];
    
    if (file)
    {
        if (relative)
        {
            return [[TextureCache sharedInstance] textureForSprite:[@"SpritePacks" stringByAppendingPathComponent:file]];            
        }
        else
        {
            return [[TextureCache sharedInstance] textureForSprite:file];            
        }
    }
    
    return nil;
}

- (UIImage*) spriteImageFromString:(NSString*)spriteString
{
    NSString *relFile = [self relativeSpriteFileFromString:spriteString];
    
    if( relFile )
    {
        return [UIImage imageNamed:[@"SpritePacks" stringByAppendingPathComponent:relFile]];
    }
    
    return nil;
}

- (UIImage*) spriteImageFromStringUncached:(NSString*)spriteString
{
    NSString *absFile = [self spriteFileFromString:spriteString];
    
    if( absFile )
    {
        return [UIImage imageWithContentsOfFile:absFile];
    }
    
    return nil;
}

- (NSString*) relativeSpriteFileFromString:(NSString*)spriteString
{
    if( [allPacks count] == 0 )
    {
        [self createLookupCache];
    }
    
    NSArray *components = [spriteString componentsSeparatedByString:@":"];
    NSString *spritePath = nil;
    
    if( [components count] == 2 )
    {
        NSString *packPath = [[components objectAtIndex:0] stringByAppendingPathExtension:@"spritepack"];
        NSString *filePath = [[components objectAtIndex:1] stringByAppendingPathExtension:@"png"];           
        
        SpritePack *pack = [allPacks objectForKey:[components objectAtIndex:0]];
        if( pack )
        {                     
            spritePath = [packPath stringByAppendingPathComponent:filePath];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath:[pack.bundlePath stringByAppendingPathComponent:filePath]] == NO )
            {
                DBLog(@"Invalid Sprite specified");                 
                spritePath = nil;
            }
        }
        else
        {
            DBLog(@"Invalid SpritePack specified");
        }        
    }
    else
    {
        DBLog(@"Sprite string has incorrect number of components");
    }
    
    return spritePath;
}

- (NSString*) spriteFileFromString:(NSString*)spriteString
{
    if( [allPacks count] == 0 )
    {
        [self createLookupCache];
    }    
    
    NSArray *components = [spriteString componentsSeparatedByString:@":"];
    NSString *spritePath = nil;
    
    if( [components count] == 2 )
    {
        SpritePack *pack = [allPacks objectForKey:[components objectAtIndex:0]];
        
        if( pack )
        {            
            NSString *filePath = [[components objectAtIndex:1] stringByAppendingPathExtension:@"png"];            
            spritePath = [pack.bundlePath stringByAppendingPathComponent:filePath];            
            
            if( [[NSFileManager defaultManager] fileExistsAtPath:spritePath] == NO )
            {
                DBLog(@"Invalid Sprite specified");                
                spritePath = nil;
            }
        }
        else
        {
            DBLog(@"Invalid SpritePack specified");
        }

    }
    else
    {
        DBLog(@"Sprite string has incorrect number of components");
    }
    
    return spritePath;
}

- (NSString*) spriteFileFromString:(NSString*)spriteString relative:(BOOL*)relative
{
    if( [allPacks count] == 0 )
    {
        [self createLookupCache];
    }    
    
    NSArray *components = [spriteString componentsSeparatedByString:@":"];
    NSString *spritePath = nil;
    
    if( [components count] == 2 )
    {
        SpritePack *pack = [allPacks objectForKey:[components objectAtIndex:0]];
        
        if( pack )
        {   
            if (pack.userPack)
            {
                NSString *filePath = [[components objectAtIndex:1] stringByAppendingPathExtension:@"png"];            
                spritePath = [pack.bundlePath stringByAppendingPathComponent:filePath];           
                *relative = YES;
                
                if( [[NSFileManager defaultManager] fileExistsAtPath:[pack.bundlePath stringByAppendingPathComponent:filePath]] == NO )
                {
                    DBLog(@"Invalid Sprite specified");                
                    spritePath = nil;
                }
            }
            else
            {
                //NSString *packPath = [[components objectAtIndex:0] stringByAppendingPathExtension:@"spritepack"];
                NSString *filePath = [[components objectAtIndex:1] stringByAppendingPathExtension:@"png"];           
                spritePath = [pack.bundlePath stringByAppendingPathComponent:filePath];                
                *relative = NO;
                
                if( [[NSFileManager defaultManager] fileExistsAtPath:spritePath] == NO )
                {
                    DBLog(@"Invalid Sprite specified");                
                    spritePath = nil;
                }                
            }                        
        }
        else
        {
            DBLog(@"Invalid SpritePack specified");
        }        
    }
    else
    {
        DBLog(@"Sprite string has incorrect number of components");
    }
    
    return spritePath;
}

- (NSString*) documentsFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];        
}

- (NSArray*) loadSpritePacksInPath:(NSString*)path
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray *packs = [NSMutableArray arrayWithCapacity:[contents count]];
    
    for( NSString *folder in contents )
    {
        //DBLog(@"Processing %@ in path: %@", folder, path);
        
        if( [[folder pathExtension] isEqualToString:@"spritepack"] )
        {        
            NSString *packPath = [path stringByAppendingPathComponent:folder];
            
            SpritePack *pack = [SpritePack bundleWithPath:packPath validFileTypes:[NSArray arrayWithObject:@"png"]];
            
            [packs addObject:pack];
        }
    }
    
    return packs;
}

- (NSArray*) includedSpritePacks
{
    if( includedPacksCache == nil )
    {
        includedPacksCache = [[self loadSpritePacksInPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"SpritePacks"]] retain];
    }
    
    return includedPacksCache;
}

- (NSArray*) userSpritePacks
{
    if( userPacksCache == nil )
    {
        userPacksCache = [[self loadSpritePacksInPath:[self documentsFolder]] retain];                        
        
        //TEMPORARY DISABLE
        /*
        SpritePack *globalPack = [SpritePack bundleWithPath:getDocumentsImagesPath() validFileTypes:[NSArray arrayWithObject:@"png"]];        
        globalPack.userPack = YES;
        [(NSMutableArray*)userPacksCache addObject:globalPack];        
        */
    }
    
    return userPacksCache;    
}

- (NSArray*) availableSpritePacks
{
    //TODO: Return both user and included sprite packs
    return self.includedSpritePacks; //[self.includedSpritePacks arrayByAddingObjectsFromArray:self.userSpritePacks];
}

@end
