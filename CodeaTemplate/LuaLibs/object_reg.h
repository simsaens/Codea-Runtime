//
//  object_reg.h
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

// The following code is based on this: https://github.com/brimworks/lua-ev/blob/master/obj_lua_ev.c by Brian Maher

#ifndef Codify_object_reg_h
#define Codify_object_reg_h

#include "lua.h"

/**
 * Copied from the lua source code lauxlib.c.  It simply converts a
 * negative stack index into a positive one so that if the stack later
 * grows or shrinks, the index will not be effected.
 */
#define abs_index(L, i)                    \
((i) > 0 || (i) <= LUA_REGISTRYINDEX ? \
(i) : lua_gettop(L) + (i) + 1)

void create_obj_registry(lua_State *L);
void register_obj(lua_State*L, int obj_i, void* obj);
int push_obj(lua_State* L, void* obj);
void unregister_obj(lua_State* L, void* obj);
int isudatatype (lua_State *L, int ud, const char *tname);

#endif
