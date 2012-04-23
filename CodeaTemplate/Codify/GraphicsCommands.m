//
//  GraphicsCommands.m
//  Codea
//
//  Created by Simeon Nasilowski on 8/10/11.
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

#import "GraphicsCommands.h"
#import "ImprovedPerlinNoise.h"

#import "lauxlib.h"

int noise(struct lua_State* L)
{
    int n = lua_gettop(L);
    
    lua_Number x = 0;
    lua_Number y = 0;
    lua_Number z = 0;
    
    switch( n )
    {
        case 3:
            z = luaL_checknumber(L, 3);
        case 2:
            y = luaL_checknumber(L, 2);            
        case 1:
            x = luaL_checknumber(L, 1);  
            break;
    }
    
    lua_Number noiseResult = perlin_noise(x, y, z);
    
    lua_pushnumber(L, noiseResult);
    
    return 1;
}

int rsqrt(struct lua_State* L)
{
    int n = lua_gettop(L);
    
    lua_Number number = 0;    
    
    if( n == 1 )
    {
        number = luaL_checknumber(L, 1);
    }
    
    long i;
    float x2, y;
    const float threehalfs = 1.5F;
    
    x2 = number * 0.5F;
    y  = number;
    i  = * ( long * ) &y;                       // evil floating point bit level hacking
    i  = 0x5f3759df - ( i >> 1 );               // what the fuck?
    y  = * ( float * ) &i;
    y  = y * ( threehalfs - ( x2 * y * y ) );   // 1st iteration
    //    y  = y * ( threehalfs - ( x2 * y * y ) );   // 2nd iteration, this can be removed
    
    lua_pushnumber(L, y);
    
    return 1;
}