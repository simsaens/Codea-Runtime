//
//  body.h
//  Codea
//
//  Created by John Millard on 9/11/11.
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

#ifndef Codify_body_h
#define Codify_body_h

#ifdef __cplusplus
extern "C" {
#endif 
    
#import "LuaState.h"           
#include "lua.h"
#include "lauxlib.h"    
#include "object_reg.h"
#include "vec2.h"
 
#define CODIFY_RIGIDBODY_LIBNAME "rigidbody"    
LUALIB_API int (luaopen_rigidbody) (lua_State *L);

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)    
    
#ifdef __cplusplus
}
#endif 

struct b2Body;
typedef struct b2Body b2Body;

typedef enum rigidbody_shape_type
{
    RIGIDBODY_CIRCLE = 0,
    RIGIDBODY_EDGE = 1,
    RIGIDBODY_POLYGON = 2,
    RIGIDBODY_CHAIN = 3,
    RIGIDBODY_COMPOUND = 4
} rigidbody_shape_type;

typedef struct body_wrapper_type
{    
    b2Body* body;
    rigidbody_shape_type type;
        
    // Options 
//    int infoRef;
    int interpolate;
    
    // Compound stuff
    struct body_wrapper_type* parent;
    struct body_wrapper_type** children;
    int childCount;    
    
    // Polygon info
    int pointCount;
    float* x;
    float* y;
    
    // Render interpolation
    float prevX;
    float prevY;
    float prevAngle;
    float renderX;
    float renderY;
    float renderAngle;
    
    
} body_wrapper_type;

#endif    