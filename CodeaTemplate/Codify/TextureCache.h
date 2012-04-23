//
//  TextureCache.h
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
#import "CCTexture2D.h"

@interface TextureCache : NSObject
{
    NSMutableDictionary *loadedTextures;
}

- (CCTexture2D*) textureForSprite:(NSString*)relSpritePath;
- (void) flushUnusedTextures;
- (void) flushTextures;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(TextureCache);
@end
