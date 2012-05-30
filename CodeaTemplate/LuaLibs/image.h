//
//  image.h
//  Codea
//
//  Created by Dylan Sale on 19/11/11.
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

#ifndef Codify_image_h
#define Codify_image_h

#include "lua.h"

#define CODIFY_IMAGELIBNAME "image"

typedef unsigned char image_color_element;
typedef struct image_type_data_t {
    image_color_element r,g,b,a;
} image_type_data;

@class CCTexture2D;

typedef struct image_type_t
{
    lua_Integer scaledWidth, scaledHeight; //Scaled by 1/contentScaleFactor (user facing)
    lua_Integer rawWidth, rawHeight; //The raw size (renderer facing)
    NSUInteger scaleFactor;
    image_type_data* data;
    BOOL dataChanged;
    CCTexture2D* texture;
    boolean_t premultiplied;
} image_type;


#ifdef __cplusplus
extern "C" {
#endif 
    
    LUALIB_API int (luaopen_image) (lua_State *L);
    image_type *checkimage(lua_State *L, int i);
    image_type *pushimage(lua_State *L, unsigned char* data, size_t width, size_t height, boolean_t premultipliedAlpha, float scale);
    
    //Create an image_type on the lua stack and draw the UIImage into it as premultiplied RGBA
    image_type* pushUIImage(lua_State* L, UIImage* image);

    
    void updateImageTextureIfRequired(image_type* image);
    
#ifdef __cplusplus
}
#endif 

#endif
