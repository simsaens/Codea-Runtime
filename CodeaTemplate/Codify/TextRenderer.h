//
//  TextRenderer.h
//  Codea
//
//  Created by Simeon Nasilowski on 3/01/12.
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
#import <UIKit/UIKit.h>

#import "RenderManager.h"

@class CCTexture2D;

@interface TextRenderer : NSObject
{
    NSMutableDictionary *stringCache;        
}

- (CCTexture2D*) textureForString:(NSString*)string withFont:(NSString*)font size:(CGFloat)size wrapWidth:(CGFloat)wrapWidth alignment:(GraphicsStyle::TextAlign)align currentFrame:(NSUInteger)frame;

- (CGSize) sizeForString:(NSString*)string withFont:(NSString*)font size:(CGFloat)size wrapWidth:(CGFloat)wrapWidth;

- (void) flushCacheForFrame:(NSUInteger)frame;
- (void) flushCache;

@end
