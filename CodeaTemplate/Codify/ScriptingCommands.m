//
//  ScriptingCommands.m
//  Codea
//
//  Created by Simeon Nasilowski on 21/05/11.
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

#import "ScriptingCommands.h"

#import "lua.h"
#import "lauxlib.h"

#import "LuaState.h"

static NSString *fixNameString(NSString* name)
{
    NSMutableString *fixedString = [name mutableCopy];
    for( int i = 0; i < [name length]; i++ )
    {
        unichar character = [name characterAtIndex:i];
        if( i == 0 )
        {
            if( !([[NSCharacterSet letterCharacterSet] characterIsMember:character] || character == '_') )
            {
                [fixedString replaceCharactersInRange:NSMakeRange(i, 1) withString:@"_"]; 
            }
        }
        else
        {
            if( ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:character] )
            {
                [fixedString replaceCharactersInRange:NSMakeRange(i, 1) withString:@"_"];                 
            }
        } 
    }
    
    return [fixedString autorelease];
}

int print(struct lua_State *L) 
{
    int n = lua_gettop(L);  /* number of arguments */
    int i;
    
    lua_getglobal(L, "tostring");
    
    NSMutableString *destStr = [NSMutableString stringWithString:@""];
    
    for( i = 1; i <= n; i++ ) 
    {
        const char *s;
        
        lua_pushvalue(L, -1);  /* function to be called */
        lua_pushvalue(L, i);   /* value to print */
        lua_call(L, 1, 1);
        
        s = lua_tostring(L, -1);  /* get result */
        
        if (s == NULL)
        {
            return luaL_error(L, LUA_QL("tostring") " must return a string to "
                              LUA_QL("print"));
        }            
        
        if (i>1) 
        {            
            [destStr appendString:@"\t"];
            //fputs("\t", stdout);    
        }
        
        NSString *strToAppend = [NSString stringWithUTF8String:s];
        
        if( strToAppend != nil )
            [destStr appendString:strToAppend];                
        //fputs(s, stdout);
        
        lua_pop(L, 1);  /* pop result */
    }
    
    [destStr appendString:@"\n"];
    //fputs("\n", stdout);
    
    [[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] printedText:destStr];     
    
    return 0;
}

int parameter(struct lua_State* L)
{
    int nargs = lua_gettop(L);
    
    //Misusing NSRange here but it's a convenient tuple
    lua_Number min = 0;
    lua_Number max = 1;
    NSString *name = @"Unknown";

    float initVal = 0;    
    
    //Calling this with a number or no args does nothing
    if( nargs == 0 || lua_isnumber(L, 1) )
    {
        return 0;
    }    

    //Ensure the first paramater is a string
    if( !lua_isstring(L, 1) )
    {
        return 0;
    }
    
    switch(nargs)
    {
        case 4:
            initVal = lua_tonumber(L, 4);            
        case 3:            
        {
            min = lua_tonumber(L, 2);            
            max = lua_tonumber(L, 3);
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;                        
        case 2:
        {
            max = lua_tonumber(L, 2);
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;            
        case 1:
        {
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;
    }
    
    if( nargs < 4 ) initVal = min;
        
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if( [name isEqualToString:@""] )
    {
        return 0;
    }
    
    name = fixNameString(name);        
    
    [[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] registerFloatParameter:name initialValue:initVal withMin:min andMax:max editable:YES];
    
    return 0;
}

int iparameter(struct lua_State* L)
{
    int nargs = lua_gettop(L);
    
    //Misusing NSRange here but it's a convenient tuple
    lua_Number min = 0;
    lua_Number max = 10;
    NSString *name = @"Unknown";
    
    int initVal = 0;
    
    //Calling this with a number or no args does nothing
    if( nargs == 0 || lua_isnumber(L, 1) )
    {
        return 0;
    }
    
    //Ensure the first paramater is a string
    if( !lua_isstring(L, 1) )
    {
        return 0;
    }    
    
    switch(nargs)
    {
        case 4:
            initVal = lua_tointeger(L, 4);
        case 3:
        {
            min = lua_tointeger(L, 2);            
            max = lua_tointeger(L, 3);
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];                       
        }   break;            
        case 2:
        {
            max = lua_tointeger(L, 2);            
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;                        
        case 1:
        {
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;
    }
    
    if( nargs < 4 ) initVal = min;    

    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if( [name isEqualToString:@""] )
    {
        return 0;
    }    
    
    name = fixNameString(name);    
    
    [[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] registerIntegerParameter:name initialValue:initVal withMin:min andMax:max editable:YES];
    
    return 0;
}

int clearParameters(struct lua_State* L)
{
    [[LuaState sharedInstance].delegate removeAllParametersForLuaState:[LuaState sharedInstance]];
    
    return 0;
}

int clearOutput(struct lua_State* L)
{
    [[LuaState sharedInstance].delegate clearOutputForLuaState:[LuaState sharedInstance]];
    
    return 0;    
}

int watch(struct lua_State* L)
{
    int nargs = lua_gettop(L);
    
    //Misusing NSRange here but it's a convenient tuple
    NSString *name = @"Unknown";
    
    //Calling this with a number or no args does nothing
    if( nargs == 0 || lua_isnumber(L, 1) )
    {
        return 0;
    }    
    
    //Ensure the first paramater is a string
    if( !lua_isstring(L, 1) )
    {
        return 0;
    }    
    
    switch(nargs)
    {
        case 1:
        {
            const char *s = lua_tostring(L, 1);            
            if( s )
                name = [NSString stringWithUTF8String:s];            
        }   break;
    }
    
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if( [name isEqualToString:@""] )
    {
        return 0;
    }    
    
    //name = fixNameString(name);    
    
    //[[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] registerFloatParameter:name initialValue:0 withMin:0 andMax:0 editable:NO];
    
    [[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] registerWatch:name];
    
    return 0;
}

