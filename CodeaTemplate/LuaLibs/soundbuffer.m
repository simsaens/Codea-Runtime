//
//  soundbuffer.c
//  Codea
//
//  Created by Dylan Sale on 5/02/12.
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
#include "soundbuffer.h"

#import "ALBuffer.h"

#define SOUNDBUFFERTYPE "codeasoundbuffer"
#define SOUNDBUFFERSIZE sizeof(soundbuffer_type)

static ALBuffer* newBuffer(const char* data, size_t len, ALenum format, ALsizei freq)
{
    return [ALBuffer bufferWithName:nil data:(void*)data size:len format:format frequency:freq];
}

static void deallocData(soundbuffer_type* v)
{
    [v->buffer release];
    v->buffer = nil;
}

static soundbuffer_type* Pget( lua_State *L, int i )
{
    if (luaL_checkudata(L,i,SOUNDBUFFERTYPE)==NULL) luaL_typerror(L,i,SOUNDBUFFERTYPE);
    return lua_touserdata(L,i);
}

soundbuffer_type* tosoundbuffer(lua_State* L, int i)
{
    return (soundbuffer_type*)luaL_checkudata(L,i,SOUNDBUFFERTYPE);
}

soundbuffer_type* check_soundbuffer(lua_State *L, int i)
{
    return Pget(L, i);
}

static soundbuffer_type* Pnew( lua_State *L )
{
    soundbuffer_type *v=lua_newuserdata(L,SOUNDBUFFERSIZE);
    luaL_getmetatable(L,SOUNDBUFFERTYPE);
    lua_setmetatable(L,-2);
    return v;
}

static int Lnew( lua_State *L )
{
    soundbuffer_type *v = Pnew(L);
    
    if (lua_gettop(L) == 0) 
    {
        luaL_error(L, "soundbuffer requires data as the first parameter");
        return 0;
    }
    
    lua_Integer format = luaL_optinteger(L, 2, AL_FORMAT_MONO8);
    lua_Integer frequency = luaL_optinteger(L, 3, 44100);
    
    size_t dataLen;
    void* data = (void*)luaL_checklstring(L, 1, &dataLen);
    
    void* dataCpy = malloc(dataLen);
    memcpy(dataCpy, data, dataLen);
    
    v->buffer = [[ALBuffer bufferWithName:nil data:dataCpy size:dataLen format:format frequency:frequency] retain];
    
    return 1;
}


static int Lget( lua_State *L )
{
    soundbuffer_type *v=Pget(L,1);
    const char* c = luaL_checkstring(L,2);
    
    if( strcmp(c, "format") == 0 )
    {
        lua_pushnumber(L, [v->buffer format]);
    }
    else if( strcmp(c, "frequency") == 0 )
    {
        lua_pushnumber(L, [v->buffer frequency]);        
    }
    else if( strcmp(c, "channels") == 0 )
    {
        lua_pushnumber(L, [v->buffer channels]);        
    }
    else if( strcmp(c, "duration") == 0 )
    {
        lua_pushnumber(L, [v->buffer duration]);        
    }
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, SOUNDBUFFERTYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);
    }
    
    return 1;
}

static int Lgc( lua_State *L)
{
    soundbuffer_type *v=Pget(L,1);
    deallocData(v);
    return 0;
}

static int Ltostring(lua_State *L)
{
    soundbuffer_type *v = Pget(L,1);
    lua_pushfstring(L,"Soundbuffer: format = %d, frequency = %d, size = %d", v->buffer.format, v->buffer.frequency, v->buffer.size);
    return 1;
}

static const luaL_reg R[] =
{
    { "__index", Lget },
    //{ "__newindex",	Lset		},
    { "__tostring", Ltostring },
    { "__gc", Lgc },
    { NULL, NULL }
};

LUALIB_API int luaopen_soundbuffer(lua_State *L)
{
    luaL_newmetatable(L,SOUNDBUFFERTYPE);
    
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);   // pushes the metatable
    lua_settable(L, -3);    // metatable.__index = metatable
    
    luaL_register(L, NULL, R);
    
    lua_register(L,"soundbuffer",Lnew);
    
    return 1;
}

