//
//  DisplayCommands.h
//  Codea
//
//  Created by Simeon Nasilowski on 11/17/11.
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

#ifndef Codify_DisplayCommands_h
#define Codify_DisplayCommands_h

struct lua_State;
@class LuaState;

#define DISPLAY_MODE_STANDARD                   0
#define DISPLAY_MODE_FULLSCREEN                 1
#define DISPLAY_MODE_FULLSCREEN_NO_BUTTONS      2

#define ORIENTATION_PORTRAIT                   0
#define ORIENTATION_PORTRAIT_UPSIDE_DOWN       1
#define ORIENTATION_LANDSCAPE_LEFT             2
#define ORIENTATION_LANDSCAPE_RIGHT            3
#define ORIENTATION_PORTRAIT_ANY               4
#define ORIENTATION_LANDSCAPE_ANY              5
#define ORIENTATION_ANY                        6

//Defined in terms of DISPLAY_MODE because they use the same global in Lua
#define BACKING_MODE_STANDARD                   DISPLAY_MODE_STANDARD
#define BACKING_MODE_RETAINED                   1

#ifdef __cplusplus
extern "C" {
#endif 
    
void setupDisplayGlobals(LuaState* state);

int backingMode(struct lua_State* L);
int displayMode(struct lua_State* L);
int supportedOrientations(struct lua_State* L);
int closeL(struct lua_State* L);

int showKeyboard(struct lua_State* L);    
int hideKeyboard(struct lua_State* L); 
int keyboardBuffer(struct lua_State* L); 
    
int startRecording(struct lua_State* L);
int stopRecording(struct lua_State* L);
int isRecording(struct lua_State* L);
    
#ifdef __cplusplus
}
#endif 

#endif
