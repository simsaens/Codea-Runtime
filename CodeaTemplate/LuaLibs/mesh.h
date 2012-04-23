//
//  mesh2d.h
//  Codea
//
//  Created by John Millard on 6/01/12.
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

#ifndef Codify_mesh2d_h
#define Codify_mesh2d_h

#include "lua.h"
#import "CCTexture2D.h"
#import "image.h"

#define CODIFY_MESH_LIBNAME "mesh"

typedef struct float_buffer_t
{
    GLfloat* buffer;
    int length;
    int capacity;
    size_t elementSize;
} float_buffer;

typedef struct mesh_type_t
{    
//    GLfloat* vertices;
//    int nVertices;
//        
//    GLfloat* texCoords;
//    int nTexCoords;
//    
//    GLfloat* colors;
//    int nColors;
//    
//    GLint* triangles;
//    int nTriangles;

    float_buffer vertices;
    float_buffer colors;
    float_buffer texCoords;
//    float_buffer texCoordsReversed;
    
    BOOL valid;
    
    NSString* spriteName;
    CCTexture2D* texture;
    image_type* image;
    int imageRef;
    
} mesh_type;

LUALIB_API int (luaopen_mesh) (lua_State *L);
mesh_type *checkMesh(lua_State *L, int i);

//Creates the userdata and puts it on the stack, and returns the same userdata
mesh_type* createMesh(lua_State *L);

#endif
