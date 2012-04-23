//
//  matrix44.m
//  Codea
//
//  Created by Dylan Sale on 4/03/12.
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

#include "matrix44.h"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#ifdef __cplusplus
extern "C"
{
#endif
      
#include "lauxlib.h"
    
#ifdef __cplusplus
}
#endif


#define MATRIX44TYPE    "matrix"
#define MATRIX44SIZE    16

#define MATHF(c)    c##f

lua_Number *checkmatrix44(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        lua_Number *v = (lua_Number*) luaL_checkudata(L,i,MATRIX44TYPE);
        
        luaL_argcheck(L, v != NULL, 1, "`matrix' expected");
        
        return v;
    }
    
    return NULL;
}

static lua_Number *Pget(lua_State *L, int i)
{
    if (luaL_checkudata(L,i,MATRIX44TYPE) == NULL) luaL_typerror(L,i,MATRIX44TYPE);
    return (lua_Number*) lua_touserdata(L,i);
}

static lua_Number *Pnew(lua_State *L)
{
    lua_Number *v = (lua_Number*) lua_newuserdata(L, sizeof(float)*MATRIX44SIZE);
    luaL_getmetatable(L,MATRIX44TYPE);
    lua_setmetatable(L,-2);
    return v;
}

static int Lnew(lua_State *L)			/** matrix44(x1, ... ,x16) */
{
    
    int n = lua_gettop(L);
    if (n != 0 && n != 16) 
    {
        luaL_error(L, "matrix expects 16 numbers or 0 if you want an identity matrix");
        return 0;
    }
    
    lua_settop(L,MATRIX44SIZE);
    lua_Number *v=Pnew(L);
    
    if(n == 16)
    {
        for (int i=1, j=0; i<MATRIX44SIZE+1; i++, j++)
        {
            v[j] = lua_tonumber(L, i);
        }
    }
    else //setup identity matrix
    {
        int i=0;
        for(int r=0; r<4; r++)
        {
            for(int c=0; c<4; c++)
            {
                if (r == c) 
                {
                    v[i] = 1;
                }
                else
                {
                    v[i] = 0;
                }
                i++;
            }
        }
    }
    
    return 1;
}

void pushmatrix44(lua_State *L, const lua_Number* data)
{
    lua_Number *v=Pnew(L);
    
    memcpy(v, data, sizeof(float)*MATRIX44SIZE);
    
    //return 1;
}

static int Lget(lua_State *L)
{
    lua_Number *v = Pget(L,1);

    bool isnumber = lua_isnumber(L, 2);
    if (isnumber) 
    {
        lua_Integer i = lua_tointeger(L, 2);
        if (i < 1 || i > 16) 
        {
            luaL_error(L, "cannot index a matrix outside range 1 to 16");
            return 0;
        }
        else
        {
            lua_pushnumber(L, v[(i-1)]);
            return 1;
        }
    }
    else
    {
        const char* tag = luaL_checkstring(L,2);
        //Load the metatable and value for key
        luaL_getmetatable(L, MATRIX44TYPE);
        lua_pushstring(L, tag);
        lua_gettable(L, -2);

        return 1;
    }
}

static int Lset(lua_State *L) 
{
    lua_Number *v = Pget(L,1);
    

    lua_Integer i = luaL_checkinteger(L,2);
    lua_Number t = luaL_checknumber(L,3);
    
    if (i < 1 || i > 16) 
    {
        luaL_error(L, "cannot index a matrix outside range 1 to 16");
        return 0;
    }
    
    v[i-1] = t;
    
    return 1;
}

static int Ltostring(lua_State *L)
{
    lua_Number *v = Pget(L,1);
    char s[32*MATRIX44SIZE];
    sprintf(s,"(%.2f, %.2f, %.2f, %.2f\n %.2f, %.2f, %.2f, %.2f\n %.2f, %.2f, %.2f, %.2f\n %.2f, %.2f, %.2f, %.2f)",
            v[ 0],v[ 1],v[ 2],v[ 3],
            v[ 4],v[ 5],v[ 6],v[ 7],
            v[ 8],v[ 9],v[10],v[11],
            v[12],v[13],v[14],v[15]);
    lua_pushstring(L,s);
    return 1;
}

static int Ladd(lua_State *L)
{
    lua_Number *o1 = checkmatrix44(L, -1);
    lua_Number *o2 = checkmatrix44(L, -2);
    
    if( o1 && o2 )
    {
        lua_Number *r = Pnew(L);
        for(int i=0; i<MATRIX44SIZE; i++)
        {
            r[i] = o1[i]+o2[i];
        }
        
        return 1;
    }
    
    return 0;
}

static int Lmul(lua_State *L)
{
    lua_Number n, *v = NULL, *v2 = NULL;
    
    v = checkmatrix44(L, -1);
    v2 = checkmatrix44(L, -2);
    
    if(v != NULL && v2 != NULL)
    {        
        lua_Number *r = Pnew(L);
             
        //Column major multiplication
        glm::mat4& m1 = *(glm::mat4*)v;
        glm::mat4& m2 = *(glm::mat4*)v2;
        
        glm::mat4& res = *(glm::mat4*)r;
        
        res = m1 * m2;
        
        //glm::mat4 res = (*m1) * (*m2);        
        //lua_Number *resV = glm::value_ptr(res);
        
        //memcpy(r, resV, 16*sizeof(lua_Number));
        
        //Do matrix multiplication using row major matricies (not sure if this is correct, it might need to be
        //column major
        //This is very naive, and there are probably a lot of faster ways
        /*
        for (int leftRow=0; leftRow < 4; leftRow++) 
        {
            for (int rightCol=0; rightCol < 4; rightCol++)
            {
                float element = 0;
                for (int i = 0; i < 4; i++) 
                {
                    element += v[leftRow*4+i] * v2[i*4+rightCol];
                }
                r[leftRow*4+rightCol] = element;
            }
        }
        */
         
        return 1;
    }
    
    
    //scalar multiplication
    if( lua_isnumber(L, -1) && v2 != NULL )
    {
        v = v2;
        n = luaL_checknumber(L, -1);
    }
    else if( lua_isnumber(L, -2) && v != NULL)
    {
        n = luaL_checknumber(L, -2);        
    }
    
    luaL_argcheck(L, v != NULL, 1, "`matrix' expected");    
    
    lua_Number *r = Pnew(L);
    
    /*Fails?*/    
//    glm::mat4& res = *(glm::mat4*)r;    
//    res = n * res;
    
    for(int i=0; i<MATRIX44SIZE; i++)
    {
        r[i] = v[i]*n;
    }
    
    return 1;
}

static int Ldiv(lua_State *L)
{
    lua_Number n, *v = NULL;
    
    v = checkmatrix44(L, 1);
    n = luaL_checknumber(L, 2);
    
    luaL_argcheck(L, v != NULL, 1, "`matrix' expected");    
    
    lua_Number *r = Pnew(L);
    lua_Number invN = 1.f/n;
    for(int i=0; i<MATRIX44SIZE; i++)
    {
        r[i] = v[i]*invN;
    }
    
    
    return 1;
}

static int Lsub(lua_State *L)
{
    lua_Number *o1 = checkmatrix44(L, 1);
    lua_Number *o2 = checkmatrix44(L, 2);
    
    if( o1 && o2 )
    {    
        lua_Number *r = Pnew(L);
        for(int i=0; i<MATRIX44SIZE; i++)
        {
            r[i] = o1[i]-o2[i];
        }
        
        return 1;    
    }
    
    return 0;
}

static int Lunm(lua_State *L)   /** Unary negation */
{
    lua_Number *o1 = checkmatrix44(L, -1);
    
    if( o1 )
    {
        lua_Number *r = Pnew(L);
        for(int i=0; i<MATRIX44SIZE; i++)
        {
            r[i] = -o1[i];
        }
        
        return 1;            
    }
    
    return 0;
}

static int Leq(lua_State *L)
{
    lua_Number *o1 = checkmatrix44(L, -1);
    lua_Number *o2 = checkmatrix44(L, -2);
    
    if( o1 && o2 )
    {
        bool same = true;
        for(int i=0; i<MATRIX44SIZE && same; i++)
        {
            same = o1[i] == o2[i];
        }
        
        lua_pushboolean(L, same);
        
        return 1;
    }
    
    return 0;
}

static int Lrotate(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number *m = checkmatrix44(L, 1);    
    
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");        
    
    if( m != NULL )
    {
        lua_Number r = 0;
        lua_Number x = 0,y = 0,z = 1;
        switch(n)
        {
            case 5: /* matrix.rotate( m, r, x, y, z ) */
                x = luaL_checknumber(L, 3);      
                y = luaL_checknumber(L, 4);      
                z = luaL_checknumber(L, 5);  
                
            case 2: /* matrix.rotate( m, r ) */
                r = luaL_checknumber(L, 2);                        
                break;
        }

        lua_Number *mv = Pnew(L);
        
        glm::mat4& mat = *(glm::mat4*)m;       
        glm::mat4& rotated = *(glm::mat4*)mv;
        
        rotated = glm::rotate(mat, r, glm::vec3( x, y, z ) );        
        
        return 1;
    }
    
    return 0;        
}

static int Ltranslate(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number *m = checkmatrix44(L, 1);    
    
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");        
    
    if( m != NULL )
    {
        lua_Number x = 0,y = 0,z = 0;
        switch(n)
        {
            case 4:                
                z = luaL_checknumber(L, 4);      
            case 3:
                x = luaL_checknumber(L, 2);      
                y = luaL_checknumber(L, 3);                  
                break;
        }
        
        lua_Number *mv = Pnew(L);
        
        glm::mat4& mat = *(glm::mat4*)m;        
        glm::mat4& translated = *(glm::mat4*)mv;
        
        translated = glm::translate(mat, glm::vec3(x, y, z) );        
        
        return 1;
    }
    
    return 0;        
}

static int Lscale(lua_State *L)
{
    int n = lua_gettop(L);
    
    lua_Number *m = checkmatrix44(L, 1);    
    
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");        
    
    if( m != NULL )
    {
        lua_Number x = 1,y = 1,z = 1;
        switch(n)
        {
            case 4:                
                z = luaL_checknumber(L, 4);      
            case 3:
                x = luaL_checknumber(L, 2);      
                y = luaL_checknumber(L, 3);                                  
                break;
            case 2:
                x = luaL_checknumber(L, 2);      
                y = x;
                z = x;
                break;
        }
        
        lua_Number *mv = Pnew(L);
        
        glm::mat4& mat = *(glm::mat4*)m; 
        glm::mat4& scaled = *(glm::mat4*)mv;
        
        scaled = glm::scale(mat, glm::vec3(x,y,z));
        
        return 1;
    }
    
    return 0;        
}

static int Linverse(lua_State *L)
{
    lua_Number *m = checkmatrix44(L, 1);    
    
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");        
    
    if( m != NULL )
    {
        lua_Number *r = Pnew(L);        
        glm::mat4& mat = *(glm::mat4*)m;
        glm::mat4& inverted = *(glm::mat4*)r;
        
        inverted = glm::inverse(mat);
        
        return 1;
    }
    
    return 0;
}

static int Ltranspose(lua_State *L)
{
    lua_Number *m = checkmatrix44(L, 1);    
    
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");        
    
    if( m != NULL )
    {
        lua_Number *r = Pnew(L);        
        glm::mat4& mat = *(glm::mat4*)m;
        glm::mat4& transposed = *(glm::mat4*)r;
        
        transposed = glm::transpose(mat);
        return 1;
    }
    
    return 0;
}

static int Ldeterminant(lua_State *L)
{
    lua_Number *m = checkmatrix44(L, 1);
    luaL_argcheck(L, m != NULL, 1, "`matrix' expected");
    
    if( m != NULL )
    {
        lua_Number det;
        glm::mat4& mat = *(glm::mat4*)m;
        
        det = glm::determinant(mat);
        lua_pushnumber(L, det);
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
    { "rotate",     Lrotate     },
    { "translate",  Ltranslate  },
    { "scale",      Lscale      },   
    { "inverse",    Linverse    },   
    { "transpose",  Ltranspose  },
    { "determinant",  Ldeterminant  },
//    { "dot",        Ldot        },   
//    { "normalize",  Lnormalize  },       
//    { "dist",       Ldist       },       
//    { "distSqr",    LdistSqr    }, 
//    { "len",        Llen        },       
//    { "lenSqr",     LlenSqr     },     
//    { "cross",      Lcross      },           
//    { "rotate",     Lrotate     },           
//    { "rotate90",   Lrotate90   }, 
//    { "angleBetween",LangleBetween },         
	{ NULL,		NULL		}
};

static const luaL_reg M[] =
{
//    { "dot",        Ldot        },   
//    { "normalize",  Lnormalize  },       
//    { "dist",       Ldist       },       
//    { "distSqr",    LdistSqr    }, 
//    { "len",        Llen        },       
//    { "lenSqr",     LlenSqr     },     
//    { "cross",      Lcross      },           
//    { "rotate",     Lrotate     },           
//    { "rotate90",   Lrotate90   }, 
//    { "angleBetween",LangleBetween },     
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_matrix44(lua_State *L)
{ 
    luaL_newmetatable(L,MATRIX44TYPE);         
    
    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);   // pushes the metatable
    lua_settable(L, -3);    // metatable.__index = metatable
    
    luaL_register(L,NULL,R);        
    
    lua_register(L,"matrix",Lnew);
    
    return 1;
}
