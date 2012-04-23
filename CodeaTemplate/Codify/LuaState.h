//
//  LuaState.h
//  Codea
//
//  Created by Simeon Nasilowski on 17/05/11.
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

#include "SynthesizeSingleton.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "touch.h"
    
#ifdef __cplusplus
}
#endif

@class LuaState;

@protocol LuaStateDelegate <NSObject>

- (void) luaState:(LuaState*)state printedText:(NSString*)text;
- (void) clearOutputForLuaState:(LuaState*)state;
- (void) removeAllParametersForLuaState:(LuaState*)state;
- (void) luaState:(LuaState *)state registerWatch:(NSString*)expression;
- (void) luaState:(LuaState*)state registerFloatParameter:(NSString*)text initialValue:(CGFloat)value withMin:(CGFloat)min andMax:(CGFloat)max editable:(BOOL)editable;
- (void) luaState:(LuaState*)state registerIntegerParameter:(NSString*)text initialValue:(NSInteger)value withMin:(NSInteger)min andMax:(NSInteger)max editable:(BOOL)editable;
- (void) luaState:(LuaState *)state errorOccured:(NSString*)error;

@end

struct lua_State;

typedef struct LuaError
{
    NSUInteger lineNumber;
    NSUInteger referringLine;
    NSString* errorMessage;
} LuaError;

@interface LuaState : NSObject 
{
    struct lua_State *L;
    
    id<LuaStateDelegate> delegate;
}
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(LuaState);

@property (nonatomic,assign) id<LuaStateDelegate> delegate;
@property (nonatomic,readonly) struct lua_State* L;

- (void) create;
- (void) createWithFakeLibs;

- (void) close;

- (LuaError) loadString:(NSString*)string;

- (NSString*) stackArgumentsToString;

- (BOOL) hasGlobal:(NSString*)name;

- (void*) createGlobalUserData:(size_t)size withTypeName:(NSString*)type andName:(NSString*)name;

- (void) setGlobalNumber:(lua_Number)number withName:(NSString*)name;
- (void) setGlobalInteger:(int)number withName:(NSString*)name;
- (void) setGlobalString:(NSString*)string withName:(NSString*)name;

- (void*) globalUserData:(NSString*)name;
- (lua_Number) globalNumber:(NSString*)name;
- (int) globalInteger:(NSString*)name;

- (void) printErrors:(int)status;

- (BOOL) callSimpleFunction:(NSString*)funcName;
- (BOOL) callFunction:(NSString*)funcName numArgs:(int)argCount;
- (BOOL) callTouchFunction:(NSSet*)touches inView:(UIView*)view;
- (BOOL) callKeyboardFunction:(NSString*)newText;
- (BOOL) callOrientationFunction:(int)newOrientation;

- (void) disableInstructionLimit;
@end
