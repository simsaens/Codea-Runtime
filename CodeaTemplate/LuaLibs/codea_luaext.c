//
//  codea_luaext.c
//  Codea
//
//  Created by Simeon Nasilowski on 8/03/12.
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

#include "lua.h"
#include "lauxlib.h"

void *testudata (lua_State *L, int ud, const char *tname) 
{
    void *p = lua_touserdata(L, ud);
    if (p != NULL) {  /* value is a userdata? */
        if (lua_getmetatable(L, ud)) {  /* does it have a metatable? */
            lua_getfield(L, LUA_REGISTRYINDEX, tname);  /* get correct metatable */
            if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
                lua_pop(L, 2);  /* remove both metatables */
                return p;
            }
        }
    }
    return NULL;  /* to avoid warnings */
}