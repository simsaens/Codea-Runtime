//
//  touch.c
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

#include <stdio.h>
#include <string.h>

#include "touch.h"
#include "lauxlib.h"

#define TOUCHTYPE		"touch"
#define TOUCHSIZE      sizeof(touch_type)

void setupEmptyTouch(touch_type* t)
{
    t->x = 0;
    t->y = 0;
    t->prevX = 0;
    t->prevY = 0;
    t->deltaX = 0;
    t->deltaY = 0;
    t->ID = 0;
    t->state = TOUCH_STATE_INACTIVE;
    t->tapCount = 0;
}

static touch_type* Pget( lua_State *L, int i )
{
    if (luaL_checkudata(L,i,TOUCHTYPE)==NULL) luaL_typerror(L,i,TOUCHTYPE);
    return lua_touserdata(L,i);
}

static touch_type* Pnew( lua_State *L )
{
    touch_type *v=lua_newuserdata(L,TOUCHSIZE);
    luaL_getmetatable(L,TOUCHTYPE);
    lua_setmetatable(L,-2);
    return v;
}

static int Lget( lua_State *L )
{
    touch_type *v=Pget(L,1);
    const char* c = luaL_checkstring(L,2);

    if( strcmp(c, "x") == 0 )
    {
        lua_pushnumber(L, v->x);
    }
    else if( strcmp(c, "y") == 0 )
    {
        lua_pushnumber(L, v->y);        
    }
    else if( strcmp(c, "prevX") == 0 )
    {
        lua_pushnumber(L, v->prevX);        
    }
    else if( strcmp(c, "prevY") == 0 )
    {
        lua_pushnumber(L, v->prevY);        
    }    
    else if( strcmp(c, "deltaX") == 0 )
    {
        lua_pushnumber(L, v->deltaX);        
    }            
    else if( strcmp(c, "deltaY") == 0 )
    {
        lua_pushnumber(L, v->deltaY);        
    }            
    else if( strcmp(c, "id") == 0 )
    {
        lua_pushnumber(L, v->ID);        
    }    
    else if( strcmp(c, "state") == 0 )
    {
        lua_pushnumber(L, v->state);        
    }    
    else if( strcmp(c, "tapCount") == 0 )
    {
        lua_pushnumber(L, v->tapCount);        
    }    
    else
    {
        lua_pushnil(L);
    }
    
    return 1;
}

static int Ltostring(lua_State *L)
{
    touch_type *v=Pget(L,1);
    char s[128];
    sprintf(s,"Touch\n\tx:%f, y:%f\n\tprevX:%f, prevY:%f\n\tid:%d\n\tstate:%d\n\ttapCount:%d", 
               v->x, v->y, v->prevX, v->prevY, (int)v->ID, (int)v->state, (int)v->tapCount);
    lua_pushstring(L,s);
    return 1;
}

static const luaL_reg R[] =
{
    { "__index", Lget },
    { "__tostring", Ltostring },
    { NULL, NULL }
};

LUALIB_API int luaopen_touch(lua_State *L)
{
    luaL_newmetatable(L,TOUCHTYPE);
    luaL_openlib(L,NULL,R,0);
    return 1;
}
