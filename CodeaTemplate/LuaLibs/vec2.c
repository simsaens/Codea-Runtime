//
//  vec2.c
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

#include "vec2.h"
#include "lua.h"
#include "lauxlib.h"
#include "math.h"
#include "codea_luaext.h"

#define VEC2TYPE    "vec2"
#define VEC2DIM     2

#define MATHF(c)    c##f

lua_Number *getvec2(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        return testudata(L, i, VEC2TYPE);
    }
    
    return NULL;
}

lua_Number *checkvec2(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        lua_Number *v = luaL_checkudata(L,i,VEC2TYPE);
        
        luaL_argcheck(L, v != NULL, 1, "`vec2' expected");
        
        return v;
    }
    
    return NULL;
}

static lua_Number *Pget(lua_State *L, int i)
{
    if (luaL_checkudata(L,i,VEC2TYPE)==NULL) luaL_typerror(L,i,VEC2TYPE);
    return lua_touserdata(L,i);
}

static lua_Number *Pnew(lua_State *L)
{
    lua_Number *v=lua_newuserdata(L,VEC2DIM*sizeof(lua_Number));
    luaL_getmetatable(L,VEC2TYPE);
    lua_setmetatable(L,-2);
    return v;
}

static int Lnew(lua_State *L)			/** vec2(x, y) */
{
    lua_Number *v;
    lua_settop(L,VEC2DIM);
    v=Pnew(L);
    v[0]=luaL_optnumber(L,1,0);
    v[1]=luaL_optnumber(L,2,0);   
    return 1;
}

void pushvec2(lua_State *L, lua_Number x, lua_Number y)
{
    lua_Number *v=Pnew(L);
    v[0]=x;
    v[1]=y;
    //return 1;
}

static int Lget(lua_State *L)
{
    lua_Number *v=Pget(L,1);
    const char* i=luaL_checkstring(L,2);
    switch (*i) 
    {		/* lazy! */
        case '1': case 'x': lua_pushnumber(L,v[0]); break;
        case '2': case 'y': lua_pushnumber(L,v[1]); break;
        default: 
        {
            //Load the metatable and value for key
            luaL_getmetatable(L, VEC2TYPE);
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
        case '1': case 'x': v[0]=t; break;
        case '2': case 'y': v[1]=t; break;
        default: break;
    }
    return 1;
}

static int Ltostring(lua_State *L)
{
    lua_Number *v=Pget(L,1);
    char s[64];
    sprintf(s,"(%f, %f)",v[0],v[1]);
    lua_pushstring(L,s);
    return 1;
}

static int Ladd(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, -1);
    lua_Number *o2 = checkvec2(L, -2);
    
    if( o1 && o2 )
    {
        lua_Number *r = Pnew(L);
        r[0] = o1[0] + o2[0];
        r[1] = o1[1] + o2[1]; 
    
        return 1;
    }
    
    return 0;
}

static int Lmul(lua_State *L)
{
    lua_Number n, *v = NULL;
    
    if( lua_isnumber(L, -1) )
    {
        v = checkvec2(L, -2);
        n = luaL_checknumber(L, -1);
    }
    else if( lua_isnumber(L, -2) )
    {
        v = checkvec2(L, -1);        
        n = luaL_checknumber(L, -2);        
    }
    
    luaL_argcheck(L, v != NULL, 1, "`vec2' expected");    
    
    lua_Number *r = Pnew(L);
    r[0] = v[0] * n;
    r[1] = v[1] * n;
    
    return 1;
}

static int Ldiv(lua_State *L)
{
    lua_Number n, *v = NULL;
    
    v = checkvec2(L, 1);
    n = luaL_checknumber(L, 2);
    
    luaL_argcheck(L, v != NULL, 1, "`vec2' expected");    
    
    lua_Number *r = Pnew(L);
    r[0] = v[0] / n;
    r[1] = v[1] / n;
    
    return 1;
}

static int Lsub(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
    
    if( o1 && o2 )
    {    
        lua_Number *r = Pnew(L);
        r[0] = o1[0] - o2[0];
        r[1] = o1[1] - o2[1]; 
        
        return 1;    
    }
    
    return 0;
}

static int Lunm(lua_State *L)   /** Unary negation */
{
    lua_Number *o1 = checkvec2(L, -1);
    
    if( o1 )
    {
        lua_Number *r = Pnew(L);
        r[0] = -o1[0];
        r[1] = -o1[1];
        
        return 1;            
    }
    
    return 0;
}

static int Leq(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, -1);
    lua_Number *o2 = checkvec2(L, -2);
    
    if( o1 && o2 )
    {
        if( o1[0] == o2[0] && o1[1] == o2[1] )
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
    lua_Number *o1 = checkvec2(L, -1);
        
    if( o1 )
    {
        lua_pushnumber( L, MATHF(sqrt)(o1[0]*o1[0] + o1[1]*o1[1]) );
    
        return 1;        
    }
    
    return 0;
}

static int LlenSqr(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, -1);

    if( o1 )
    {
        lua_pushnumber( L, o1[0]*o1[0] + o1[1]*o1[1] );
    
        return 1;        
    }
    
    return 0;
}

static int Lnormalize(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, -1);
    
    if( o1 )
    {    
        lua_Number len = MATHF(sqrt)(o1[0]*o1[0] + o1[1]*o1[1]);
        
        lua_Number *r = Pnew(L);
        r[0] = o1[0] / len;
        r[1] = o1[1] / len;        
        
        return 1;        
    }
    
    return 0;
}

static int Lrotate(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    
    if( o1 )
    {
        lua_Number a = luaL_checknumber(L, 2);
        
        lua_Number *r = Pnew(L);
        r[0] = MATHF(cos)(a)*o1[0] - MATHF(sin)(a)*o1[1];
        r[1] = MATHF(sin)(a)*o1[0] + MATHF(cos)(a)*o1[1];
        
        return 1;        
    }
    
    return 0;
}

static int Lrotate90(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    
    if( o1 )
    {
        lua_Number *r = Pnew(L);
        r[0] = -o1[1];
        r[1] = o1[0];
        
        return 1;        
    }
    
    return 0;
}

static int Ldot(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
    
    if( o1 && o2 )
    {
        lua_pushnumber(L, o1[0]*o2[0] + o1[1]*o2[1]);    
    
        return 1;        
    }
    
    return 0;
}

static int Lcross(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
    
    if( o1 && o2 )
    {
        lua_pushnumber(L, o1[0]*o2[1] - o1[1]*o2[0]); 
    
        return 1;
    }
    
    return 0;
}

static int Ldist(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
        
    if( o1 && o2 )
    {
        lua_pushnumber(L, sqrt((o1[0]-o2[0])*(o1[0]-o2[0]) + (o1[1]-o2[1])*(o1[1]-o2[1])) ); 
    
        return 1;
    }
    
    return 0;
}

static int LdistSqr(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
        
    if( o1 && o2 )
    {
        lua_pushnumber(L, (o1[0]-o2[0])*(o1[0]-o2[0]) + (o1[1]-o2[1])*(o1[1]-o2[1]) ); 
    
        return 1;
    }
    
    return 0;
}

static int LangleBetween(lua_State *L)
{
    lua_Number *o1 = checkvec2(L, 1);
    lua_Number *o2 = checkvec2(L, 2);
    
    if( o1 && o2 )
    {
        lua_Number angle = MATHF(atan2)(o2[1], o2[0]) - MATHF(atan2)(o1[1], o1[0]);
        
        if( MATHF(fabs)(angle) > M_PI )
            angle += (2 * M_PI * (angle<0?1:-1));
        
        lua_pushnumber(L, angle);     
        
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
    { "rotate",     Lrotate     },           
    { "rotate90",   Lrotate90   }, 
    { "angleBetween",LangleBetween },         
	{ NULL,		NULL		}
};

static const luaL_reg M[] =
{
    { "dot",        Ldot        },   
    { "normalize",  Lnormalize  },       
    { "dist",       Ldist       },       
    { "distSqr",    LdistSqr    }, 
    { "len",        Llen        },       
    { "lenSqr",     LlenSqr     },     
    { "cross",      Lcross      },           
    { "rotate",     Lrotate     },           
    { "rotate90",   Lrotate90   }, 
    { "angleBetween",LangleBetween },     
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_vec2(lua_State *L)
{ 
    luaL_newmetatable(L,VEC2TYPE);         
    
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);   // pushes the metatable
    lua_settable(L, -3);    // metatable.__index = metatable

    luaL_register(L,NULL,R);        
    
    lua_register(L,"vec2",Lnew);
    
    return 1;
}
