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

- (NSString*) retinaSpritePathAtIndex:(NSUInteger)index
{
    NSString *filePath = [self.files objectAtIndex:index];
    
    NSString *base = [filePath stringByDeletingPathExtension];
    NSString *ext = [filePath pathExtension];
        
    return [[base stringByAppendingString:@"@2x"] stringByAppendingPathExtension:ext];
}

- (NSString*) spritePathAtIndex:(NSUInteger)index
{
    NSString *filePath = [self.files objectAtIndex:index];
    
    return filePath;
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

- (BOOL) deleteSpriteAtIndex:(NSUInteger)index andReload:(BOOL)reload
{
    NSString *path = [self spritePathAtIndex:index];
    NSString *retinaPath = [self retinaSpritePathAtIndex:index];
    
    BOOL noErr = YES;
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:path] ) 
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        
        if( error )
        {
            DBLog(@"EditableSpriteGridController: Error deleting sprite(s) ");
            noErr = NO;
        }
    }    
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:retinaPath] ) 
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:retinaPath error:&error];
        
        if( error )
        {
            DBLog(@"EditableSpriteGridController: Error deleting sprite(s) ");
            noErr = NO;            
        }
    }        
    
    if( reload )
        [self reloadFilesFromBundlePath];
    
    return noErr;
}

- (BOOL) deleteSpriteAtIndex:(NSUInteger)index
{
    return [self deleteSpriteAtIndex:index andReload:YES];
}

- (BOOL) deleteSpritesAtIndices:(NSIndexSet*)set
{
    BOOL noErr = YES;
    
    NSUInteger idx = [set firstIndex];
    while( idx != NSNotFound ) 
    {
        if( ![self deleteSpriteAtIndex:idx andReload:NO] )
        {
            noErr = NO;
        }
        
        idx = [set indexGreaterThanIndex:idx];
    }

    [self reloadFilesFromBundlePath];    
    
    return noErr;
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
                DBLog(@"Invalid Sprite specified: %@", filePath);                 
                spritePath = nil;
            }
        }
        else
        {
            DBLog(@"Invalid SpritePack specified: %@", [components objectAtIndex:0]);
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
                DBLog(@"Invalid Sprite specified: %@", filePath);                
                spritePath = nil;
            }
        }
        else
        {
            DBLog(@"Invalid SpritePack specified: %@", [components objectAtIndex:0]);
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
            NSString *filePath = [[components objectAtIndex:1] stringByAppendingPathExtension:@"png"];           
            spritePath = [pack.bundlePath stringByAppendingPathComponent:filePath];                
            
            if (pack.userPack)
            {
                *relative = NO;
                spritePath = [pack.bundlePath stringByAppendingPathComponent:filePath];
            }
            else 
            {
                *relative = YES;
                spritePath = [[[components objectAtIndex:0] stringByAppendingPathExtension:@"spritepack"] stringByAppendingPathComponent:filePath];
            }
                        
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

- (NSString*) documentsFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];        
}

- (SpritePack*) spritePackFromPath:(NSString*)path
{
    return [SpritePack bundleWithPath:path validFileTypes:[NSArray arrayWithObjects:@"png", @"jpg", nil]];
}

- (NSMutableArray*) loadSpritePacksInPath:(NSString*)path
{        
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray *packs = [NSMutableArray arrayWithCapacity:[contents count]];
    
    for( NSString *folder in contents )
    {
        //DBLog(@"Processing %@ in path: %@", folder, path);
        
        if( [[folder pathExtension] isEqualToString:@"spritepack"] )
        {        
            NSString *packPath = [path stringByAppendingPathComponent:folder];
            
            SpritePack *pack = [self spritePackFromPath:packPath];
            
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

void createDropboxPath()
{
    // Attempt to create dropbox directory if it doesn't exist
    if( ![[NSFileManager defaultManager] fileExistsAtPath:getDropboxPath()] )
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:getDropboxPath() withIntermediateDirectories:YES attributes:nil error:NULL];                                        
    }
}

NSString* getDropboxPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return [documentsDirectoryPath stringByAppendingPathComponent:@"Dropbox.spritepack"];    
}

- (NSArray*) userSpritePacks
{
    if( userPacksCache == nil )
    {
        createDropboxPath();
                
        //Load any .spritepack folders sitting in Documents
        userPacksCache = [[self loadSpritePacksInPath:[self documentsFolder]] retain];                                
        
        //Load Documents/* itself, as a sprite pack
        SpritePack* documents = [self spritePackFromPath:[self documentsFolder]];
        documents.userPack = YES;
        documents.info = [NSDictionary dictionaryWithObjectsAndKeys:@"Documents", @"Name", @"You", @"Author", @"SpritePackDocuments.png", @"Icon", nil];
        
        //Place documents spritepack at the start of the list
        [userPacksCache insertObject:documents atIndex:0];   
        
        //Configure the Dropbox sprite pack
        for (SpritePack* pack in userPacksCache)
        {
            if ([pack.name isEqualToString:@"Dropbox"])
            {
                SpritePack *dropboxPack = pack;
                dropboxPack.userPack = YES;
                dropboxPack.info = [NSDictionary dictionaryWithObjectsAndKeys:@"Dropbox", @"Name", @"You", @"Author", @"SpritePackDropbox.png", @"Icon", nil];                
            }
        }        
    }
    
    return userPacksCache;    
}

- (NSArray*) availableSpritePacks
{
    //Return both the user sprite packs and the included ones
    return [self.userSpritePacks arrayByAddingObjectsFromArray:self.includedSpritePacks];
}

@end
