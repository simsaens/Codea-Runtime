//
//  OSCommands.m
//  Codea
//
//  Created by Simeon Nasilowski on 19/03/12.
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

#import "OSCommands.h"
#import "lua.h"
#import "lauxlib.h"

int openURL(struct lua_State *L)
{
    int n = lua_gettop(L);
    int useInternal = 0;
    NSString *theURL = nil;
    
    switch (n) 
    {
        case 2:
            useInternal = lua_toboolean(L, 2);            
        case 1:
        {
            const char *theString = luaL_checkstring(L, 1);
            
            if( theString )
            {
                theURL = [NSString stringWithUTF8String:theString];
            }
        }   break;   
        default:
            break;
    }
    
    if( theURL )
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:theURL]];
    }
    
    return 0;
}

int tweet(struct lua_State *L)
{
    return 0;
}

int alert(struct lua_State *L)
{
    return 0;
}