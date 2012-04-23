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

/*
* lv3.c
* 3d vectors for Lua 5.0
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 03 Dec 2004 11:29:50
* This code is hereby placed in the public domain.
*/

#include <stdio.h>

#include "color.h"
#include "lua.h"
#include "lauxlib.h"

#define MYTYPE		"color"
#define COLDIM      4

color_type *checkcolor(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        color_type *v = luaL_checkudata(L,i,MYTYPE);
        
        luaL_argcheck(L, v != NULL, 1, "`color' expected");
        
        return v;
    }
    
    return NULL;
}

static color_type *Pget(lua_State *L, int i)
{
 if (luaL_checkudata(L,i,MYTYPE)==NULL) luaL_typerror(L,i,MYTYPE);
 return lua_touserdata(L,i);
}

static color_type *Pnew(lua_State *L)
{
 color_type *v=lua_newuserdata(L,sizeof(color_type)/*COLDIM*sizeof(lua_Number)*/);
 luaL_getmetatable(L,MYTYPE);
 lua_setmetatable(L,-2);
 return v;
}

color_type* pushcolor(lua_State *L, lua_Number r, lua_Number g, lua_Number b, lua_Number a)
{
    color_type* v = Pnew(L);
    v->r = r;
    v->g = g;
    v->b = b;
    v->a = a;
    
    return v;
}

static int Lnew(lua_State *L)			/** color(r, g, b, a) */
{
 color_type *v;
 lua_settop(L,COLDIM);
 v=Pnew(L);
 v->r=luaL_optnumber(L,1,0);
 v->g=luaL_optnumber(L,2,0);
 v->b=luaL_optnumber(L,3,0);
 v->a=luaL_optnumber(L,4,255);    
 return 1;
}

static int Lget(lua_State *L)
{
 color_type *v=Pget(L,1);
 const char* i=luaL_checkstring(L,2);
 switch (*i) {		/* lazy! */
  case '1': case 'x': case 'r': lua_pushnumber(L,v->r); break;
  case '2': case 'y': case 'g': lua_pushnumber(L,v->g); break;
  case '3': case 'z': case 'b': lua_pushnumber(L,v->b); break;
  case '4': case 'w': case 'a': lua_pushnumber(L,v->a); break;         
  default: lua_pushnil(L); break;
 }
 return 1;
}

static int Lset(lua_State *L) {
 color_type *v=Pget(L,1);
 const char* i=luaL_checkstring(L,2);
 lua_Number t=luaL_checknumber(L,3);
 switch (*i) {		/* lazy! */
  case '1': case 'x': case 'r': v->r = t; break;
  case '2': case 'y': case 'g': v->g = t; break;
  case '3': case 'z': case 'b': v->b = t; break;
  case '4': case 'w': case 'a': v->a = t; break;         
  default: break;
 }
 return 1;
}

static int Ltostring(lua_State *L)
{
 color_type *v=Pget(L,1);
 char s[64];
 sprintf(s,"(%d, %d, %d, %d)",(int)v->r,(int)v->g,(int)v->b,(int)v->a);
 lua_pushstring(L,s);
 return 1;
}

static const luaL_reg R[] =
{
	{ "__index",	Lget		},
	{ "__newindex",	Lset		},
	{ "__tostring",	Ltostring	},
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_color(lua_State *L)
{
 luaL_newmetatable(L,MYTYPE);
 luaL_openlib(L,NULL,R,0);
 lua_register(L,"color",Lnew);
 return 1;
}
