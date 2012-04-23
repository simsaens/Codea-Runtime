//
//  DisplayCommands.m
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

#include "DisplayCommands.h"

#import "lua.h"
#import "lauxlib.h"
#import "LuaState.h"
#import "EAGLView.h"
#import "SharedRenderer.h"
#import "KeyboardInputView.h"
#import "ScreenCapture.h"

void setupDisplayGlobals(LuaState* state)
{
    [state setGlobalInteger:DISPLAY_MODE_STANDARD withName:@"STANDARD"];
    [state setGlobalInteger:DISPLAY_MODE_FULLSCREEN withName:@"FULLSCREEN"];    
    [state setGlobalInteger:DISPLAY_MODE_FULLSCREEN_NO_BUTTONS withName:@"FULLSCREEN_NO_BUTTONS"];    

    //[state setGlobalInteger:BACKING_MODE_STANDARD withName:@"STANDARD"]; //Use the same as DISPLAY_MODE_STANDARD
    [state setGlobalInteger:BACKING_MODE_RETAINED withName:@"RETAINED"];
    
    [state setGlobalInteger:ORIENTATION_PORTRAIT withName:@"PORTRAIT"];
    [state setGlobalInteger:ORIENTATION_PORTRAIT_UPSIDE_DOWN withName:@"PORTRAIT_UPSIDE_DOWN"];    
    [state setGlobalInteger:ORIENTATION_LANDSCAPE_LEFT withName:@"LANDSCAPE_LEFT"];        
    [state setGlobalInteger:ORIENTATION_LANDSCAPE_RIGHT withName:@"LANDSCAPE_RIGHT"];                
    
    [state setGlobalInteger:ORIENTATION_PORTRAIT_ANY withName:@"PORTRAIT_ANY"];            
    [state setGlobalInteger:ORIENTATION_LANDSCAPE_ANY withName:@"LANDSCAPE_ANY"];                

    [state setGlobalInteger:ORIENTATION_ANY withName:@"ANY"];     
    
    [state setGlobalString:@"" withName:@"BACKSPACE"];     
    [state setGlobalString:@"\n" withName:@"RETURN"];         
}

int backingMode(struct lua_State* L)
{
    EAGLView* glView = [SharedRenderer renderer].glView;

    int n = lua_gettop(L);
    if (n == 0)
    {
        BOOL retainedBacking = glView.retainedBacking;
        if (retainedBacking == YES) {
            lua_pushinteger(L, BACKING_MODE_RETAINED);
        }
        else
        {
            lua_pushinteger(L, BACKING_MODE_STANDARD);
        }
        return 1;
    }
    
    int backingMode = luaL_checkinteger(L, 1);
    
    [glView setRetainedBacking:(backingMode==BACKING_MODE_RETAINED)];
    return 0;
}

int displayMode(struct lua_State* L)
{
    int n = lua_gettop(L);
    if (n > 1)
    {
        luaL_error(L, "function expects 0 or 1 arguments");
        return 0;
    }    
    
    BasicRendererViewController* vc = [SharedRenderer renderer];    
    
    if( n == 0 )
    {        
        if( vc.fullscreen && vc.showButtons )
        {
            lua_pushinteger(L, DISPLAY_MODE_FULLSCREEN);            
        }
        else if( vc.fullscreen && !vc.showButtons )
        {
            lua_pushinteger(L, DISPLAY_MODE_FULLSCREEN_NO_BUTTONS);
        }
        else
        {
            lua_pushinteger(L, DISPLAY_MODE_STANDARD);
        }
        
        return 1;
    }
    else
    {
        int i = luaL_checkinteger(L, 1);        
        
        switch (i) 
        {
            case DISPLAY_MODE_STANDARD:
                [vc setFullscreen:NO animated:YES];
                vc.showButtons = YES;
                break;
                
            case DISPLAY_MODE_FULLSCREEN:
                [vc setFullscreen:YES animated:YES];            
                vc.showButtons = YES;
                break;
                
            case DISPLAY_MODE_FULLSCREEN_NO_BUTTONS:
                [vc setFullscreen:YES animated:YES]; 
                vc.showButtons = NO;
                break;

            default:
                luaL_error(L, "expected one of STANDARD, FULLSCREEN, or FULLSCREEN_NO_BUTTONS");
                break;
        }
        
        return 0;
    }
}

int supportedOrientations(struct lua_State* L)
{
    int n = lua_gettop(L);
    
    BasicRendererViewController* vc = [SharedRenderer renderer];       
    
    if( n == 0 )
    {
        NSSet *supported = vc.supportedOrientations;
        int numResults = 0;
        
        for( NSNumber *n in supported )
        {
            UIInterfaceOrientation orientation = (UIInterfaceOrientation)[n intValue];
            
            switch (orientation) 
            {
                case UIInterfaceOrientationPortrait:
                    numResults++;
                    lua_pushinteger(L, ORIENTATION_PORTRAIT);
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    numResults++;                    
                    lua_pushinteger(L, ORIENTATION_PORTRAIT_UPSIDE_DOWN);                    
                    break;                    
                case UIInterfaceOrientationLandscapeLeft:
                    numResults++;                    
                    lua_pushinteger(L, ORIENTATION_LANDSCAPE_LEFT);                    
                    break;                    
                case UIInterfaceOrientationLandscapeRight:
                    numResults++;                    
                    lua_pushinteger(L, ORIENTATION_LANDSCAPE_RIGHT);                    
                    break;
            }            
        }
        
        return numResults;
    }
    else
    {
        [vc clearSupportedOrientations];
        for( int i = 1; i <= n; i++ )
        {
            lua_Integer orient = luaL_checkinteger(L, i);
                        
            [vc addSupportedOrientation:orient];
        }
    }
    
    return 0;
}

int closeL(struct lua_State* L)
{
    int n = lua_gettop(L);
    if (n > 0)
    {
        luaL_error(L, "function expects 0 arguments");
        return 0;
    }      
    
    //[[CodifyAppDelegate delegate] showRenderView:NO animated:YES];    
    [[SharedRenderer renderer] stopAnimation];
    [[SharedRenderer renderer] dismissModalViewControllerAnimated:YES];
    
    return 0;
}

int showKeyboard(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  
    
    vc.keyboardInputView.active = YES;
    
    return 0;
}

int hideKeyboard(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  
    
    vc.keyboardInputView.active = NO;    
    
    return 0;
}

int keyboardBuffer(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  
    
    if( vc.keyboardInputView.active && vc.keyboardInputView.currentText )
    {
        lua_pushstring(L, [vc.keyboardInputView.currentText UTF8String]);
        return 1;                
    }
    
    return 0;
}

int startRecording(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  

    [vc startRecording];
    
    return 0;
}

int stopRecording(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  
    
    [vc stopRecording];
    
    return 0;
}

int isRecording(struct lua_State* L)
{
    BasicRendererViewController* vc = [SharedRenderer renderer];  
    
    lua_pushboolean(L, vc.screenCapture.recording);
    
    return 1;
}
