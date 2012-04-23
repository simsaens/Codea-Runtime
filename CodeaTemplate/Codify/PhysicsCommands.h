//
//  PhysicsCommands.h
//  Codea
//
//  Created by JtM on 30/10/11.
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

#import <Foundation/Foundation.h>

#define CODIFY_PHYSICSLIBNAME "physics"
#define CLAMP(x, l, h)  (((x) > (h)) ? (h) : (((x) < (l)) ? (l) : (x)))

@class PhysicsManager;
struct lua_State;

#ifdef __cplusplus
extern "C" {
#endif 
    
    #include "lua.h"

    void pc_initialize(PhysicsManager *api);
    PhysicsManager *getPhysicsAPI();

    int pausePhysics(struct lua_State *L);
    int resumePhysics(struct lua_State *L);
    int setPhysicsIterations(struct lua_State *L);
    int setGravity(struct lua_State *L);

    int raycastAll(struct lua_State *L);
    int raycast(struct lua_State *L);
    int queryAABB(struct lua_State *L);
    
    
    LUALIB_API int (luaopen_physics) (lua_State *L);    
    
#ifdef __cplusplus
}
#endif 