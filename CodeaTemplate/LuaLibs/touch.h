//
//  touch.h
//  Codea
//
//  Created by Simeon Nasilowski on 25/09/11.
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

#ifndef Codify_touch_h
#define Codify_touch_h

#include "lua.h"

#define CODIFY_TOUCHLIBNAME "touch"

typedef enum touch_state
{
    TOUCH_STATE_BEGAN=0,
    TOUCH_STATE_MOVING,
    TOUCH_STATE_ENDED,
    TOUCH_STATE_INACTIVE,    
    TOUCH_STATE_STATIONARY,

} touch_state;

typedef struct touch_type
{
    unsigned int ID;
    
    lua_Number x;
    lua_Number y;
    lua_Number prevX;
    lua_Number prevY;
    lua_Number deltaX;
    lua_Number deltaY;
    
    unsigned int state;
    unsigned int tapCount;
} touch_type;

LUALIB_API int (luaopen_touch) (lua_State *L);

void setupEmptyTouch(touch_type* t);

#endif
