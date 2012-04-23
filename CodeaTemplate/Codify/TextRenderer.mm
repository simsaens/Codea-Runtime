//
//  TextRenderer.m
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

#import <QuartzCore/QuartzCore.h>

#import "TextRenderer.h"
#import "CCTexture2D.h"
#import "SharedRenderer.h"
#import "EAGLView.h"

#pragma mark - Text cache object with life time

@interface RenderedTextCache : NSObject 
{
@private
    CCTexture2D *texture;
    NSUInteger lastFrameUsed;
}
@property (nonatomic, retain) CCTexture2D *texture;
@property (nonatomic, assign) NSUInteger lastFrameUsed;
- (id) initWithTexture:(CCTexture2D*)t andLastFrame:(NSUInteger)f;
+ (id) renderedTextCacheWithTexture:(CCTexture2D*)t andLastFrame:(NSUInteger)f;
@end

@implementation RenderedTextCache

@synthesize texture, lastFrameUsed;

- (id) initWithTexture:(CCTexture2D*)t andLastFrame:(NSUInteger)f
{
    self = [super init];
    if( self )
    {
        self.texture = t;
        self.lastFrameUsed = f;
    }
    return self;
}

+ (id) renderedTextCacheWithTexture:(CCTexture2D*)t andLastFrame:(NSUInteger)f
{
    return [[[RenderedTextCache alloc] initWithTexture:t andLastFrame:f] autorelease];
}

- (void) dealloc
{
    [texture release];
    [super dealloc];
}

@end

#pragma mark - Text renderer helper class

@implementation TextRenderer

- (id) init
{
    self = [super init];
    if ( self )
    {
        stringCache = [[NSMutableDictionary dictionary] retain];
    }
    
    return self;
}

- (void) dealloc
{
    [stringCache release];
    
    [super dealloc];
}

- (CGSize) sizeForString:(NSString*)string withFont:(NSString*)font size:(CGFloat)size wrapWidth:(CGFloat)wrapWidth
{
    CGSize result;
    
    if( wrapWidth > 0 )
    {
        result = [string sizeWithFont:[UIFont fontWithName:font size:size] constrainedToSize:CGSizeMake(wrapWidth, 20000) lineBreakMode:UILineBreakModeWordWrap];
    }
    else
    {
        result = [string sizeWithFont:[UIFont fontWithName:font size:size]];        
    }
    
    return result;
}

- (CCTexture2D*) textureForString:(NSString*)string withFont:(NSString*)font size:(CGFloat)size wrapWidth:(CGFloat)wrapWidth alignment:(GraphicsStyle::TextAlign)align currentFrame:(NSUInteger)frame
{
    //Lookup string
    NSString *lookup = [NSString stringWithFormat:@"%@%@%.1f%.1f%d", string, font, size, wrapWidth, align];
    
    //DBLog(@"String cache lookup key \"%@\"",lookup);    
    RenderedTextCache *cache = [stringCache objectForKey:lookup];
    
    if( cache == nil )
    {        
        UILabel *label = [[UILabel alloc] init];
        
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        //label.minimumFontSize = size;
        label.font = [UIFont fontWithName:font size:size];        
        label.text = string;
        
        //DBLog(@"Creating font texture with font %@ and size %f", font, size);
        
        switch( align ) 
        {
            case GraphicsStyle::TEXT_ALIGN_CENTER:
                label.textAlignment = UITextAlignmentCenter;        
                break;
                
            case GraphicsStyle::TEXT_ALIGN_LEFT:
                label.textAlignment = UITextAlignmentLeft;
                break;
                
            case GraphicsStyle::TEXT_ALIGN_RIGHT:
                label.textAlignment = UITextAlignmentRight;
                break;
        }

        label.numberOfLines = 1;
        
        if( wrapWidth > 0 )
        {
            label.numberOfLines = 0;
            CGSize sz = [string sizeWithFont:label.font constrainedToSize:CGSizeMake(wrapWidth, 10000) lineBreakMode:UILineBreakModeWordWrap];
            
            label.frame = CGRectMake(0, 0, sz.width, sz.height);
        }
        else
        {
            [label sizeToFit];
        }
        
        CGFloat scaleFactor = [SharedRenderer renderer].glView.contentScaleFactor;
        
        UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, scaleFactor);
        [label.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *layerImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();    
        
        //DBLog(@"\tText %@ frame size %.1f x %.1f", label.text, label.frame.size.width, label.frame.size.height);                
        
        CCTexture2D *texture = [[CCTexture2D alloc] initWithImage:layerImage];        
        
        //DBLog(@"\tTexture size is %d %d", texture.pixelsWide, texture.pixelsHigh);
        
        cache = [RenderedTextCache renderedTextCacheWithTexture:texture andLastFrame:frame];        
        [texture release];
        
        [stringCache setObject:cache forKey:lookup];
        
        [label release];
    }        
    
    cache.lastFrameUsed = frame;    
    
    return cache.texture;
}

- (void) flushCacheForFrame:(NSUInteger)frame
{
    NSUInteger count = [stringCache count];
    id objects[count];
    id keys[count];
    
    [stringCache getObjects:objects andKeys:keys];
    
    for( int i = 0; i < count; i++ )
    {
        RenderedTextCache *cache = objects[i];
        
        if( cache.lastFrameUsed < frame )
        {
            //DBLog(@"Flushing texture for key %@", (NSString*)keys[i]);
            [stringCache removeObjectForKey:keys[i]];
        }
    }
}

- (void) flushCache
{
    [stringCache removeAllObjects];
}

@end
