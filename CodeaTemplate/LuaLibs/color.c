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
#include <string.h>

#include "color.h"
#include "lua.h"
#include "lauxlib.h"

#if !defined(MIN)
    #define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

#if !defined(MAX)
    #define MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

#define COLORTYPE	"color"
#define COLDIM      4
#define COLCLAMP(x) MAX(MIN((x),255),0)

color_type *checkcolor(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        color_type *v = luaL_checkudata(L,i,COLORTYPE);
        
        luaL_argcheck(L, v != NULL, 1, "`color' expected");
        
        return v;
    }
    
    return NULL;
}

static color_type *Pget(lua_State *L, int i)
{
    if (luaL_checkudata(L,i,COLORTYPE)==NULL) luaL_typerror(L,i,COLORTYPE);
    return lua_touserdata(L,i);
}

static color_type *Pnew(lua_State *L)
{
    color_type *v=lua_newuserdata(L,sizeof(color_type)/*COLDIM*sizeof(lua_Number)*/);
    luaL_getmetatable(L,COLORTYPE);
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
    
    if( strlen(i) == 1 )
    {
        switch (*i)
        {		/* lazy! */
            case '1': case 'x': case 'r': lua_pushnumber(L,v->r); break;
            case '2': case 'y': case 'g': lua_pushnumber(L,v->g); break;
            case '3': case 'z': case 'b': lua_pushnumber(L,v->b); break;
            case '4': case 'w': case 'a': lua_pushnumber(L,v->a); break;         
            default: 
            {
                //Load the metatable and value for key
                luaL_getmetatable(L, COLORTYPE);
                lua_pushstring(L, i);
                lua_gettable(L, -2);
            } break;
        }
    }
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, COLORTYPE);
        lua_pushstring(L, i);
        lua_gettable(L, -2);
    }
    
    return 1;
}

static int Lset(lua_State *L) 
{
    color_type *v=Pget(L,1);
    const char* i=luaL_checkstring(L,2);
    lua_Number t=luaL_checknumber(L,3);
    switch (*i) 
    {		/* lazy! */
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

static int Lmul(lua_State *L)
{
    color_type *o1 = checkcolor(L, 1);
    color_type *o2 = checkcolor(L, 2);
    
    if( o1 && o2 )
    {
        pushcolor(L,
                  COLCLAMP( (o1->r * o2->r)/255.0f ), 
                  COLCLAMP( (o1->g * o2->g)/255.0f ), 
                  COLCLAMP( (o1->b * o2->b)/255.0f ), 
                  COLCLAMP( (o1->a + o2->a) ));        
        
        return 1;
    }
    
    return 0;
}

static int Ladd(lua_State *L)
{
    color_type *o1 = checkcolor(L, 1);
    color_type *o2 = checkcolor(L, 2);
    
    if( o1 && o2 )
    {
        pushcolor(L,
                  COLCLAMP( o1->r + o2->r ), 
                  COLCLAMP( o1->g + o2->g ), 
                  COLCLAMP( o1->b + o2->b ), 
                  COLCLAMP( o1->a + o2->a ));        
        
        return 1;
    }
    
    return 0;
}

static int Leq(lua_State *L)
{
    color_type *o1 = checkcolor(L, 1);
    color_type *o2 = checkcolor(L, 2);
    
    if( o1 && o2 )
    {
        if( o1->r == o2->r && 
            o1->g == o2->g && 
            o1->b == o2->b &&
            o1->a == o2->a )
        {
            lua_pushboolean(L, 1);
        }
        else
        {
            lua_pushboolean(L, 0);
        }
        
        return 1;
    }
    
    return 0;
}

static int Lblend(lua_State *L)
{
    color_type *o1 = checkcolor(L, 1);
    color_type *o2 = checkcolor(L, 2);
        
    if( o1 && o2 )
    {
        lua_Number alpha = o1->a / 255.0f;
        lua_Number inv = 1 - alpha;
        
        pushcolor(L, 
                  COLCLAMP( o1->r * alpha + o2->r * inv ), 
                  COLCLAMP( o1->g * alpha + o2->g * inv ), 
                  COLCLAMP( o1->b * alpha + o2->b * inv ), 
                  COLCLAMP( o1->a + o2->a ));
        
        return 1;
    }
    
    return 0;
}

static int Llerp(lua_State *L)
{
    color_type *o1 = checkcolor(L, 1);
    color_type *o2 = checkcolor(L, 2);
    lua_Number t = luaL_checknumber(L,3);
    
    if( o1 && o2 )
    {
        lua_Number invt = 1 - t;
        
        pushcolor(L, 
                  COLCLAMP( o1->r * t + o2->r * invt ), 
                  COLCLAMP( o1->g * t + o2->g * invt ), 
                  COLCLAMP( o1->b * t + o2->b * invt ), 
                  COLCLAMP( o1->a * t + o2->a * invt ));
        
        return 1;
    }
    
    return 0;
}

static const luaL_reg R[] =
{
	{ "__index",	Lget		},
	{ "__newindex",	Lset		},
	{ "__tostring",	Ltostring	},
    { "__add",      Ladd        }, 
    { "__mul",      Lmul        },    
    { "__eq",       Leq         },     
    { "blend",      Lblend      },
    { "mix",        Llerp       },    
	{ NULL,         NULL		}
};

LUALIB_API int luaopen_color(lua_State *L)
{
    luaL_newmetatable(L,COLORTYPE);

    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);
    lua_settable(L, -3);
    
    luaL_register(L, NULL, R);
    lua_register(L,"color",Lnew);
    
    return 1;
}
