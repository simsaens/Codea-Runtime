//
//  contact.h
//  Codea
//
//  Created by John Millard on 3/01/12.
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

//
//  body.h
//  Codea
//
//  Created by John Millard on 9/11/11.
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

#ifndef Codify_contact_h
#define Codify_contact_h

struct ContactPoint;
typedef struct ContactPoint ContactPoint;

#ifdef __cplusplus
extern "C" {
#endif 
    
#import "LuaState.h"           
#include "lua.h"
#include "lauxlib.h"    
#include "object_reg.h"
#include "vec2.h"
    
#define CODIFY_CONTACT_LIBNAME "contact"    
    LUALIB_API int (luaopen_contact) (lua_State *L);

void push_contact(lua_State *L, ContactPoint* cp);
    
#ifdef __cplusplus
}
#endif 

typedef struct contact_wrapper_type
{    
    ContactPoint* contact;
} contact_wrapper_type;



#endif    