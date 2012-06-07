//
//  RenderCommands.m
//  Codea
//
//  Created by Simeon Nasilowski on 18/05/11.
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

#import "RenderCommands.h"
#import "RenderManager.h"
#import "TextRenderer.h"

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <CoreText/CoreText.h>

#import "ShaderManager.h"
#import "SpriteManager.h"
#import "SharedRenderer.h"
#import "EAGLView.h"

#include <Box2d/ConvexDecomposition/b2Polygon.h>

#ifdef __cplusplus
extern "C" {
#endif    
    #import "lua.h"
    #import "lauxlib.h"
    #import "color.h"
    #import "image.h"
    #import "mesh.h"
    #import "vec2.h"
#ifdef __cplusplus
}
#endif    

#import "matrix44.h"

RenderManager *renderAPI;

void drawLineCap(GLfloat x1, GLfloat y1, float strokeWidth);

static const struct luaL_reg graphics [] = 
{
    {"background", background},
    {"fill", fill},
    {"noFill", noFill},    
    {"stroke", stroke},
    {"noStroke", noStroke},        
    {NULL,NULL}    
};

int luaopen_graphics(lua_State *L)
{
    luaL_openlib(L, "graphics", graphics, 0);    
    return 1;
}

void rc_initialize(RenderManager *api)
{
    renderAPI = api;
}

int background(lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 1:
        {
            color_type* colT = checkcolor(L, 1);
            if( colT )
            {
                glClearColor(colT->r/255.0f, colT->g/255.0f, colT->b/255.0f, colT->a/255.0f);
                break;
            }
            
            float col = luaL_checkinteger(L, 1)/255.0f;
            glClearColor(col, col, col, 1.0f);
        }   break;
        case 2:
        {
            lua_Number g = luaL_checknumber(L, 1)/255.0f;
            lua_Number a = luaL_checknumber(L, 2)/255.0f;      
            
            glClearColor(g, g, g, a);
            
        }   break;            
        case 3:
        {
            lua_Integer r = luaL_checkinteger(L, 1);
            lua_Integer g = luaL_checkinteger(L, 2);            
            lua_Integer b = luaL_checkinteger(L, 3);            
            glClearColor(r/255.0f,g/255.0f,b/255.0f, 1.0f);            
        }   break;
        case 4:
        {
            lua_Integer r = luaL_checkinteger(L, 1);
            lua_Integer g = luaL_checkinteger(L, 2);            
            lua_Integer b = luaL_checkinteger(L, 3);            
            lua_Integer a = luaL_checkinteger(L, 4);                        
            glClearColor(r/255.0f,g/255.0f,b/255.0f,a/255.0f);                        
        }   break;
    }
    
    glClear(GL_COLOR_BUFFER_BIT);    
    
    return 0;
}

int tint(lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            const float *curTint = renderAPI.tintColor;
            
            lua_pushinteger(L, curTint[0] * 255);
            lua_pushinteger(L, curTint[1] * 255);
            lua_pushinteger(L, curTint[2] * 255);
            lua_pushinteger(L, curTint[3] * 255);            
            
            return 4;
        } break;            
        case 1:
        {
            color_type* colT = checkcolor(L, 1);
            if( colT )
            {
                [renderAPI setStyleTintColor:glm::vec4(colT->r/255.0f, colT->g/255.0f, colT->b/255.0f, colT->a/255.0f)];
                break;
            }            
            
            lua_Number col = luaL_checknumber(L, 1)/255.0f;
            [renderAPI setStyleTintColor:glm::vec4(col,col,col,1.0f)];
        }   break;
        case 2:
        {
            lua_Number g = luaL_checknumber(L, 1)/255.0f;
            lua_Number a = luaL_checknumber(L, 2)/255.0f;      
            
            [renderAPI setStyleTintColor:glm::vec4(g,g,g,a)];            
            
        }   break;            
        case 3:
        {            
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            [renderAPI setStyleTintColor:glm::vec4(r,g,b,1.0f)];            
        }   break;
        case 4:
        {
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            lua_Number a = luaL_checknumber(L, 4)/255.0f;                        
            [renderAPI setStyleTintColor:glm::vec4(r,g,b,a)];            
        }   break;
    }
    
    return 0;    
}
int noTint(lua_State *L)
{
    [renderAPI setStyleTintColor:glm::vec4(1,1,1,1)];
    return 0;
}

int fill(lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            const float *curFill = renderAPI.fillColor;
            
            lua_pushinteger(L, curFill[0] * 255);
            lua_pushinteger(L, curFill[1] * 255);
            lua_pushinteger(L, curFill[2] * 255);
            lua_pushinteger(L, curFill[3] * 255);            
            
            return 4;
        } break;
        case 1:
        {
            color_type* colT = checkcolor(L, 1);
            if( colT )
            {
                [renderAPI setStyleFillColor:glm::vec4(colT->r/255.0f, colT->g/255.0f, colT->b/255.0f, colT->a/255.0f)];
                break;
            }            
            
            lua_Number col = luaL_checknumber(L, 1)/255.0f;
            [renderAPI setStyleFillColor:glm::vec4(col,col,col,1.0f)];
        }   break;
        case 2:
        {
            lua_Number g = luaL_checknumber(L, 1)/255.0f;
            lua_Number a = luaL_checknumber(L, 2)/255.0f;      

            [renderAPI setStyleFillColor:glm::vec4(g,g,g,a)];            
            
        }   break;
        case 3:
        {            
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            [renderAPI setStyleFillColor:glm::vec4(r,g,b,1.0f)];            
        }   break;
        case 4:
        {
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            lua_Number a = luaL_checknumber(L, 4)/255.0f;                        
            [renderAPI setStyleFillColor:glm::vec4(r,g,b,a)];            
        }   break;
    }

    return 0;    
}
int noFill(lua_State *L)
{
    [renderAPI setStyleFillColor:glm::vec4(0,0,0,0)];
    return 0;
}

int stroke(lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            const float *curStroke = renderAPI.strokeColor;
            
            lua_pushinteger(L, curStroke[0] * 255);
            lua_pushinteger(L, curStroke[1] * 255);
            lua_pushinteger(L, curStroke[2] * 255);
            lua_pushinteger(L, curStroke[3] * 255);            
            
            return 4;
        } break;           
        case 1:
        {
            color_type* colT = checkcolor(L, 1);
            if( colT )
            {
                [renderAPI setStyleStrokeColor:glm::vec4(colT->r/255.0f, colT->g/255.0f, colT->b/255.0f, colT->a/255.0f)];
                break;
            }                        
            
            lua_Number col = luaL_checknumber(L, 1)/255.0f;
            [renderAPI setStyleStrokeColor:glm::vec4(col,col,col,1.0f)];
        }   break;
        case 2:
        {
            lua_Number g = luaL_checknumber(L, 1)/255.0f;
            lua_Number a = luaL_checknumber(L, 2)/255.0f;      
            
            [renderAPI setStyleStrokeColor:glm::vec4(g,g,g,a)];            
            
        }   break;            
        case 3:
        {            
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            [renderAPI setStyleStrokeColor:glm::vec4(r,g,b,1.0f)];            
        }   break;
        case 4:
        {
            lua_Number r = luaL_checknumber(L, 1)/255.0f;
            lua_Number g = luaL_checknumber(L, 2)/255.0f;            
            lua_Number b = luaL_checknumber(L, 3)/255.0f;            
            lua_Number a = luaL_checknumber(L, 4)/255.0f;                        
            [renderAPI setStyleStrokeColor:glm::vec4(r,g,b,a)];            
        }   break;
    }
    
    return 0;    
}
int noStroke(lua_State *L)
{
    [renderAPI setStyleStrokeWidth:0.0f];
    return 0;
}

int strokeWidth(lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushnumber(L, *renderAPI.strokeWidth);      
            return 1;            
        }   break;
        case 1:
        {
            lua_Number width = luaL_checknumber(L, 1);
            [renderAPI setStyleStrokeWidth:width];
        }   break;
    }
    
    return 0; 
}

#pragma mark - Font parameters

int font(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        case 0:
        {
            lua_pushstring(L, renderAPI.fontName);
            return 1;
        }   break;
        case 1:
        {
            const char* name = luaL_checkstring(L, 1);
            [renderAPI setStyleFontName:name];
        }   break;
    }
    
    return 0;
}

int fontSize(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        case 0:
        {
            lua_pushnumber(L, renderAPI.fontSize);
            return 1;
        }   break;
        case 1:
        {
            lua_Number size = luaL_checknumber(L, 1);
            [renderAPI setStyleFontSize:size];
        }   break;
    }
    
    return 0;    
}

int fontMetrics(struct lua_State *L)
{
    if( CTFontCreateWithName )
    {
        
        NSString *fontName = [NSString stringWithUTF8String:renderAPI.fontName];
        CTFontRef font = CTFontCreateWithName((CFStringRef)fontName, renderAPI.fontSize, NULL);
        
        if( font )
        {
            lua_newtable(L);

            lua_pushstring(L, "size");
            lua_pushnumber(L, CTFontGetSize(font));
            lua_settable(L, -3);            
            
            lua_pushstring(L, "ascent");
            lua_pushnumber(L, CTFontGetAscent(font));
            lua_settable(L, -3);
            
            lua_pushstring(L, "descent");
            lua_pushnumber(L, CTFontGetDescent(font));
            lua_settable(L, -3);            
            
            lua_pushstring(L, "leading");     
            lua_pushnumber(L, CTFontGetLeading(font));        
            lua_settable(L, -3);            
            
            lua_pushstring(L, "xHeight");
            lua_pushnumber(L, CTFontGetXHeight(font));        
            lua_settable(L, -3);            
            
            lua_pushstring(L, "capHeight");
            lua_pushnumber(L, CTFontGetCapHeight(font));        
            lua_settable(L, -3);            
            
            lua_pushstring(L, "underlinePosition");
            lua_pushnumber(L, CTFontGetUnderlinePosition(font));        
            lua_settable(L, -3);            
            
            lua_pushstring(L, "underlineThickness");    
            lua_pushnumber(L, CTFontGetUnderlineThickness(font));        
            lua_settable(L, -3);            
            
            lua_pushstring(L, "slantAngle");    
            lua_pushnumber(L, CTFontGetSlantAngle(font));        
            lua_settable(L, -3);                                
            
            return 1;
        }
    }
    
    return 0;
}

int textWrapWidth(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        case 0:
        {
            lua_pushnumber(L, renderAPI.textWrapWidth);
            return 1;
        }   break;
        case 1:
        {
            lua_Number wrap = luaL_checknumber(L, 1);
            [renderAPI setStyleTextWrapWidth:wrap];
        }   break;
    }
    
    return 0;        
}

int textAlign(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        case 0:
        {
            lua_pushnumber(L, (int)renderAPI.textAlign);
            return 1;
        }   break;
        case 1:
        {
            lua_Integer align = luaL_checkint(L, 1);
            [renderAPI setStyleTextAlign:(GraphicsStyle::TextAlign)align];
        }   break;
    }
    
    return 0;        
}

int textSize(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    const char* name;

    CGSize result = CGSizeMake(0, 0);
    
    if( n >= 1 )
    {
        //name = luaL_checkstring(L, 1);
        name = lua_tolstring(L, 1, NULL);

        if( name )
        {
            result = [renderAPI.textRenderer sizeForString:[NSString stringWithUTF8String:name] withFont:[NSString stringWithUTF8String:renderAPI.fontName] size:renderAPI.fontSize wrapWidth:renderAPI.textWrapWidth];                 
        }
    }        
    
    lua_pushnumber(L, result.width);
    lua_pushnumber(L, result.height);
    
    return 2;   
}

#pragma mark - Matrix manipulation

int perspective(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    // The default values are: perspective(PI/3.0, width/height, cameraZ/10.0, cameraZ*10.0) where cameraZ is ((height/2.0) / tan(PI*60.0/360.0));
    
    BasicRendererViewController *rvc = [SharedRenderer renderer];
    
    lua_Number camZ = (rvc.glView.bounds.size.height/2.0f) / tanf(M_PI * 60.0 / 360.0);
    
    lua_Number fov = 45.0f;
    lua_Number aspect = rvc.glView.bounds.size.width / rvc.glView.bounds.size.height;
    lua_Number zNear = 0.1;
    lua_Number zFar = camZ * 10;
    
    switch (n) 
    {
        case 4: //fov, aspect, znear, zfar
            zFar = luaL_checknumber(L, 4);
        case 3: //fov, aspect, znear
            zNear = luaL_checknumber(L, 3);            
        case 2: //fov, aspect
            aspect = luaL_checknumber(L, 2);            
        case 1: //fov
            fov = luaL_checknumber(L, 1);            
        case 0: //none 
            break;
    }
    
    [renderAPI perspectiveFOV:fov aspect:aspect zNear:zNear zFar:zFar];
    
    return 0;
}

int ortho(struct lua_State *L)
{
    int n = lua_gettop(L);    
    
    //For gl view width and height
    BasicRendererViewController *rvc = [SharedRenderer renderer];    
    
    lua_Number left = 0;
    lua_Number right = rvc.glView.bounds.size.width;
    lua_Number bottom = 0;
    lua_Number top = rvc.glView.bounds.size.height;
    lua_Number near = -10;
    lua_Number far = 10;
    
    switch( n )
    {
        case 6:
            far = luaL_checknumber(L, 6);
        case 5:
            near = luaL_checknumber(L, 5);
        case 4:
            top = luaL_checknumber(L, 4);
        case 3:
            bottom = luaL_checknumber(L, 3);
        case 2:
            right = luaL_checknumber(L, 2);
        case 1:
            left = luaL_checknumber(L, 1);            
    }
    
    [renderAPI orthoLeft:left right:right bottom:bottom top:top zNear:near zFar:far];
    
    return 0;
}

int camera(struct lua_State *L)
{
    int n = lua_gettop(L);    
    
    glm::vec3 eye( 0, 0, -10 );
    glm::vec3 center( 0, 0, 0 );
    glm::vec3 up( 0, 1, 0 );
    
    switch (n) 
    {
        case 9:
            up.z = luaL_checknumber(L, 9);
        case 8:
            up.y = luaL_checknumber(L, 8);            
        case 7:
            up.x = luaL_checknumber(L, 7);            
        case 6:
            center.z = luaL_checknumber(L, 6);            
        case 5:
            center.y = luaL_checknumber(L, 5);
        case 4:
            center.x = luaL_checknumber(L, 4);            
        case 3:
            eye.z = luaL_checknumber(L, 3);            
        case 2:
            eye.y = luaL_checknumber(L, 2);            
        case 1:
            eye.x = luaL_checknumber(L, 1);            
        default:
            break;
    }
    
    [renderAPI setViewMatrix:glm::lookAt(eye, center, up)];
    
    return 0;
}

int applyMatrix(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        case 1:
        {
            lua_Number *m = checkmatrix44(L, 1);
            
            if( m != NULL )
            {
                glm::mat4& matrix = *(glm::mat4*)m;
                
                [renderAPI multMatrix:matrix];
            }
            
            return 0;
            
        }   break;
    }
    
    return 0;    
}

int modelMatrix(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
        //Replace model matrix with given matrix
        case 1:
        {
            lua_Number *m = checkmatrix44(L, 1);
            
            if( m != NULL )
            {
                glm::mat4& matrix = *(glm::mat4*)m;
                
                [renderAPI setMatrix:matrix];
            }
            
            return 0;
            
        }   break;
            
        //Return current model matrix            
        case 0:
        {
            pushmatrix44(L, renderAPI.modelMatrix);
            
            return 1;
            
        }   break;
    }
    
    return 0; 
}

int viewMatrix(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
            //Replace model matrix with given matrix
        case 1:
        {
            lua_Number *m = checkmatrix44(L, 1);
            
            if( m != NULL )
            {
                glm::mat4& matrix = *(glm::mat4*)m;
                
                [renderAPI setViewMatrix:matrix];
            }
            
            return 0;
            
        }   break;
            
            //Return current model matrix            
        case 0:
        {
            pushmatrix44(L, renderAPI.viewMatrix);
            
            return 1;
            
        }   break;
    }
    
    return 0; 
}

int projectionMatrix(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch (n) 
    {
            //Replace model matrix with given matrix
        case 1:
        {
            lua_Number *m = checkmatrix44(L, 1);
            
            if( m != NULL )
            {
                glm::mat4& matrix = *(glm::mat4*)m;
                
                [renderAPI setProjectionMatrix:matrix];
            }
            
            return 0;
            
        }   break;
            
            //Return current model matrix            
        case 0:
        {
            pushmatrix44(L, renderAPI.projectionMatrix);
            
            return 1;
            
        }   break;
    }
    
    return 0; 
}

#pragma mark - Other graphics functions

int pointSize(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 1:
        {
            lua_Number size = luaL_checknumber(L, 1);
            [renderAPI setStylePointSize:size];
        }   break;
    }
    
    return 0;     
}

int rectMode(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushinteger(L, (int)renderAPI.rectMode);      
            return 1;
        }   break;            
        case 1:
        {
            lua_Integer mode = luaL_checkinteger(L, 1);
            [renderAPI setStyleRectMode:(GraphicsStyle::ShapeMode)mode];
        }   break;
    }    
    
    return 0;
}

int ellipseMode(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushinteger(L, (int)renderAPI.ellipseMode);      
            return 1;
        }   break;
        case 1:
        {
            lua_Integer mode = luaL_checkinteger(L, 1);
            [renderAPI setStyleEllipseMode:(GraphicsStyle::ShapeMode)mode];
        }   break;
    }        
    
    return 0;
}

int spriteMode(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushinteger(L, (int)renderAPI.spriteMode);      
            return 1;
        }   break;            
        case 1:
        {
            lua_Integer mode = luaL_checkinteger(L, 1);
            [renderAPI setStyleSpriteMode:(GraphicsStyle::ShapeMode)mode];
        }   break;
    }        
    
    return 0;
}

int textMode(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushinteger(L, (int)renderAPI.textMode);      
            return 1;
        }   break;            
        case 1:
        {
            lua_Integer mode = luaL_checkinteger(L, 1);
            [renderAPI setStyleTextMode:(GraphicsStyle::ShapeMode)mode];
        }   break;
    }        
    
    return 0;
}

int lineCapMode(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    switch(n)
    {
        case 0:
        {
            lua_pushinteger(L, (int)renderAPI.lineCapMode);
            return 1;
        } break;
        case 1:
        {
            lua_Integer mode = luaL_checkinteger(L, 1);
            [renderAPI setStyleLineCapMode:(GraphicsStyle::LineCapMode)mode];
        } break;
    }
    
    return 0;
}

int smooth(struct lua_State *L)
{
    [renderAPI setStyleSmooth:YES];
    return 0;
}

int noSmooth(struct lua_State *L)
{
    [renderAPI setStyleSmooth:NO];
    return 0;
}

static int renderTextTexture(struct lua_State *L, CCTexture2D *texture)
{
    int n = lua_gettop(L);
    
    if( texture == nil )
    {
        return 0;
    }
    
    lua_Number x = 0;
    lua_Number y = 0;
    lua_Number w = texture.pixelsWide / texture.scale;
    lua_Number h = texture.pixelsHigh / texture.scale;
    
    switch (n) 
    {
        case 3:  //text("name", x, y)
            x = luaL_checknumber(L, 2); //x
            y = luaL_checknumber(L, 3); //y             
            break;
            
        default:
            break;
    }
    
    switch( renderAPI.textMode )
    {
        case GraphicsStyle::SHAPE_MODE_CORNER:
            break;
        default:
        case GraphicsStyle::SHAPE_MODE_CENTER:
            x = x - w*0.5f;
            y = y - h*0.5f;
            break;                
    }    
    
    GLfloat spriteVerts[] = 
    {
        x,   y,
        x+w, y,
        x,   y+h,
        x+w, y+h,
    };        
    
    GLfloat spriteUV[] = {
        0,  1,
        1,  1,
        0,  0,
        1,  0,
    };    
    
    //Load uniforms into shader    
    Shader *shader = [renderAPI useShader:@"Text"];        
    
    [renderAPI setAttributeNamed:@"Vertex" withPointer:spriteVerts size:2 andType:GL_FLOAT];
    [renderAPI setAttributeNamed:@"TexCoord" withPointer:spriteUV size:2 andType:GL_FLOAT];        
    
    //Tell the shader the Tex Unit 0 is for ColorTexture
    glUniform1i([shader uniformLocation:@"ColorTexture"], 0);
    
    //Set filtering
    if( renderAPI.smooth )
    {
        [texture setAntiAliasTexParameters];        
    }
    else
    {
        [texture setAliasTexParameters];       
    }
    
    //Bind sprite texture to tex unit 0
    [renderAPI setActiveTexture:GL_TEXTURE0];
    [renderAPI useTexture:texture.name];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
    return 0;
}

static int renderTexture(struct lua_State *L, CCTexture2D *texture, bool isImage)
{
    int n = lua_gettop(L);
    
    if( texture == nil )
    {
        return 0;
    }
    
    lua_Number x = 0;
    lua_Number y = 0;
    lua_Number w = texture.pixelsWide / texture.scale;
    lua_Number h = texture.pixelsHigh / texture.scale;
    //lua_Number cw = texture.contentSizeInPixels.width;
    //lua_Number ch = texture.contentSizeInPixels.height;    
    
    switch (n) 
    {
        case 4: //sprite("name", x, y, w)
        {
            lua_Number origWidth = w;
            w = luaL_checknumber(L, 4); //w
            //Compute height based on aspect
            h = h * (w / origWidth);
            x = luaL_checknumber(L, 2); //x
            y = luaL_checknumber(L, 3); //y             
        }   break;
            
        case 5:  //sprite("name", x, y, w, h)          
            h = luaL_checknumber(L, 5); //h 
            w = luaL_checknumber(L, 4); //w            
            //FLOW INTO case 3            
            
        case 3:  //sprite("name", x, y)
            x = luaL_checknumber(L, 2); //x
            y = luaL_checknumber(L, 3); //y             
            break;
            
        default:
            break;
    }
    
    switch( renderAPI.spriteMode )
    {
        case GraphicsStyle::SHAPE_MODE_CORNER:
            break;
        case GraphicsStyle::SHAPE_MODE_CORNERS:
        {
            //Ensure x,y are less than w,h
            lua_Number t;
            if( x > w )
            {
                t = x;
                x = w;
                w = t;
            }
            
            if( y > h )
            {
                t = y;
                y = h;
                h = t;
            }                
            
            w = w - x;
            h = h - y;
        }   break;
        case GraphicsStyle::SHAPE_MODE_CENTER:
            x = x - w*0.5f;
            y = y - h*0.5f;
            break;
        case GraphicsStyle::SHAPE_MODE_RADIUS:
            x = x - w;
            y = y - h;                
            w *= 2.0f;
            h *= 2.0f;
            break;                
    }    
    
    GLfloat spriteVerts[] = 
    {
        x,   y,
        x+w, y,
        x,   y+h,
        x+w, y+h,
    };        
    
    GLfloat spriteUV[] = {
        0,  1,
        1,  1,
        0,  0,
        1,  0,
    };    
    
    GLfloat reversedSpriteUV[] = {
        0,  0,
        1,  0,
        0,  1,
        1,  1,
    };
    
    //Load uniforms into shader    
    const float *tintColor = renderAPI.tintColor;
    
    Shader *shader = nil;
    
    if( tintColor[0] == 1 && tintColor[1] == 1 && 
        tintColor[2] == 1 && tintColor[3] == 1 )
    {
        shader = [renderAPI useShader:@"SpriteNoTint"];
    }
    else if( tintColor[0] == 1 && tintColor[1] == 1 && tintColor[2] == 1 )
    {
        shader = [renderAPI useShader:@"SpriteTintAlpha"];        
    }
    else if( tintColor[3] == 1 )
    {
        shader = [renderAPI useShader:@"SpriteTintRGB"];        
    }
    else
    {
        shader = [renderAPI useShader:@"Sprite"];                
    }        
    
    [renderAPI setAttributeNamed:@"Vertex" withPointer:spriteVerts size:2 andType:GL_FLOAT];

    if (isImage) 
    {
        [renderAPI setAttributeNamed:@"TexCoord" withPointer:reversedSpriteUV size:2 andType:GL_FLOAT];        
    }
    else
    {
        [renderAPI setAttributeNamed:@"TexCoord" withPointer:spriteUV size:2 andType:GL_FLOAT];        
    }
    
    //Tell the shader the Tex Unit 0 is for ColorTexture
    glUniform1i([shader uniformLocation:@"ColorTexture"], 0);
    
    //Set filtering
    if( renderAPI.smooth )
    {
        [texture setAntiAliasTexParameters];        
    }
    else
    {
        [texture setAliasTexParameters];       
    }
    
    //Bind sprite texture to tex unit 0
    [renderAPI setActiveTexture:GL_TEXTURE0];
    [renderAPI useTexture:texture.name];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
    return 0;
}

int drawImage(struct lua_State *L )
{
    image_type *image = checkimage(L, 1);

    CCTexture2D *texture = [[[CCTexture2D alloc] initWithData:image->data pixelFormat:kCCTexture2DPixelFormat_RGBA8888 pixelsWide:image->rawWidth pixelsHigh:image->rawHeight contentSize:CGSizeMake(image->rawWidth, image->rawHeight)] autorelease];
    
    if( image->premultiplied )
    {
        [renderAPI setBlendMode:BLEND_MODE_PREMULT];
    }
    else
    {
        [renderAPI setBlendMode:BLEND_MODE_NORMAL];        
    }
    
    return renderTexture(L, texture, true);
}

int spriteSize(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    if( n > 0 )
    {
        const char *s = lua_tolstring(L, 1, NULL); //name    
        
        if( s )
        {
            NSString *spriteName = [NSString stringWithUTF8String:s];
    
            CCTexture2D *texture = [[SpriteManager sharedInstance] spriteTextureFromString:spriteName];
        
            lua_pushinteger(L, texture.pixelsWide / [SharedRenderer renderer].glView.contentScaleFactor );
            lua_pushinteger(L, texture.pixelsHigh / [SharedRenderer renderer].glView.contentScaleFactor );        
        
            return 2;
        }
        else
        {
            image_type *image = checkimage(L, 1);            
            
            if( image )
            {
                lua_pushinteger(L, image->scaledWidth);
                lua_pushinteger(L, image->scaledHeight);
            
                return 2;
            }
        }
            
    }
    
    return 0;
}

int sprite(struct lua_State *L)
{
    const char *s = lua_tolstring(L, 1, NULL); //name
    if (s == NULL) 
    {
        image_type* image = checkimage(L, 1);
        if (image != NULL) 
        {
            if (image->dataChanged || image->texture == nil)
            {                
                updateImageTextureIfRequired(image);
                
                //Pre multiply the alpha
//                size_t textureSize = image->width*image->height*sizeof(image_type_data);
//                image_type_data* premultData = (image_type_data*)malloc(textureSize);
//                memcpy(premultData, image->data, textureSize);
//                image_type_data* dataPtr = premultData;
//                size_t len = image->width*image->height;
//                for(int i=0; i < len; i++, dataPtr++)
//                {
//                    image_color_element alpha = dataPtr->a;
//                    dataPtr->r = (image_color_element)(dataPtr->r/255.f*alpha);
//                    dataPtr->g = (image_color_element)(dataPtr->g/255.f*alpha);
//                    dataPtr->b = (image_color_element)(dataPtr->b/255.f*alpha);
//                    //dataPtr->a = alpha;
//                }
                //End premultiply

                //free(premultData); premultData = 0;
            }
            
            if( image->premultiplied )
            {
                [renderAPI setBlendMode:BLEND_MODE_PREMULT];                
            }
            else
            {
                [renderAPI setBlendMode:BLEND_MODE_NORMAL];                
            }

            //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);            
            int ret = renderTexture(L, image->texture, true);            
            //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);            
            return ret;
        }
        else
        {
            luaL_error(L, "first parameter to sprite must be a string or an image");
            return 0;
        }
    }
    else
    {
        if( s )
        {
            NSString *spriteName = [NSString stringWithUTF8String:s];
        
            CCTexture2D *texture = [[SpriteManager sharedInstance] spriteTextureFromString:spriteName];
            [renderAPI setBlendMode:BLEND_MODE_PREMULT];
            //luaL_argcheck(L, texture != nil, 1, "sprite does not exist");
            return renderTexture(L, texture, false);
        }
    }

    return 0;
}

int rect(lua_State *L)
{
    int n = lua_gettop(L);
    
    if( n == 4 )
    {
        lua_Number x = luaL_checknumber(L, 1);
        lua_Number y = luaL_checknumber(L, 2);        
        lua_Number w = luaL_checknumber(L, 3);
        lua_Number h = luaL_checknumber(L, 4);        
        
        switch( renderAPI.rectMode )
        {
            case GraphicsStyle::SHAPE_MODE_CORNER:
                break;
            case GraphicsStyle::SHAPE_MODE_CORNERS:
            {
                //Ensure x,y are less than w,h
                lua_Number t;
                if( x > w )
                {
                    t = x;
                    x = w;
                    w = t;
                }
                
                if( y > h )
                {
                    t = y;
                    y = h;
                    h = t;
                }                
                
                w = w - x;
                h = h - y;
            }   break;
            case GraphicsStyle::SHAPE_MODE_CENTER:
                x = x - w*0.5f;
                y = y - h*0.5f;
                break;
            case GraphicsStyle::SHAPE_MODE_RADIUS:
                x = x - w;
                y = y - h;                
                w *= 2.0f;
                h *= 2.0f;
                break;                
        }
        
        GLfloat rectVerts[] = 
        {
          x,   y,
          x+w, y,
          x,   y+h,
          x+w, y+h,
        };        
        
        GLfloat rectUV[] = 
        {
           -1,  -1,
            1,  -1,
           -1,   1,
            1,   1,
        };
        
        [renderAPI setBlendMode:BLEND_MODE_PREMULT];        
        
        //Load uniforms into shader            
        Shader *shader = nil;
        
        if( renderAPI.smooth )
        {
            if( [renderAPI useStroke] )
                shader = [renderAPI useShader:@"Rect"];        
            else
                shader = [renderAPI useShader:@"RectNoStroke"];
        }
        else
        {
            if( [renderAPI useStroke] )
                shader = [renderAPI useShader:@"RectNoSmooth"];        
            else
                shader = [renderAPI useShader:@"RectNoStrokeNoSmooth"];            
        }
        
        [renderAPI setAttributeNamed:@"Vertex" withPointer:rectVerts size:2 andType:GL_FLOAT];
        [renderAPI setAttributeNamed:@"TexCoord" withPointer:rectUV size:2 andType:GL_FLOAT];        

        if( [shader hasUniform:@"Size"] )
            glUniform2f([shader uniformLocation:@"Size"], w, h);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    return 0;
}

int ellipse(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    if( n >= 3 )
    {
        lua_Number x = luaL_checknumber(L, 1);
        lua_Number y = luaL_checknumber(L, 2);        
        lua_Number w = luaL_checknumber(L, 3);                
        lua_Number h = w;
        
        if( n == 4 )
        {
            h = luaL_checknumber(L, 4);        
        }
        
        switch( renderAPI.ellipseMode )
        {
            case GraphicsStyle::SHAPE_MODE_CORNER:
                break;
            case GraphicsStyle::SHAPE_MODE_CORNERS:
            {
                //Ensure x,y are less than w,h                
                lua_Number t;
                if( x > w )
                {
                    t = x;
                    x = w;
                    w = t;
                }
                
                if( y > h )
                {
                    t = y;
                    y = h;
                    h = t;
                }
                
                w = w - x;
                h = h - y;
            }   break;
            case GraphicsStyle::SHAPE_MODE_CENTER:
                x = x - w*0.5f;
                y = y - h*0.5f;
                break;
            case GraphicsStyle::SHAPE_MODE_RADIUS:
                x = x - w;
                y = y - h;                
                w *= 2.0f;
                h *= 2.0f;
                break;                
        }        
        
        GLfloat ellipseUV[] = 
        {
            -1,  -1,
             1,  -1,
            -1,   1,
             1,   1,
        };                
        
        GLfloat ellipseVerts[] = 
        {
            x,   y,
            x+w, y,
            x,   y+h,
            x+w, y+h,
        };        
                
        [renderAPI setBlendMode:BLEND_MODE_PREMULT];        
        
        //Load uniforms into shader
        Shader *shader = nil;
        if( [renderAPI useStroke] )
        {
            shader = [renderAPI useShader:@"Circle"];        
        }
        else
        {
            shader = [renderAPI useShader:@"CircleNoStroke"];
        }
        
        [renderAPI setAttributeNamed:@"Vertex" withPointer:ellipseVerts size:2 andType:GL_FLOAT];
        [renderAPI setAttributeNamed:@"TexCoord" withPointer:ellipseUV size:2 andType:GL_FLOAT];        

        glUniform2f([shader uniformLocation:@"Radius"], w, h);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    return 0;
}

int text(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    //lua_Number x = 0;
    //lua_Number y = 0;
    const char *textStr = "";
    
    if( n >= 1 )    
    {
        textStr = luaL_checkstring(L, 1);
        
        //x = luaL_checknumber(L, 2);
        //y = luaL_checknumber(L, 3);
    }
    
    if( textStr )
    {
        CCTexture2D* texture = [renderAPI.textRenderer textureForString:[NSString stringWithUTF8String:textStr] 
                                                               withFont:[NSString stringWithUTF8String:renderAPI.fontName] 
                                                                   size:renderAPI.fontSize 
                                                              wrapWidth:renderAPI.textWrapWidth 
                                                              alignment:renderAPI.textAlign 
                                                           currentFrame:renderAPI.frameCount];
    
        [renderAPI setBlendMode:BLEND_MODE_PREMULT];    
        renderTextTexture(L, texture);
    }
    
    return 0;
}

int point(lua_State *L)
{
    int n = lua_gettop(L);
    
    if( n >= 2 )
    {
        lua_Number x = luaL_checknumber(L, 1);
        lua_Number y = luaL_checknumber(L, 2);        
        lua_Number w = *renderAPI.pointSize;
        lua_Number h = w;
        
        x = x - w*0.5f;
        y = y - h*0.5f;                
        
        GLfloat ellipseVerts[] = 
        {
            x,   y,
            x+w, y,
            x,   y+h,
            x+w, y+h,
        };        
        
        GLfloat ellipseUV[] = 
        {
            -1,  -1,
            1,  -1,
            -1,   1,
            1,   1,
        };
        
        //Load uniforms into shader    
        [renderAPI setBlendMode:BLEND_MODE_PREMULT];        
        
        Shader *shader = [renderAPI useShader:@"CircleNoStroke"];        
        
        [renderAPI setAttributeNamed:@"Vertex" withPointer:ellipseVerts size:2 andType:GL_FLOAT];
        [renderAPI setAttributeNamed:@"TexCoord" withPointer:ellipseUV size:2 andType:GL_FLOAT];        

        glUniform2f([shader uniformLocation:@"Radius"], w, h);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    return 0;

}

void drawLineCap(GLfloat x, GLfloat y, float strokeWidth)
{
    float radius = strokeWidth/2.f;
    GLfloat capUV[] = 
    {
        -1,  -1,
        1,  -1,
        -1,   1,
        1,   1,
    };                
    
    GLfloat capVerts[] = 
    {
        x-radius, y-radius,
        x+radius, y-radius,
        x-radius, y+radius,
        x+radius, y+radius,
    };        
    
    //Load uniforms into shader    
    Shader *shader = [renderAPI useShader:@"LineRoundCap"];        
    [renderAPI setAttributeNamed:@"Vertex" withPointer:capVerts size:2 andType:GL_FLOAT];
    [renderAPI setAttributeNamed:@"TexCoord" withPointer:capUV size:2 andType:GL_FLOAT];        
    
    glUniform1f([shader uniformLocation:@"Radius"], radius);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

int line(lua_State *L)
{
    
    int n = lua_gettop(L);
    
    if( n >= 4 )
    {
        lua_Number x1 = luaL_checknumber(L, 1);
        lua_Number y1 = luaL_checknumber(L, 2);        
        lua_Number x2 = luaL_checknumber(L, 3);
        lua_Number y2 = luaL_checknumber(L, 4); 
        
        float strokeWidth = *renderAPI.strokeWidth;
        if(renderAPI.smooth == NO) //do an no antialiased, simple line when its too thin
        {
            GLfloat linePoints[] =
            {
                x1, y1,
                x2, y2
            };
            
            [renderAPI setBlendMode:BLEND_MODE_PREMULT];            
            
            [renderAPI useShader:@"SimpleLine"];        
            [renderAPI setAttributeNamed:@"Vertex" withPointer:linePoints size:2 andType:GL_FLOAT];
            
            if( [SharedRenderer renderer].glView.contentScaleFactor == 2 )
            {
                //GL's line width is NOT scaled by contentScaleFactor. So we do it manually to ensure physical consistency in size.
                glLineWidth((*renderAPI.strokeWidth) * 2);
            }
            else 
            {
                glLineWidth(*renderAPI.strokeWidth);
            }
            

            glDrawArrays(GL_LINES, 0, 2);
        }
        else
        {
            CGPoint line = CGPointMake(x2-x1, y2-y1);
            float len = sqrtf(line.x*line.x+line.y*line.y);
            CGPoint perp = CGPointMake(-line.y, line.x);
            
            float perpFactor = strokeWidth*0.5f/len;
            perp.x *= perpFactor;
            perp.y *= perpFactor;
            
            GraphicsStyle::LineCapMode lineCapMode = renderAPI.lineCapMode;
            
            if(lineCapMode == GraphicsStyle::LINE_CAP_PROJECT) //just extend it out by half the stroke width on both ends
            {
                x1 -= perp.y;
                y1 += perp.x;
                
                x2 += perp.y;
                y2 -= perp.x;
            }
            
            GLfloat linePoints[] = 
            {
                x1-perp.x, y1-perp.y,
                x2-perp.x, y2-perp.y,
                x1+perp.x, y1+perp.y,
                x2+perp.x, y2+perp.y
            };
            
            GLfloat lineUV[] = 
            {
                -1,  -1,
                1,  -1,
                -1,   1,
                1,   1,
            }; 
            
            [renderAPI setBlendMode:BLEND_MODE_PREMULT];
            
            Shader* shader = [renderAPI useShader:@"Line"];
            [renderAPI setAttributeNamed:@"Vertex" withPointer:linePoints size:2 andType:GL_FLOAT];
            [renderAPI setAttributeNamed:@"TexCoord" withPointer:lineUV size:2 andType:GL_FLOAT];            
            
            glUniform2f([shader uniformLocation:@"Size"],len,strokeWidth);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            if(lineCapMode == GraphicsStyle::LINE_CAP_ROUND)
            {
                drawLineCap(x1,y1,strokeWidth);
                drawLineCap(x2,y2,strokeWidth);
            }
            
            
        }
        
    }
     
     
    return 0;

}

int drawMesh(struct lua_State *L)
{
    mesh_type* m2d = checkMesh(L, 1);
    if (m2d && m2d->valid)
    {
        //Load uniforms into shader    
        BOOL textured = (m2d->texture && m2d->texCoords.length > 0) || m2d->image;
        BOOL colored = (m2d->colors.length > 0);

        //Need to set blend mode before useShader for cache reasons
        if( textured && m2d->image )
        {
            //Use premult in images
            if( m2d->image->premultiplied )
            {
                [renderAPI setBlendMode:BLEND_MODE_PREMULT];                    
            }
            else
            {
                [renderAPI setBlendMode:BLEND_MODE_NORMAL];                                    
            }            
        }
        else if( textured )
        {
            [renderAPI setBlendMode:BLEND_MODE_PREMULT];                                
        }
        else
        {
            [renderAPI setBlendMode:BLEND_MODE_NORMAL]; 
        }
        
        NSString *shaderName = textured ? 
                                (colored ? @"Mesh2DTextured" : @"MeshFillColorTexture") : 
                                (colored ? @"Mesh2D" : @"MeshFillColor");
        Shader *shader = [renderAPI useShader:shaderName];        
        
        [renderAPI setAttributeNamed:@"Vertex" withPointer:m2d->vertices.buffer size:m2d->vertices.elementSize andType:GL_FLOAT];
        
        if (colored)
        {
            [renderAPI setAttributeNamed:@"Color" withPointer:m2d->colors.buffer size:m2d->colors.elementSize andType:GL_FLOAT];    
        }        
        
        if (textured)
        {
            [renderAPI setAttributeNamed:@"TexCoord" withPointer:m2d->texCoords.buffer size:m2d->texCoords.elementSize andType:GL_FLOAT];                    
            //Tell the shader the Tex Unit 0 is for ColorTexture
            glUniform1i([shader uniformLocation:@"ColorTexture"], 0);

            CCTexture2D* texture = nil;
            BOOL spriteMode = NO;            
            if (m2d->image)
            {                
                if (m2d->image->dataChanged || m2d->image->texture == nil)
                {                
                    updateImageTextureIfRequired(m2d->image);
                }

                texture = m2d->image->texture;                
            }
            else
            {
                texture = m2d->texture;
                spriteMode = YES;
            }            
            
            glUniform1i([shader uniformLocation:@"SpriteMode"], spriteMode);
            
            //Set filtering            
            if( renderAPI.smooth )
            {
                [texture setAntiAliasTexParameters];        
            }
            else
            {
                [texture setAliasTexParameters];       
            }            

            //Bind sprite texture to tex unit 0
            [renderAPI setActiveTexture:GL_TEXTURE0];
            [renderAPI useTexture:texture.name];
            //glBindTexture(GL_TEXTURE_2D, texture.name);
        }
        
        glDrawArrays(GL_TRIANGLES, 0, m2d->vertices.length);            
    }
    
    return 1;
}

int setContext(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    if( n == 0 )
    {
        //Set context to framebuffer
        [renderAPI setFramebuffer:NULL];
    }
    else
    {
        //Set context to passed image
        image_type* image = checkimage(L, 1);
        if (image != NULL) 
        {
            [renderAPI setFramebuffer:image];
        }
    }
    
    return 0;
}

int pushMatrix(lua_State *L)
{
    [renderAPI pushMatrix];
    return 0;    
}
int popMatrix(lua_State *L)
{
    [renderAPI popMatrix];
    return 0;    
}

int resetMatrix(struct lua_State *L)
{
    [renderAPI resetMatrix];
    return 0;
}

int pushStyle(struct lua_State *L)
{
    [renderAPI pushStyle];
    return 0;
}

int popStyle(struct lua_State *L)
{
    [renderAPI popStyle];
    return 0;    
}

int resetStyle(struct lua_State *L)
{
    [renderAPI resetStyle];
    return 0;    
}

int zLevel(struct lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number z = 0;
    
    if( n >= 1 )
    {
        z = luaL_checknumber(L, 1);
    }
    
    [renderAPI translateModel:0 y:0 z:z];
    
    return 0;
}

int translate(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number x = 0, y = 0, z = 0;
    
    switch(n)
    {
        case 3:
            z = luaL_checknumber(L, 3);
        case 2:
            x = luaL_checknumber(L, 1);            
            y = luaL_checknumber(L, 2);            
            break;
    }
    
    [renderAPI translateModel:x y:y z:z];
    
    return 0;    
}

int rotate(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number r = 0;
    lua_Number x = 0,y = 0,z = 1;
    switch(n)
    {
        case 4:            
            x = luaL_checknumber(L, 2);      
            y = luaL_checknumber(L, 3);      
            z = luaL_checknumber(L, 4);      
        case 1:
            r = luaL_checknumber(L, 1);                        
            break;
    }
    
    [renderAPI rotateModel:r x:x y:y z:z];
    
    return 0;    
}

int scale(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number x = 1, y = 1, z = 1;
    
    switch(n)
    {
        case 3:
            z = luaL_checknumber(L, 3);
        case 2:
            x = luaL_checknumber(L, 1);            
            y = luaL_checknumber(L, 2);                  
            break;
        case 1:
            x = luaL_checknumber(L, 1);            
            y = x;
            break;
    }
    
    [renderAPI scaleModel:x y:y z:z];
    
    return 0;    
}

int clip(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n == 4)
    {
        [renderAPI scissorTestX:luaL_checkinteger(L, 1) 
                              y:luaL_checkinteger(L, 2) 
                          width:luaL_checkinteger(L, 3) 
                         height:luaL_checkinteger(L, 4)];        
    }
    else if( n == 0 )
    {
        [renderAPI noScissorTest];
    }
    return 0;
}

int noClip(struct lua_State *L)
{
    [renderAPI noScissorTest];
    return 0;
}

#pragma mark - Utils

int triangulate(struct lua_State *L)
{
    static float trX[256];
    static float trY[256];
    static b2Triangle triangles[256];
    
    if (lua_istable(L, 1))
    {
        int n = luaL_getn(L, 1);
        for (int i = 1; i <= n; i++)
        {
            lua_rawgeti(L, 1, i);
            lua_Number* v = checkvec2(L, -1);
            trX[i-1] = v[0];
            trY[i-1] = v[1];
            lua_pop(L, 1);            
        }
        
//        if (!polygon.IsCCW())
//        {
//            ReversePolygon(polygon.x, polygon.y, polygon.nVertices);
//        }
        
        int triCount = TriangulatePolygon(trX, trY, n, triangles);
        if (triCount > 0)
        {
            lua_createtable(L, triCount*3, 0);
            int count = 1;
            for (int i = 1; i <= triCount; i++)
            {
                pushvec2(L, triangles[i-1].x[0], triangles[i-1].y[0]);
                lua_rawseti(L, -2, count++);
                pushvec2(L, triangles[i-1].x[1], triangles[i-1].y[1]);
                lua_rawseti(L, -2, count++);
                pushvec2(L, triangles[i-1].x[2], triangles[i-1].y[2]);
                lua_rawseti(L, -2, count++);
            }  
            return 1;
        }
    }
    return 0;
}

