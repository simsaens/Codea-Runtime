//
//  matrix44.h
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

#ifndef __Codify__matrix44_h__
#define __Codify__matrix44_h__

#ifdef __cplusplus
extern "C"
{
#endif
    
#include "lua.h"    

#define CODIFY_MATRIX44LIBNAME "matrix44"
    
LUALIB_API int (luaopen_matrix44) (lua_State *L);
lua_Number *checkmatrix44(lua_State *L, int i);
void pushmatrix44(lua_State *L, const lua_Number* data); //data must be 16 elements long

#ifdef __cplusplus
}
#endif


#endif

