//
//  http.m
//  Codea
//
//  Created by Dylan Sale on 20/03/12.
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

#import "http.h"
#import "ASIHTTPRequest.h"
#import "LuaState.h"
#import "image.h"

#ifdef __cplusplus
extern "C"
{
#endif
    
#include "lauxlib.h"
    
#ifdef __cplusplus
}
#endif

//Table is at index idx. Takes the keys and values and puts them in the request headers
//Stack is the same when returning
static void buildHeadersFromTable (lua_State* L, int idx, ASIHTTPRequest* request)
{
    luaL_checktype(L, idx, LUA_TTABLE);
    if (idx < 0)
        idx = lua_gettop(L)+idx+1; //make it positive
    
    /* table is in the stack at index 't' */
    lua_pushnil(L);  /* first key */
    while (lua_next(L, idx) != 0) {
        /* uses 'key' (at index -2) and 'value' (at index -1) */

        if(lua_type(L, -2) != LUA_TSTRING || lua_type(L, -1) != LUA_TSTRING)
        {
            luaL_error(L, "header table must only have string keys and values");
            return;
        }
        
        const char* key = lua_tostring(L, -2);
        const char* val = lua_tostring(L, -1);
        
        NSString* keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
        NSString* valStr = [NSString stringWithCString:val encoding:NSUTF8StringEncoding];
        
        [request addRequestHeader:keyStr value:valStr];
        
        
        /* removes 'value'; keeps 'key' for next iteration */
        lua_pop(L, 1);
    }

}

//returns with the new table on the top of the stack
static void pushNSDictionary(lua_State* L, NSDictionary* dictionary)
{
    lua_newtable(L);
    int tablePos = lua_gettop(L);
    for (NSString* key in dictionary) 
    {
        NSString* value = [dictionary objectForKey:key];
        lua_pushstring(L, [key cStringUsingEncoding:NSUTF8StringEncoding]);
        lua_pushstring(L, [value cStringUsingEncoding:NSUTF8StringEncoding]);
        lua_settable(L, tablePos);
    }
}

//Synchronous (ish?) http get
//Requires (url, successCallback, [failCallback], [params])
//where params is a table like {"method":"HEAD", "headers":{things}, "data":"postdata", "useragent":etc}
int Lrequest(lua_State* L)
{
    int n = lua_gettop(L);
    
    if (n < 2)
        luaL_error(L, "expected a url and success callback, or url and parameter table");
    
    const char* urlCString = luaL_checkstring(L, 1);
    
    NSString* urlString = [NSString stringWithCString:urlCString encoding:NSUTF8StringEncoding];
    NSURL* url = [NSURL URLWithString:urlString];
    __block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:url];
    
    
    //Check successCallback
    luaL_argcheck(L, lua_isfunction(L, 2), 2, "expected a function");
    
    lua_pushvalue(L, 2); //push it to the top of the stack
    int successCallback = luaL_ref(L, LUA_REGISTRYINDEX); //remove it and store it in the registry
    int failCallback;
    BOOL hasFailCallback = false;
    
    if(n >= 3 && lua_isfunction(L, 3))
    {
        hasFailCallback = true;
        lua_pushvalue(L, 3); //push it to the top of the stack
        failCallback = luaL_ref(L, LUA_REGISTRYINDEX); //remove it and store it in the registry
    }
    
    if(n >= 3 && lua_istable(L, n))
    {
        //TODO: extract parameters from the table
        int paramsPos = n;
        
        lua_pushliteral(L, "method");
        lua_gettable(L, paramsPos);
        if ( lua_isstring(L, -1) )
        {
            const char* method = lua_tostring(L, -1);
            [request setRequestMethod:[NSString stringWithCString:method encoding:NSUTF8StringEncoding]];
        }
        lua_pop(L, 1);
        
        lua_pushliteral(L, "headers");
        lua_gettable(L, paramsPos);
        if ( lua_istable(L, -1) ) 
        {
            buildHeadersFromTable(L, -1, request);
        }
        lua_pop(L, 1);
        
        lua_pushliteral(L, "useragent");
        lua_gettable(L, paramsPos);
        if ( lua_isstring(L, -1) ) 
        {
            const char* useragent = lua_tostring(L,-1);
            [request setUserAgent:[NSString stringWithCString:useragent encoding:NSUTF8StringEncoding]];
        }
        lua_pop(L, 1);
        
        lua_pushliteral(L, "data");
        lua_gettable(L, paramsPos);
        if ( lua_isstring(L, -1) ) 
        {
            size_t len;
            const char* postData = lua_tolstring(L, -1, &len);
            NSMutableData* data = [NSMutableData dataWithBytes:postData length:len];
            [request setPostBody:data];
        }
        lua_pop(L, 1);
        
    }
    
    [request setCompletionBlock:^{
        
        NSData* responseData = request.responseData;
        
        //This will try to make an image if iOS can from the given data, otherwise returns nil
        UIImage* image = [UIImage imageWithData:responseData];
        
        //        NSString* mimeType = [request.responseHeaders objectForKey:@"Content-Type"];
        //        BOOL isImage = [mimeType rangeOfString:@"image/png"].location != NSNotFound ||
        //                       [mimeType rangeOfString:@"image/jpeg"].location != NSNotFound;
        
        
        lua_rawgeti(L,LUA_REGISTRYINDEX,successCallback); //push the callback to the top of the stack
        lua_unref(L, successCallback); //free the callback
        if(hasFailCallback)
        {
            lua_unref(L, failCallback);
        }
        
        if(image != nil)
        {
            pushUIImage(L, image);            
        }
        else
        {
            lua_pushlstring(L, [responseData bytes], [responseData length]);            
        }        
        
        lua_pushinteger(L, request.responseStatusCode);
        pushNSDictionary(L, request.responseHeaders);
        
        //TODO: extract response headers and push as a table
        
        [[LuaState sharedInstance] printErrors:lua_pcall(L, 3, 0, 0)];
        
    }];
    
    
    if(hasFailCallback)
    {
        [request setFailedBlock:^{
            
            NSString* error = [request.error localizedDescription];
            
            lua_rawgeti(L,LUA_REGISTRYINDEX,failCallback); //push the callback to the top of the stack
            lua_unref(L, failCallback); //free the callback
            lua_unref(L, successCallback); //free the callback
            
            lua_pushstring(L, [error cStringUsingEncoding:NSUTF8StringEncoding]);
            
            [[LuaState sharedInstance] printErrors:lua_pcall(L, 1, 0, 0)];
            
        }];
    }
    
    
    [request startAsynchronous];      
    
    return 0;
}

int Lget(lua_State* L)
{
    return Lrequest(L);
}

int Lpost(lua_State* L)
{
    return 0;
}

static const luaL_reg R[] =
{    
	{ "get",        Lget		},
	//{ "post",       Lpost		},
	{ "request",	Lrequest	},
        
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_http(lua_State *L)
{
    luaL_register(L,CODIFY_HTTPLIBNAME,R);
    return 1;
}
