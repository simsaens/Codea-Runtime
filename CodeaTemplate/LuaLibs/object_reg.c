//
//  object_reg.c
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

#include "object_reg.h"
#include <stdio.h>


////////////////////////////////////////////////
// Object registry
static char* obj_registry = "ev{obj}";

/**
 * Create a "registry" of light userdata pointers into the
 * fulluserdata so that we can get handles into the lua objects.
 */
void create_obj_registry(lua_State *L) {
    lua_pushlightuserdata(L, &obj_registry);
    lua_newtable(L);
    
    lua_createtable(L,  0, 1);
    lua_pushstring(L,   "v");
    lua_setfield(L,     -2, "__mode");
    lua_setmetatable(L, -2);
    
    lua_rawset(L, LUA_REGISTRYINDEX);
}

/**
 * Register the lua object at index obj_i so it is keyed off of the
 * obj pointer.
 *
 * [-0, +0, ?]
 */
void register_obj(lua_State*L, int obj_i, void* obj) {
    obj_i = abs_index(L, obj_i);
    
    lua_pushlightuserdata(L, &obj_registry);
    lua_rawget(L,            LUA_REGISTRYINDEX);
//    assert(lua_istable(L, -1) /* create_obj_registry() should have ran */);
    
    lua_pushlightuserdata(L, obj);
    lua_pushvalue(L,         obj_i);
    lua_rawset(L,            -3);
    lua_pop(L,               1);
}

int push_obj(lua_State* L, void* obj) 
{
    lua_pushlightuserdata(L, &obj_registry);
    lua_rawget(L,            LUA_REGISTRYINDEX);
    
    int registry_i = lua_gettop(L);    
    lua_pushlightuserdata(L, obj);
    lua_rawget(L, registry_i);    
    
    // remove registry table from stack
    lua_remove(L, registry_i);
    
    return 1;
}

void unregister_obj(lua_State* L, void* obj) 
{
    lua_pushlightuserdata(L, &obj_registry);
    lua_rawget(L,            LUA_REGISTRYINDEX);

    int registry_i = lua_gettop(L);    
    lua_pushlightuserdata(L, obj);
    lua_pushnil(L);
    lua_rawset(L, registry_i);
    
    lua_remove(L, registry_i);
}

int isudatatype (lua_State *L, int ud, const char *tname) 
{
    void *p = lua_touserdata(L, ud);
    if (p != NULL) {  /* value is a userdata? */
        if (lua_getmetatable(L, ud)) {  /* does it have a metatable? */
            lua_getfield(L, LUA_REGISTRYINDEX, tname);  /* get correct metatable */
            if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
                lua_pop(L, 2);  /* remove both metatables */
                return 1;
            }
        }
    }
    return 0;
}


//``````````````````````````````````````````````
