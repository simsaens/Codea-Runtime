//
//  Persistence.m
//  Codea
//
//  Created by Dylan Sale on 5/11/11.
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

#import "Persistence.h"

#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "image.h"
#import "lauxlib.h"

#define PREFIX_FORMAT @"%@_DATA"

NSString* globalDataPrefix = @"CODEA_GLOBAL_DATA_STORE"; //Doesn't end it _DATA so it cant conflict with a local data

#define BOOL_CHARACTER "§"
#define TRUE_STRING @BOOL_CHARACTER 
#define FALSE_STRING @BOOL_CHARACTER BOOL_CHARACTER

NSString* currentPrefix = nil;
NSMutableDictionary* currentLocalStore = nil;

NSString* currentProjectDataPath = nil;
NSMutableDictionary* currentProjectStore = nil;

NSMutableDictionary* currentProjectInfoStore = nil;

NSMutableDictionary* currentGlobalStore = nil;

#pragma mark - Function Prototypes
int saveData(lua_State *L, NSMutableDictionary* saveToDict);
int readData(lua_State *L, NSDictionary* readFromDict);


#pragma mark - Local Store

void saveLocalStore()
{
    if (currentPrefix && currentLocalStore) 
    {
        [[NSUserDefaults standardUserDefaults] setObject:currentLocalStore forKey:currentPrefix];
    }
}


void setLocalDataPrefix(NSString* name)
{
    saveLocalStore();
    if(name == nil)
    {
        SAFE_RELEASE(currentPrefix);
        SAFE_RELEASE(currentLocalStore);
        return;
    }

    [currentPrefix release];
    currentPrefix = [[NSString stringWithFormat:PREFIX_FORMAT,name ] retain];
    
    [currentLocalStore release];
    currentLocalStore = [[[NSUserDefaults standardUserDefaults] objectForKey:currentPrefix] mutableCopy];
    if (!currentLocalStore)
    {
        currentLocalStore = [[NSMutableDictionary alloc] init];
    }
    
}

void removeLocalDataForPrefix(NSString* name)
{
    assert(currentPrefix == nil);
    NSString* prefix = [NSString stringWithFormat:PREFIX_FORMAT,name];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefix];
}



int clearLocalData(lua_State *L)
{
    [currentLocalStore release];
    currentLocalStore = [[NSMutableDictionary alloc] init];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:currentPrefix];
    return 0;
}

int saveLocalData(lua_State *L)
{
    assert(currentPrefix != nil);
    int num = saveData(L, currentLocalStore);
    saveLocalStore();
    return num;
}

int readLocalData(lua_State *L)
{
    assert(currentPrefix != nil);
    int num = readData(L, currentLocalStore);
    return num;
}

#pragma mark - Project Info

void setProjectInfoStore(NSMutableDictionary *info)
{
    [currentProjectInfoStore release];    
    currentProjectInfoStore = [info retain];
}

int saveProjectInfo(lua_State *L)
{
    int num = saveData(L, currentProjectInfoStore);
    return num;
}

int readProjectInfo(lua_State *L)
{
    int num = readData(L, currentProjectInfoStore);
    return num;
}

#pragma mark - Project Data

void saveProjectStore()
{
    if (currentProjectDataPath && currentProjectStore)
    {
        if(![currentProjectStore writeToFile:currentProjectDataPath atomically:YES])
        {
            CDLog(@"Didn't write project data store for some reason");
        }
    }
}

void setProjectDataPath(NSString* path)
{
    saveProjectStore();
    if (path == nil) 
    {
        SAFE_RELEASE(currentProjectDataPath);
        SAFE_RELEASE(currentProjectStore);
        return;
    }
    
    [currentProjectDataPath release];
    currentProjectDataPath = [[path stringByAppendingPathComponent:PROJECT_DATA_FILE] retain];

    [currentProjectStore release];
    currentProjectStore = [[NSMutableDictionary dictionaryWithContentsOfFile:currentProjectDataPath] retain];
    if (!currentProjectStore)
    {
        currentProjectStore = [[NSMutableDictionary alloc] init];
    }
}


int clearProjectData(lua_State *L)
{
    [currentProjectStore release];
    currentProjectStore = [[NSMutableDictionary alloc] init];
    saveProjectStore();
    return 0;
}

int saveProjectData(lua_State *L)
{
    assert(currentProjectDataPath != nil);
    int num = saveData(L, currentProjectStore);
    saveProjectStore();
    return num;
}

int readProjectData(lua_State *L)
{
    assert(currentProjectDataPath != nil);
    int num = readData(L, currentProjectStore);
    return num;
}

#pragma mark - Global Data

void setupGlobalData()
{
    [currentGlobalStore release];
    currentGlobalStore = [[[NSUserDefaults standardUserDefaults] objectForKey:globalDataPrefix] mutableCopy];
    if (currentGlobalStore == nil) 
    {
        currentGlobalStore = [[NSMutableDictionary alloc] init];
    }
}

void saveGlobalStore()
{
    if (currentGlobalStore)
    {
        [[NSUserDefaults standardUserDefaults] setObject:currentGlobalStore forKey:globalDataPrefix];
    }
}

int saveGlobalData(lua_State *L)
{
    assert(currentGlobalStore != nil);
    int num = saveData(L, currentGlobalStore);
    saveGlobalStore();
    return num;
}

int readGlobalData(lua_State *L)
{
    assert(currentGlobalStore != nil);
    int num = readData(L, currentGlobalStore);
    return num;    
}

#pragma mark - Generic Functions
//Checks if there are any null characters before the last character in the string
//len is the size before the null terminating character ie, "abc\0" has length 3 (assuming it doesnt have an extra \0 at the end).
BOOL has_nulls(const char* str, size_t len)
{
    for(size_t i=0; i<len; i++)
    {
        if(str[i] == '\0')
            return YES;
    }
    
    return NO;
}


//May not return if error is cause
int saveData(lua_State *L, NSMutableDictionary* saveToDict)
{
    
    int n = lua_gettop(L);
    if(n != 2)
    {
        luaL_error(L, "Expected two arguments");
        return 0;
    }
    
    size_t keyLen = 0;
    const char* key = luaL_checklstring(L, 1, &keyLen);
    
    if(has_nulls(key, keyLen))
    {
        luaL_error(L, "key cannot have null characters");
        return 0;
    }
    if (keyLen == 0) 
    {
        luaL_error(L, "key cannot be the empty string");
    }
    
    NSString* nsKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    
    if (lua_isnumber(L, 2))
    {
        lua_Number value = lua_tonumber(L, 2);
        [saveToDict setObject:[NSNumber numberWithFloat:value] forKey:nsKey];
    }
    else if(lua_isboolean(L, 2))
    {
        int value = lua_toboolean(L, 2);
        if (value) 
        {
            [saveToDict setObject:TRUE_STRING forKey:nsKey];
        }
        else
        {
            [saveToDict setObject:FALSE_STRING forKey:nsKey];            
        }
    }
    else if(lua_isstring(L, 2))
    {
        size_t valueLen = 0;
        const char* value = lua_tolstring(L, 2, &valueLen);
        
        if (has_nulls(value, valueLen)) 
        {
            luaL_error(L, "value cannot have null characters");
            return 0;
        }
        
        NSString* nsValue = [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
        //[[NSUserDefaults standardUserDefaults] setObject:nsValue forKey:nsKey];
        [saveToDict setObject:nsValue forKey:nsKey];
    }
    else if(lua_isnil(L, 2))
    {
        [saveToDict removeObjectForKey:nsKey];
    }
    else
    {
        luaL_error(L, "Can only save a string or a number or nil");
        return 0;
    }
    
    return 0;
}


//May not return if error is called
int readData(lua_State *L, NSDictionary* readFromDict)
{
    
    int n = lua_gettop(L);
    if(n < 1 )
    {
        luaL_error(L, "Expected one or two arguments");
        return 0;
    }
    
    int useDefault = n >= 2;
    
    size_t keyLen = 0;
    const char* key = luaL_checklstring(L, 1, &keyLen);
    if(has_nulls(key, keyLen))
    {
        luaL_error(L, "key cannot have null characters");
        return 0;
    }
    
    NSString* nsKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    
    NSObject* value = [readFromDict objectForKey:nsKey];

    if(!value)
    {
        if(!useDefault)
        {
            lua_pushnil(L);
        }
        else
        {
            lua_pushvalue(L, 2);
        }
        return 1;
    }
    else if([value isKindOfClass:[NSString class]])
    {
        NSString* valueNSStr = (NSString*)value;
        
        //Check if its a string representing a boolean (because you can't distringuish with NSNumber)
        if ([valueNSStr isEqualToString:TRUE_STRING]) 
        {
            lua_pushboolean(L, 1);
            return 1;
        }
        else if([valueNSStr isEqualToString:FALSE_STRING])
        {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        const char* valueStr = [valueNSStr UTF8String];
        lua_pushstring(L, valueStr);
        return 1;
    }
    else if([value isKindOfClass:[NSNumber class]])
    {
        NSNumber* number = (NSNumber*)value;
        lua_Number num = [number floatValue];
        lua_pushnumber(L, num);
        return 1;
    }
    
    
    luaL_error(L, "Value for key cannot be read (but it exists)");
    return 0;
}

#pragma mark - Images

NSString* getDocumentsImagesPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;    
}

NSString* getProjectImagesPath()
{
    return currentProjectDataPath;
}

UIImage* createUIImageFromImage(image_type* image)
{    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, 
                                                              image->data, 
                                                              image->rawWidth*image->rawHeight*4, 
                                                              NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(image->rawWidth,
                                        image->rawHeight,
                                        8,
                                        32,
                                        4*image->rawWidth,colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    /*I get the current dimensions displayed here */
    //    NSLog(@"Created image with width=%d, height: %d", (int)CGImageGetWidth(imageRef), (int)CGImageGetHeight(imageRef) );
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    //    NSLog(@"resultImg width:%f, height:%f", newImage.size.width,newImage.size.height);
    
    CGDataProviderRelease(provider);
    CGImageRelease(imageRef);
	CGColorSpaceRelease(colorSpaceRef);
    
    return newImage;    
}

int saveImage(lua_State *L, NSString* path)
{
    int n = lua_gettop(L);
    if(n != 2)
    {
        luaL_error(L, "Expected two arguments");
        return 0;
    }
    
    size_t keyLen = 0;
    const char* key = luaL_checklstring(L, 1, &keyLen);
    
    if(has_nulls(key, keyLen))
    {
        luaL_error(L, "key cannot have null characters");
        return 0;
    }
    if (keyLen == 0) 
    {
        luaL_error(L, "key cannot be the empty string");
    }    
    
    NSString* nsKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    
    image_type* image = checkimage(L, 2);
    
    if (nsKey && image)
    {
        NSString* file = [[path stringByAppendingPathComponent:nsKey] stringByAppendingPathExtension:@"png"];               
        UIImage* sourceImage = createUIImageFromImage(image);
        UIImage* flippedImage = [UIImage imageWithCGImage:sourceImage.CGImage 
                                                    scale:1.0 orientation: UIImageOrientationUpMirrored];        
        [UIImagePNGRepresentation(flippedImage) writeToFile:file atomically:YES];
    }
    
    return 0;    
}

int saveDocumentsImage(lua_State *L)
{
    return saveImage(L, getDocumentsImagesPath());
}

int saveProjectImage(lua_State *L)
{
    return saveImage(L, getProjectImagesPath());
}

