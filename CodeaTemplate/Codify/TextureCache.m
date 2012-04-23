//
//  TextureCache.m
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

#import "TextureCache.h"

@implementation TextureCache

SYNTHESIZE_SINGLETON_FOR_CLASS(TextureCache);

- (id)init
{
    self = [super init];
    if (self) 
    {
        loadedTextures = [[NSMutableDictionary dictionary] retain];
    }
    
    return self;
}

- (void) dealloc
{
    [loadedTextures release];
    
    [super dealloc];
}

- (CCTexture2D*) textureForSprite:(NSString*)relSpritePath
{
    CCTexture2D *texture = [loadedTextures objectForKey:relSpritePath];
    
    if( texture == nil )
    {
        //load it
        //using image named to trigger caching
        UIImage *image = [UIImage imageNamed:relSpritePath];
        
        if (image == nil)
        {
            image = [UIImage imageWithContentsOfFile:relSpritePath];
        }
        
        texture = [[[CCTexture2D alloc] initWithImage:image] autorelease];
        
        //store it
        [loadedTextures setObject:texture forKey:relSpritePath];        
    }
    
    return texture;
}

- (void) flushUnusedTextures
{
    for( NSString *key in [loadedTextures allKeys] )
    {
        CCTexture2D *tex = [loadedTextures objectForKey:key];
        
        if( [tex retainCount] == 1 )
        {
            [loadedTextures removeObjectForKey:key];
        }
    }
}

- (void) flushTextures
{
    [loadedTextures removeAllObjects];
}

@end
