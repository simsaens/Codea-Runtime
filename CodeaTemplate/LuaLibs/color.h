//
//  color.h
//  Codea
//
//  Created by Simeon Nasilowski on 20/09/11.
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

#ifndef Codify_color_h
#define Codify_color_h

#include "lua.h"

#define CODIFY_COLORLIBNAME "color"

typedef struct color_type_t
{
    lua_Number r,g,b,a;
} color_type;

LUALIB_API int (luaopen_color) (lua_State *L);
color_type *checkcolor(lua_State *L, int i);

//Creates the userdata and puts it on the stack, and returns the same userdata
color_type* pushcolor(lua_State *L, lua_Number r, lua_Number g, lua_Number b, lua_Number a);

#endif
