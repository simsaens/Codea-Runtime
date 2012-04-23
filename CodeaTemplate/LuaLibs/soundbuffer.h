//
//  soundbuffer.h
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

#ifndef Codify_soundbuffer_h
#define Codify_soundbuffer_h

#include "lua.h"

#define CODIFY_SOUNDBUFFERLIBNAME "soundbuffer"

@class ALBuffer;

typedef struct soundbuffer_type_t
{
    ALBuffer* buffer;
} soundbuffer_type;


#ifdef __cplusplus
extern "C" {
#endif 
    
    LUALIB_API int (luaopen_soundbuffer) (lua_State *L);
    soundbuffer_type *check_soundbuffer(lua_State *L, int i);
    soundbuffer_type* tosoundbuffer(lua_State* L, int i);

#ifdef __cplusplus
}
#endif 



#endif
