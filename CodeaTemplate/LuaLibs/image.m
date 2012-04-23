//
//  image.c
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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "image.h"
#include "lua.h"
#include "lauxlib.h"

#include "color.h"

#import "CCTexture2D.h"

#import "SharedRenderer.h"
#import "EAGLView.h"

#define IMAGETYPE "codeaimage"
#define IMAGESIZE sizeof(image_type)

#define RED(x) 

void updateImageTextureIfRequired(image_type* image)
{
    if( image->dataChanged || image->texture == nil )
    {
        [image->texture release];
        
        image->texture = [[CCTexture2D alloc] initWithData:image->data pixelFormat:kCCTexture2DPixelFormat_RGBA8888 pixelsWide:image->rawWidth pixelsHigh:image->rawHeight contentSize:CGSizeMake(image->rawWidth, image->rawHeight)];
        
        image->texture.scale = [SharedRenderer renderer].glView.contentScaleFactor;

        image->dataChanged = NO;        
    }
}

static image_type* Pget( lua_State *L, int i )
{
    if (luaL_checkudata(L,i,IMAGETYPE)==NULL) luaL_typerror(L,i,IMAGETYPE);
    return lua_touserdata(L,i);
}

image_type* checkimage(lua_State *L, int i)
{
    return Pget(L, i);
}

static void allocateData(image_type *image)
{
    size_t size = image->rawWidth*image->rawHeight;
    if (image->data)
    {
        free(image->data);
        image->data = 0;
    }
    if (size > 0) 
    {
        image->data = (image_type_data*)calloc(size, sizeof(image_type_data));    
    }
    
    [image->texture release];
    image->texture = nil;
    image->dataChanged = YES;
}

static void deallocData(image_type *image)
{
    if(image->data)
    {
        free(image->data);
        image->data = 0;        
    }
    [image->texture release];
    image->texture = nil;
}

inline static image_type_data colorToImageData(color_type* c)
{
    image_type_data data = {(image_color_element)c->r,
                            (image_color_element)c->g,
                            (image_color_element)c->b,
                            (image_color_element)c->a};
    return data;
}

inline static image_type_data createImageDataType(lua_Integer r, lua_Integer g, lua_Integer b, lua_Integer a)
{
    image_type_data data = {(image_color_element)r,
                            (image_color_element)g,
                            (image_color_element)b,
                            (image_color_element)a};
    return data;
    
}


//    xx (0,0) -> 0 , (1,0) -> 1
//    xx (0,1) -> 2 , (1,1) -> 3
//
//    _x_x (0,0) -> 0, (1,0) -> 2
//    xxxx
//    _x_x (0,1) -> 8, (1,1) -> 10
//    xxxx

inline static ptrdiff_t xyToIdx(lua_Integer x, lua_Integer y, lua_Integer width, NSUInteger scaleFactor)
{
    return (y*scaleFactor)*(width*scaleFactor)+(x*scaleFactor);
}


// _a_b (0,0) touches 1,4,5.  (1,0) touches 3,6,7
// aabb
// _c_d (0,1) touches 9,12,13 (1,1) touches 11,14,15
// ccdd
inline static void fillColor(image_type* image, lua_Integer x, lua_Integer y, lua_Integer width, NSUInteger scaleFactor, image_type_data* c)
{
    ptrdiff_t idx = xyToIdx(x,y,width,scaleFactor);
    image->data[idx] = *c;
    
    if(scaleFactor > 1)
    {
        int widthStep = scaleFactor*width;
        int xd = 1, yd = 0;
        for(; yd < scaleFactor; yd++)
        {
            for(; xd < scaleFactor; xd++)
            {
                ptrdiff_t fillIdx = idx+(widthStep*yd)+xd;
                image->data[fillIdx] = *c;
            }
            
            xd = 0;
        }
    }
}

static int setPixel_internal( lua_State *L, image_type* v, lua_Integer width, lua_Integer height, NSUInteger scaleFactor )
{    
    int n = lua_gettop(L);
    //image_type *v=Pget(L,1);

    lua_Integer a = 255;
    
    switch (n) {
        case 4:
        {
            //Was given color
            lua_Integer x = luaL_checkinteger(L, 2)-1;
            lua_Integer y = luaL_checknumber(L, 3)-1; 

            color_type* c = checkcolor(L, 4);
            
            if (x >= 0 && x < width && y >= 0 && y < height) 
            {
                image_type_data col = colorToImageData(c);
                fillColor(v,x,y,width,scaleFactor,&col);
                v->dataChanged = YES;
            }
            else
            {
                //luaL_error(L, "pixel out of bounds of image, %d, %d -> given %d, %d", v->width, v->height,x+1,y+1);
                return 0;
            }
            break;            
        }
        case 7:
            a = luaL_checkinteger(L, 7);            
        case 6:
        {    
            //Was given r,g,b,a
            lua_Integer x = luaL_checkinteger(L, 2)-1;
            lua_Integer y = luaL_checknumber(L, 3)-1; 

            lua_Integer r = luaL_checkinteger(L, 4);
            lua_Integer g = luaL_checkinteger(L, 5);
            lua_Integer b = luaL_checkinteger(L, 6);


            if (x >= 0 && x < width && y >= 0 && y < height) 
            {                
                image_type_data col = createImageDataType(r, g, b, a);
                fillColor(v, x, y, width, scaleFactor, &col);
                v->dataChanged = YES;
            }
            else
            {
                //luaL_error(L, "pixel out of bounds of image, %d, %d -> given %d, %d", v->width, v->height,x+1,y+1);
                return 0;
            }
            break;
        }
        default:
            luaL_argerror(L,n,"incorrect number of arguments");
            return 0;
            break;
    }
    
    return 0;
}

static int setPixel( lua_State *L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return setPixel_internal(L, v, v->scaledWidth, v->scaledHeight, v->scaleFactor);
}

static int setPixelRaw( lua_State *L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return setPixel_internal(L, v, v->rawWidth, v->rawHeight, 1);
}

static int getPixel_internal( lua_State *L, image_type* v, lua_Integer width, lua_Integer height, NSUInteger scaleFactor )
{
    int n = lua_gettop(L);
    if (n != 3)
    {
        luaL_argerror(L, n, "incorrect number of arguments");
        return 0;
    }
    
    //image_type *v=Pget(L,1);
    lua_Integer x = luaL_checkinteger(L, 2)-1;
    lua_Integer y = luaL_checknumber(L, 3)-1; 

    if (x >= 0 && x < width && y >= 0 && y < height) 
    {                

        image_type_data *d = v->data+xyToIdx(x, y, width, scaleFactor);
        lua_pushinteger(L, d->r);
        lua_pushinteger(L, d->g);
        lua_pushinteger(L, d->b);
        lua_pushinteger(L, d->a);
        
        return 4;
    }
    else
    {
        luaL_error(L, "pixel out of bounds of image, %d, %d -> given %d, %d", width, height,x+1,y+1);
        return 0;
    }

}

static int getPixel( lua_State *L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return getPixel_internal(L, v, v->scaledWidth, v->scaledHeight, v->scaleFactor);
}

static int getPixelRaw( lua_State *L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return getPixel_internal(L, v, v->rawWidth, v->rawHeight, 1);
}


static image_type* Pnew( lua_State *L )
{
    image_type *v=lua_newuserdata(L,IMAGESIZE);
    v->texture = nil;
    v->dataChanged = NO;
    v->rawWidth = 0;
    v->rawHeight = 0;
    v->scaledWidth = 0;
    v->scaledHeight = 0;
    v->premultiplied = 0;
    v->scaleFactor = 1;
    v->data = 0;
    luaL_getmetatable(L,IMAGETYPE);
    lua_setmetatable(L,-2);
    return v;
}

image_type* pushimage(lua_State *L, unsigned char* data, size_t width, size_t height, boolean_t premultipliedAlpha)
{
    image_type *v=Pnew(L);
    
    v->rawWidth = width;
    v->rawHeight = height;
    v->scaledWidth = width;
    v->scaledHeight = height;
    v->scaleFactor = 1;
    v->premultiplied = premultipliedAlpha;
    allocateData(v);
    
    if(data)
    {
        memcpy( v->data, data, width*height*sizeof(image_type_data) );        
    }
    
    return v;
}

static CGContextRef newBitmapRGBA8ContextFromImage(image_type* image)
{
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	uint32_t *bitmapData = (uint32_t*)image->data;
    
	size_t bitsPerPixel = 32;
	size_t bitsPerComponent = 8;
	size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
	size_t width = image->rawWidth;
	size_t height = image->rawHeight;
    
	size_t bytesPerRow = width * bytesPerPixel;
	
	colorSpace = CGColorSpaceCreateDeviceRGB();
    
	if(!colorSpace) 
    {
		NSLog(@"Error allocating color space RGB\n");
		return NULL;
	}
    
	if(!bitmapData) 
    {
		NSLog(@"Error allocating memory for bitmap\n");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}
    
	//Create bitmap context
    
	context = CGBitmapContextCreate(bitmapData, 
                                    width, 
                                    height, 
                                    bitsPerComponent, 
                                    bytesPerRow, 
                                    colorSpace, 
                                    kCGImageAlphaPremultipliedLast);	// RGBA
	if(!context) 
    {
		NSLog(@"Bitmap context not created");
	}
    
	CGColorSpaceRelease(colorSpace);
    
	return context;	
}


image_type* pushUIImage(lua_State* L, UIImage* image)
{
    CGImageRef imageRef = image.CGImage;
    
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);

    image_type* luaImage = pushimage(L, NULL, width, height, 1);
    if (!luaImage) 
    {
        NSLog(@"Error creating lua image");
        return NULL;
    }
    
	// Create a bitmap context to draw the uiimage into
	CGContextRef context = newBitmapRGBA8ContextFromImage(luaImage);
    
	if(!context) 
    {
		return NULL;
	}
    
    
	CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    //CGContextRotateCTM(context, M_PI);
    // Draw image into the context to get the raw image data
	CGContextDrawImage(context, rect, imageRef);
    
    CGContextRelease(context);

    return luaImage;
}


static int copyImage_internal( lua_State *L, image_type* v, lua_Integer width, lua_Integer height, NSUInteger scaleFactor )
{
    int n = lua_gettop(L);
    //image_type *v=Pget(L,1);
    
    switch (n)
    {
        case 1:
        {
            image_type *newImage = Pnew(L);
            
            newImage->rawWidth = v->rawWidth;
            newImage->rawHeight = v->rawHeight;
            newImage->scaledWidth = v->scaledWidth;
            newImage->scaledHeight = v->scaledHeight;
            newImage->scaleFactor = v->scaleFactor;
            allocateData(newImage);
            memcpy(newImage->data, v->data, v->rawWidth*v->rawHeight*sizeof(image_type_data));
            break;
        }
        case 5:
        {
            image_type *newImage = Pnew(L);
            lua_Integer x = luaL_checkinteger(L, 2)-1;
            lua_Integer y = luaL_checkinteger(L, 3)-1;
            lua_Integer targetWidth = luaL_checkinteger(L, 4);
            lua_Integer targetHeight = luaL_checkinteger(L, 5);

            luaL_argcheck(L, targetWidth > 0, 4, "target width must be > 0");
            luaL_argcheck(L, targetHeight > 0, 5, "target height must be > 0");

            if (x < 0)
            {
                targetWidth += x;
                x = 0;
            }
            
            if (y < 0) 
            {
                targetHeight += y;
                
                y = 0;
            }

            if (x+targetWidth > width) 
            {
                targetWidth = width-x;
            }
            
            if (y+targetHeight > height) 
            {
                targetHeight = height-y;
            }
            
            if (targetWidth < 0) {
                luaL_error(L, "rect does not intersect image on x axis");
                return 0;
            }
            
            if (targetHeight < 0) {
                luaL_error(L, "rect does not intersect image on y axis");
                return 0;
            }
            
            newImage->rawWidth = targetWidth*scaleFactor;
            newImage->rawHeight = targetHeight*scaleFactor;
            newImage->scaledWidth = targetWidth;
            newImage->scaledHeight = targetHeight;
            newImage->scaleFactor = v->scaleFactor;
            allocateData(newImage);
            
            for (int j = 0; j<newImage->rawHeight; j++) 
            {
                for(int i = 0; i<newImage->rawWidth; i++)
                {
                    ptrdiff_t vIndex = xyToIdx(x+i, y+j, width*scaleFactor, 1);
                    ptrdiff_t index = xyToIdx(i, j, newImage->rawWidth, 1);
                    newImage->data[index] = v->data[vIndex];
                }
            }
            
            break;            
        }
        default:
            luaL_argerror(L, n, "incorrect number of arguments");
            return 0;
            break;
    }
    
    
    return 1;
}

static int copyImage( lua_State* L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return copyImage_internal(L, v, v->scaledWidth, v->scaledHeight, v->scaleFactor);
}

static int copyImageRaw( lua_State* L )
{
    image_type *v=Pget(L,1);
    if (v == NULL) 
    {
        return 0;
    }
    return copyImage_internal(L, v, v->rawWidth, v->rawHeight, 1);
}

static int decompress(lua_State *L)
{
    int n = lua_gettop(L);
    size_t len;
    const char* data = 0;
    if(n < 1 || (data = luaL_checklstring(L, 1, &len)) == NULL )
    {
        luaL_argerror(L, 1, "expected data");
        return 0;
    }
    
    NSData* nsdata = [NSData dataWithBytesNoCopy:(void*)data length:len freeWhenDone:NO];
    UIImage* image = [UIImage imageWithData:nsdata];
    pushUIImage(L, image);
    
    return 1;
}


static int Lnew( lua_State *L )
{
    if(lua_gettop(L) == 1 && lua_type(L, 1) == LUA_TSTRING)
    {
        return decompress(L);
    }
    else
    {
        image_type *v = Pnew(L);
        v->scaledWidth=luaL_optnumber(L,1,0);
        v->scaledHeight=luaL_optnumber(L,2,0);
        NSUInteger scaleFactor = [SharedRenderer renderer].glView.contentScaleFactor; //[SharedRenderer renderer].glView.contentScaleFactor;
        v->rawWidth = v->scaledWidth * scaleFactor;
        v->rawHeight = v->scaledHeight * scaleFactor;
        v->scaleFactor = scaleFactor;
        v->premultiplied = 0;
        allocateData(v);     
    }
    
    return 1;
}

static int Lget( lua_State *L )
{
    image_type *v=Pget(L,1);
    const char* c = luaL_checkstring(L,2);
    
    if( strcmp(c, "width") == 0 )
    {
        lua_pushnumber(L, v->scaledWidth);
    }
    else if( strcmp(c, "height") == 0 )
    {
        lua_pushnumber(L, v->scaledHeight);        
    }
    else if( strcmp(c, "rawWidth") == 0 )
    {
        lua_pushnumber(L, v->rawWidth);
    }
    else if( strcmp(c, "rawHeight") == 0 )
    {
        lua_pushnumber(L, v->rawHeight);        
    }
    else if( strcmp(c, "premultiplied") == 0)
    {
        lua_pushboolean(L, v->premultiplied);
    }
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, IMAGETYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);
    }
    
    return 1;
}

static int Lset(lua_State *L) 
{
    image_type *v=Pget(L,1);
    const char* i=luaL_checkstring(L,2);
    if(strcmp(i, "premultiplied") == 0)
    {
        lua_Number b =lua_toboolean(L, 3);
        v->premultiplied = b;
    }
    return 1;
}

static int Lgc( lua_State *L)
{
    image_type *v=Pget(L,1);
    deallocData(v);
    return 0;
}

//static int Lset( lua_State *L )
//{
//    image_type *v=Pget(L,1);
//    const char* c = luaL_checkstring(L,2);
//    lua_Number t=luaL_checknumber(L,3);
//    
//    
//    return 0;
//}

static int Ltostring(lua_State *L)
{
    image_type *v = Pget(L,1);
    lua_pushfstring(L,"Image: width = %d, height = %d (raw_width = %d, raw_height = %d)",v->scaledWidth, v->scaledHeight, v->rawWidth, v->rawHeight);
    return 1;
}


static const luaL_reg R[] =
{
    { "__index", Lget },
    { "__newindex",	Lset		},
    { "__tostring", Ltostring },
    { "__gc", Lgc },
    { "get", getPixel },
    { "set", setPixel },
    { "copy", copyImage },
    { "rawCopy", copyImageRaw },
    { "rawGet", getPixelRaw },
    { "rawSet", setPixelRaw },
    { "decompressImage", decompress}, 
    { NULL, NULL }
};

LUALIB_API int luaopen_image(lua_State *L)
{
    luaL_newmetatable(L,IMAGETYPE);

    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);   // pushes the metatable
    lua_settable(L, -3);    // metatable.__index = metatable

    luaL_register(L, NULL, R);
    
    
    lua_register(L,"image",Lnew);
    
    return 1;
}