//
//  vec4.c
//  Codea
//
//  Created by Simeon Nasilowski on 26/09/11.
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

#include "vec4.h"
#include "lua.h"
#include "lauxlib.h"
#include "math.h"
#include "matrix44.h"
#include "codea_luaext.h"

#define VEC4TYPE    "vec4"
#define VEC4DIM     4

#define MATHF(c)    c##f

lua_Number *getvec4(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        return testudata(L, i, VEC4TYPE);
    }
    
    return NULL;
}

lua_Number *checkvec4(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        lua_Number *v = luaL_checkudata(L,i,VEC4TYPE);
        
        luaL_argcheck(L, v != NULL, 1, "`vec4' expected");
        
        return v;
    }
    
    return NULL;
}

static lua_Number *Pget(lua_State *L, int i)
{
    if (luaL_checkudata(L,i,VEC4TYPE)==NULL) luaL_typerror(L,i,VEC4TYPE);
    return lua_touserdata(L,i);
}

static lua_Number *Pnew(lua_State *L)
{
    lua_Number *v=lua_newuserdata(L,VEC4DIM*sizeof(lua_Number));
    luaL_getmetatable(L,VEC4TYPE);
    lua_setmetatable(L,-2);
    return v;
}

void pushvec4(lua_State *L, lua_Number x, lua_Number y, lua_Number z, lua_Number w)
{
    lua_Number *v=Pnew(L);
    v[0]=x;
    v[1]=y;
    v[2]=z;
    v[3]=w;
    //return 1;
}

static int Lnew(lua_State *L)			/** vec3(x, y, z, w) */
{
    lua_Number *v;
    lua_settop(L,VEC4DIM);
    v=Pnew(L);
    v[0]=luaL_optnumber(L,1,0);
    v[1]=luaL_optnumber(L,2,0);
    v[2]=luaL_optnumber(L,3,0); 
    v[3]=luaL_optnumber(L,4,1);
    return 1;
}

static int Lget(lua_State *L)
{
    lua_Number *v=Pget(L,1);
    const char* i=luaL_checkstring(L,2);
    switch (*i) {		/* lazy! */
        case '1': case 'x': case 'r': lua_pushnumber(L,v[0]); break;
        case '2': case 'y': case 'g': lua_pushnumber(L,v[1]); break;
        case '3': case 'z': case 'b': lua_pushnumber(L,v[2]); break;
        case '4': case 'w': case 'a': lua_pushnumber(L,v[3]); break;            
        default: 
        {
            //Load the metatable and value for key
            luaL_getmetatable(L, VEC4TYPE);
            lua_pushstring(L, i);
            lua_gettable(L, -2);
        } break;
    }
    return 1;
}

static int Lset(lua_State *L) 
{
    lua_Number *v=Pget(L,1);
    const char* i=luaL_checkstring(L,2);
    lua_Number t=luaL_checknumber(L,3);
    switch (*i) {		/* lazy! */
        case '1': case 'x': case 'r': v[0]=t; break;
        case '2': case 'y': case 'g': v[1]=t; break;
        case '3': case 'z': case 'b': v[2]=t; break;
        case '4': case 'w': case 'a': v[3]=t; break;            
        default: break;
    }
    return 1;
}

static int Ltostring(lua_State *L)
{
    lua_Number *v=Pget(L,1);
    char s[64];
    sprintf(s,"(%f, %f, %f, %f)",v[0],v[1],v[2],v[3]);
    lua_pushstring(L,s);
    return 1;
}

static int Ladd(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, -1);
    lua_Number *o2 = checkvec4(L, -2);
    
    if( o1 && o2 )
    {
        lua_Number *r = Pnew(L);
        r[0] = o1[0] + o2[0];
        r[1] = o1[1] + o2[1]; 
        r[2] = o1[2] + o2[2];
        r[3] = o1[3] + o2[3];
        
        return 1;
    }
    
    return 0;
}

static int Lmul(lua_State *L)
{
    lua_Number n, *v = NULL;
    
    if( lua_isnumber(L, -1) )
    {
        v = checkvec4(L, -2);
        n = luaL_checknumber(L, -1);
    }
    else if( lua_isnumber(L, -2) )
    {
        v = checkvec4(L, -1);        
        n = luaL_checknumber(L, -2);        
    }
    
    luaL_argcheck(L, v != NULL, 1, "`vec4' expected");    
    
    lua_Number *r = Pnew(L);
    r[0] = v[0] * n;
    r[1] = v[1] * n;
    r[2] = v[2] * n;
    r[3] = v[3] * n;
    
    return 1;
}

static int Ldiv(lua_State *L)
{
    lua_Number n, *v = NULL;
    
    v = checkvec4(L, 1);
    n = luaL_checknumber(L, 2);
    
    luaL_argcheck(L, v != NULL, 1, "`vec4' expected");    
    
    lua_Number *r = Pnew(L);
    r[0] = v[0] / n;
    r[1] = v[1] / n;
    r[2] = v[2] / n;
    r[3] = v[3] / n;
    
    return 1;
}

static int Lsub(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, 1);
    lua_Number *o2 = checkvec4(L, 2);
    
    if( o1 && o2 )
    {    
        lua_Number *r = Pnew(L);
        r[0] = o1[0] - o2[0];
        r[1] = o1[1] - o2[1]; 
        r[2] = o1[2] - o2[2];
        r[3] = o1[3] - o2[3];
        
        return 1;    
    }
    
    return 0;
}

static int Lunm(lua_State *L)   /** Unary negation */
{
    lua_Number *o1 = checkvec4(L, -1);
    
    if( o1 )
    {
        lua_Number *r = Pnew(L);
        r[0] = -o1[0];
        r[1] = -o1[1];
        r[2] = -o1[2];
        r[3] = -o1[3];
        
        return 1;            
    }
    
    return 0;
}

static int Leq(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, -1);
    lua_Number *o2 = checkvec4(L, -2);
    
    if( o1 && o2 )
    {
        if( o1[0] == o2[0] && 
            o1[1] == o2[1] && 
            o1[2] == o2[2] &&
            o1[3] == o2[3] )
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

static int Llen(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, -1);
    
    if( o1 )
    {
        lua_pushnumber( L, MATHF(sqrt)(o1[0]*o1[0] + o1[1]*o1[1] + o1[2]*o1[2] + o1[3]*o1[3]) );
        
        return 1;        
    }
    
    return 0;
}

static int LlenSqr(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, -1);
    
    if( o1 )
    {
        lua_pushnumber( L, o1[0]*o1[0] + o1[1]*o1[1] + o1[2]*o1[2] + o1[3]*o1[3] );
        
        return 1;        
    }
    
    return 0;
}

static int Lnormalize(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, -1);
    
    if( o1 )
    {    
        lua_Number len = MATHF(sqrt)(o1[0]*o1[0] + o1[1]*o1[1] + o1[2]*o1[2] + o1[3]*o1[3]);
        
        lua_Number *r = Pnew(L);
        r[0] = o1[0] / len;
        r[1] = o1[1] / len;  
        r[2] = o1[2] / len;
        r[3] = o1[3] / len;
        
        return 1;        
    }
    
    return 0;
}

static int Ldot(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, 1);
    lua_Number *o2 = checkvec4(L, 2);
    
    if( o1 && o2 )
    {
        lua_pushnumber(L, o1[0]*o2[0] + o1[1]*o2[1] + o1[2]*o2[2] + o1[3]*o2[3]);    
        
        return 1;        
    }
    
    return 0;
}

//TODO: This does 3D cross product - remove it?
static int Lcross(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, 1);
    lua_Number *o2 = checkvec4(L, 2);
    
    if( o1 && o2 )
    {
        lua_Number *r = Pnew(L);
        
        // y1*z2 - y2*z1 , z1*x2 - z2*x1 , x1*y2 - x2*y1        
        r[0] = o1[1]*o2[2] - o1[2]*o2[1];
        r[1] = o1[2]*o2[0] - o1[0]*o2[2];
        r[2] = o1[0]*o2[1] - o1[1]*o2[0];        
        
        return 1;        
    }
    
    return 0;
}

static int Ldist(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, 1);
    lua_Number *o2 = checkvec4(L, 2);
    
    if( o1 && o2 )
    {
        lua_pushnumber(L, sqrt((o1[0]-o2[0])*(o1[0]-o2[0]) + (o1[1]-o2[1])*(o1[1]-o2[1]) + (o1[2]-o2[2])*(o1[2]-o2[2]) + (o1[3]-o2[3])*(o1[3]-o2[3])) ); 
        
        return 1;
    }
    
    return 0;
}

static int LdistSqr(lua_State *L)
{
    lua_Number *o1 = checkvec4(L, 1);
    lua_Number *o2 = checkvec4(L, 2);
    
    if( o1 && o2 )
    {
        lua_pushnumber(L, (o1[0]-o2[0])*(o1[0]-o2[0]) + (o1[1]-o2[1])*(o1[1]-o2[1]) + (o1[2]-o2[2])*(o1[2]-o2[2]) + (o1[3]-o2[3])*(o1[3]-o2[3]) ); 
        
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
    { "__sub",      Lsub        },        
    { "__mul",      Lmul        },    
    { "__div",      Ldiv        }, 
    { "__unm",      Lunm        },    
    { "__eq",       Leq         }, 
    { "dot",        Ldot        },   
    { "normalize",  Lnormalize  },       
    { "dist",       Ldist       },       
    { "distSqr",    LdistSqr    }, 
    { "len",        Llen        },       
    { "lenSqr",     LlenSqr     },     
    { "cross",      Lcross      },               
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_vec4(lua_State *L)
{
    luaL_newmetatable(L,VEC4TYPE);
    
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);
    lua_settable(L, -3);
    
    //luaL_openlib(L,NULL,R,0);
    luaL_register(L, NULL, R);
    
    lua_register(L,"vec4",Lnew);
    return 1;
}
