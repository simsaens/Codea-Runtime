//
//  LuaState.m
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

#import "LuaState.h"

#import "EAGLView.h"

#import "RenderCommands.h"
#import "ScriptingCommands.h"
#import "SoundCommands.h"
#import "DeviceCommands.h"
#import "GraphicsCommands.h"
#import "PhysicsCommands.h"
#import "DisplayCommands.h"
#import "OSCommands.h"

#import "SharedRenderer.h"

#import "lua.h"
#import "lualib.h"
#import "lauxlib.h"

#import "object_reg.h"
//#import "luasocket.h"
//#import "mime.h"
#import "http.h"

#import "vec2.h"
#import "vec3.h"
#import "vec4.h"
#import "matrix44.h"
#import "color.h"
#import "touch.h"
#import "body.h"
#import "joint.h"
#import "contact.h"
#import "Persistence.h"
#import "image.h"
#import "mesh.h"
#import "soundbuffer.h"

#import <unistd.h>

#define LuaRegFunc(x)   lua_register(L,#x,x)
#define LuaDudFunc(x)   lua_register(L,#x,dud_void_function)

#define LuaRegNamedFunc(x,n)    lua_register(L,#n,x)

const char* TooManyLinesError = "Lua program has exceeded instruction limit";
int kMaxLineCount = 30000000;
void TooManyLinesFunc(lua_State *L, lua_Debug *ar)
{
    luaL_error(L, TooManyLinesError);
}

int setInstructionLimit(lua_State *L)
{
    lua_Number n = lua_gettop(L);
    if(n == 1)
    {
        lua_Number instructionCount = lua_tonumber(L, 1);
        lua_sethook(L, &TooManyLinesFunc, LUA_MASKCOUNT, instructionCount);
    }
    
    return 0;
}


////////////////////////////////////////////////
//Custom Lua environment
static const luaL_Reg codifylibs[] = 
{
    {"", luaopen_base},
    
    {LUA_LOADLIBNAME, luaopen_package},
    {LUA_TABLIBNAME, luaopen_table},
    {LUA_IOLIBNAME, luaopen_io},
    {LUA_OSLIBNAME, luaopen_os},
    {LUA_STRLIBNAME, luaopen_string},
    {LUA_MATHLIBNAME, luaopen_math},
    {LUA_DBLIBNAME, luaopen_debug},
    
    /*

    {"mime", luaopen_mime_core},    
    {"socket", luaopen_socket_core},
    */
    
    {CODIFY_COLORLIBNAME, luaopen_color},
    {CODIFY_TOUCHLIBNAME, luaopen_touch},
    {CODIFY_VEC2LIBNAME, luaopen_vec2},           
    {CODIFY_VEC3LIBNAME, luaopen_vec3},   
    {CODIFY_VEC4LIBNAME, luaopen_vec4},
    {CODIFY_MATRIX44LIBNAME, luaopen_matrix44}, 
    {CODIFY_HTTPLIBNAME, luaopen_http}, 
    {CODIFY_RIGIDBODY_LIBNAME, luaopen_rigidbody},
    {CODIFY_PHYSICSLIBNAME, luaopen_physics},
    {CODIFY_CONTACT_LIBNAME, luaopen_contact},
    {CODIFY_JOINT_LIBNAME, luaopen_joint},
    {CODIFY_MESH_LIBNAME, luaopen_mesh},
    {CODIFY_IMAGELIBNAME, luaopen_image},    
    {CODIFY_SOUNDBUFFERLIBNAME, luaopen_soundbuffer},

    {NULL, NULL}
};


LUALIB_API void codify_openlibs (lua_State *L) 
{
    const luaL_Reg *lib = codifylibs;
    for (; lib->func; lib++) 
    {
        lua_pushcfunction(L, lib->func);
        lua_pushstring(L, lib->name);
        lua_call(L, 1, 0);
    }
}
////////////////////////////////////////////////
//Dud function
static int dud_void_function(lua_State* state)
{
    return 0;
}
//``````````````````````````````````````````````

@implementation LuaState

SYNTHESIZE_SINGLETON_FOR_CLASS(LuaState);

@synthesize delegate;
@synthesize L;

#pragma mark - Initialization

- (id) init 
{
    self = [super init];
    if( self )
    {
        L = 0;
        
        [self create];                    
    }
    return self;
}

#pragma mark - Helpers

- (void) printErrors:(int)status
{
    if( status )
    {
        const char* errorString = lua_tostring(L, -1);
        if(strcmp(errorString, TooManyLinesError) == 0)
        {
            DBLog(@"Too Many Lines detected, do something here to inform the user");
            //TODO: Do something to stop it running?
        }
        
        DBLog(@"error: %s", errorString );
                        
        if( [[LuaState sharedInstance].delegate respondsToSelector:@selector(luaState:errorOccured:)] )
        {
            [[LuaState sharedInstance].delegate luaState:[LuaState sharedInstance] 
                                            errorOccured:[NSString stringWithFormat:@"error: %s\n",errorString]];
        }            
        
        lua_pop(L,1);
    }
}

#pragma mark - Convert arguments on the stack to a string (e.g. print)

- (NSString*) stackArgumentsToString
{
    int n = lua_gettop(L);  /* number of arguments */
    int i;
    
    if( n == 0 ) return @"nil";
    
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
            continue;
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
    
    //Pop tostring
    lua_pop(L, 1);
    
    //Pop args after printing
    for( i = 1; i <= n; i++ )
    {
        lua_pop(L, i);
    }
    
    return destStr;
}

#pragma mark - Loading lua code

- (LuaError) loadString:(NSString*)string
{
    LuaError luaError;            
    luaError.errorMessage = nil;
    luaError.lineNumber = NSNotFound;
    luaError.referringLine = NSNotFound;
    
    lua_sethook(L, &TooManyLinesFunc, LUA_MASKCOUNT, kMaxLineCount);
    
    if( luaL_loadstring(L, [string UTF8String]) || lua_pcall(L,0,0,0) )
    {
        //[self printErrors:1];    
        
        const char *s = lua_tostring(L, -1);
                
        NSString *errorMessage = nil;
        
        if( s )
        {
            errorMessage = [NSString stringWithUTF8String:s];
        }
        
        if( errorMessage )
        {        
            DBLog(@"Raw error: %@", errorMessage);
            
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+?:.*" options:NSRegularExpressionCaseInsensitive error:&error];                
            NSRange usefulMessageRange = [regex rangeOfFirstMatchInString:errorMessage options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [errorMessage length])];

            if( usefulMessageRange.location != NSNotFound )
            {
                errorMessage = [errorMessage substringWithRange:usefulMessageRange];        
            }
            
            NSArray *components = [errorMessage componentsSeparatedByString:@":"];
            
            luaError.lineNumber = 1;
            luaError.errorMessage = errorMessage;
            
            if( [components count] >= 2 )
            {
                luaError.lineNumber = [(NSString*)[components objectAtIndex:0] intValue];
                luaError.errorMessage = [(NSString*)[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                regex = [NSRegularExpression regularExpressionWithPattern:@"at line \\d+" options:NSRegularExpressionCaseInsensitive error:&error];
                usefulMessageRange = [regex rangeOfFirstMatchInString:luaError.errorMessage options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [luaError.errorMessage length])];

                if( usefulMessageRange.location != NSNotFound )
                {
                    NSString *atLine = [luaError.errorMessage substringWithRange:usefulMessageRange];
                    
                    luaError.referringLine = [[atLine substringWithRange:NSMakeRange(8, [atLine length]-8)] intValue];
                }
            }
        }
    }      
    
    return luaError;
}

- (BOOL) hasGlobal:(NSString*)name
{
    lua_getglobal(L, [name UTF8String]);
    if( !lua_isnil(L, -1) && lua_isnumber(L, -1) )
    {
        return YES;
    }
    return NO;
}

- (void*) createGlobalUserData:(size_t)size withTypeName:(NSString*)type andName:(NSString*)name
{
    void *v = lua_newuserdata(L, size);
    luaL_getmetatable(L, [type UTF8String]);
    lua_setmetatable(L, -2);
    
    lua_setglobal(L, [name UTF8String]);
    
    return v;
}

- (void) setGlobalNumber:(lua_Number)number withName:(NSString*)name
{
    lua_pushnumber(L, number);
    lua_setglobal(L, [name UTF8String]);    
}

- (void) setGlobalInteger:(int)number withName:(NSString*)name
{
    lua_pushinteger(L, number);
    lua_setglobal(L, [name UTF8String]);    
}

- (void) setGlobalString:(NSString*)string withName:(NSString*)name
{
    lua_pushstring(L, [string UTF8String]);
    lua_setglobal(L, [name UTF8String]);
}

- (void*) globalUserData:(NSString*)name
{
    lua_getglobal(L, [name UTF8String]);
    
    if( !lua_isnil(L, -1) && lua_isuserdata(L, -1) )
    {
        void* udata = lua_touserdata(L, -1);
        lua_pop(L, 1);
        return udata;
    }
    
    lua_pop(L, 1);    
    return NULL;
}

- (lua_Number) globalNumber:(NSString*)name
{
    lua_getglobal(L, [name UTF8String]);
    if( !lua_isnil(L, -1) && lua_isnumber(L, -1) )
    {
        lua_Number num = lua_tonumber(L, -1);
        lua_pop(L, 1);
        return num;
    }
    
    lua_pop(L, 1);
    
    return 0.0f;
}

- (int) globalInteger:(NSString*)name
{
    lua_getglobal(L, [name UTF8String]);
    if( !lua_isnil(L, -1) && lua_isnumber(L, -1) )
    {
        lua_Integer num = lua_tointeger(L, -1);
        lua_pop(L, 1);
        return num;
    }
    
    lua_pop(L, 1);
    return 0;
}

- (BOOL) callFunction:(NSString*)funcName numArgs:(int)argCount
{
    lua_getglobal(L, [funcName UTF8String]);
    if( !lua_isfunction(L, -1) )
    {
        lua_pop(L,1);
        
        DBLog(@"%@ is not a Lua function", funcName);
        
        return NO;
    }
    else
    {
        [self printErrors:lua_pcall(L, 0, 0, 0)];
        
        return YES;
    }    
}

- (BOOL) callSimpleFunction:(NSString*)funcName
{
    //lua_sethook(L, &TooManyLinesFunc, LUA_MASKCOUNT, kMaxLineCount);

    lua_getglobal(L, [funcName UTF8String]);
    if( !lua_isfunction(L, -1) )
    {
        lua_pop(L,1);
        
        DBLog(@"%@ is not a Lua function", funcName);
        
        return NO;
    }
    else
    {
        [self printErrors:lua_pcall(L, 0, 0, 0)];
        
        return YES;
    }
}

- (BOOL) callKeyboardFunction:(NSString*)newText
{
    lua_getglobal(L, "keyboard");
    if( !lua_isfunction(L, -1) )
    {
        lua_pop(L,1);
        return NO;
    }
    else
    {
        lua_pushstring(L, [newText UTF8String]);
        [self printErrors:lua_pcall(L, 1, 0, 0)];
        
        return YES;
    }
}

- (BOOL) callOrientationFunction:(int)newOrientation
{
    lua_getglobal(L, "orientationChanged");
    if( !lua_isfunction(L, -1) )
    {
        lua_pop(L,1);
        return NO;
    }
    else
    {
        lua_pushinteger(L, newOrientation);
        [self printErrors:lua_pcall(L, 1, 0, 0)];
        
        return YES;
    }    
}

- (BOOL) callTouchFunction:(NSSet*)touches inView:(UIView*)view
{
    lua_getglobal(L, "touched");
    if( !lua_isfunction(L, -1) )
    {
        lua_pop(L,1);
        return NO;
    }
    else
    {
        for (UITouch* touch in touches) 
        {
            touch_type *v = lua_newuserdata(L, sizeof(touch_type));
            luaL_getmetatable(L, "touch");
            lua_setmetatable(L, -2);

            v->ID = (unsigned int)touch;
            v->tapCount = touch.tapCount;
            switch (touch.phase) {
                case UITouchPhaseBegan:
                    v->state = TOUCH_STATE_BEGAN;
                    break;
                case UITouchPhaseMoved:
                    v->state = TOUCH_STATE_MOVING;
                    break;
                case UITouchPhaseEnded:
                    v->state = TOUCH_STATE_ENDED;
                    break;
                case UITouchPhaseCancelled:
                    v->state = TOUCH_STATE_INACTIVE;
                    break;
                case UITouchPhaseStationary:
                    v->state = TOUCH_STATE_STATIONARY;
                    break;
                default:
                    break;
            }
            
            CGPoint curLoc = [touch locationInView:view];
            v->x = curLoc.x;
            v->y = view.bounds.size.height - curLoc.y;
            
            CGPoint prevLoc = [touch previousLocationInView:view];    
            v->prevX = prevLoc.x;
            v->prevY = view.bounds.size.height - prevLoc.y;    
            
            v->deltaX = v->x - v->prevX;
            v->deltaY = v->y - v->prevY;        

            [self printErrors:lua_pcall(L, 1, 0, 0)];
            
            lua_getglobal(L, "touched");
        }        
        
        lua_pop(L, 1); //remove extra function
        return YES;
    }
}

#pragma mark - Instruction limit

- (void) disableInstructionLimit
{
    lua_sethook(L, NULL, 0, 0);    
}

#pragma mark - State management

- (void) create
{
    if( L != 0 )
    {
        lua_close(L);
    }
    
    L = lua_open();
    
    //luaL_openlibs(L);
    
    //Load only a subset of Lua libs
    codify_openlibs(L);

    LuaRegFunc(setInstructionLimit);
    
    //Push the render functions
    LuaRegFunc(background);

    LuaRegFunc(tint);
    LuaRegFunc(noTint);        
    
    LuaRegFunc(fill);
    LuaRegFunc(noFill);    
    
    LuaRegFunc(stroke);
    LuaRegFunc(noStroke);    
    
    LuaRegFunc(strokeWidth); 
    LuaRegFunc(pointSize);     

    LuaRegFunc(font);
    LuaRegFunc(fontSize);
    LuaRegFunc(fontMetrics);    
    LuaRegFunc(textWrapWidth);
    LuaRegFunc(textAlign);    
    LuaRegFunc(textSize);        

    LuaRegFunc(perspective);
    LuaRegFunc(ortho);
    LuaRegFunc(camera);    
    LuaRegFunc(applyMatrix);
    LuaRegFunc(modelMatrix);
    LuaRegFunc(viewMatrix);
    LuaRegFunc(projectionMatrix);    
    
    //LuaRegFunc(drawImage);
    LuaRegFunc(sprite);
    LuaRegFunc(rect);
    LuaRegFunc(ellipse);    
    LuaRegFunc(text);
    LuaRegFunc(point);     
    LuaRegFunc(line);    
    LuaRegFunc(triangulate);

    LuaRegFunc(spriteSize);
    
    LuaRegFunc(setContext);
    
    LuaRegFunc(rectMode);
    LuaRegFunc(ellipseMode); 
    LuaRegFunc(spriteMode);  
    LuaRegFunc(textMode);      
    LuaRegFunc(lineCapMode); 
    
    LuaRegFunc(smooth); 
    LuaRegFunc(noSmooth);     

    LuaRegFunc(pushMatrix);    
    LuaRegFunc(popMatrix);
    LuaRegFunc(resetMatrix);    
    
    LuaRegFunc(pushStyle);    
    LuaRegFunc(popStyle);
    LuaRegFunc(resetStyle);        
    
    LuaRegFunc(translate);        
    LuaRegFunc(rotate);
    LuaRegFunc(scale); 
    LuaRegFunc(zLevel);    
    
    LuaRegFunc(backingMode);
    LuaRegFunc(displayMode);
    LuaRegFunc(supportedOrientations);
    LuaRegNamedFunc(closeL, close);
    LuaRegFunc(showKeyboard);
    LuaRegFunc(hideKeyboard);   
    LuaRegFunc(keyboardBuffer);        
    LuaRegFunc(startRecording);
    LuaRegFunc(stopRecording);    
    LuaRegFunc(isRecording);    
    
    LuaRegFunc(clip);
    LuaRegFunc(noClip);        
        
    //Override the Lua print function
    LuaRegFunc(print);
    
    //Additional scripting commands
    LuaRegFunc(parameter);
    LuaRegFunc(iparameter);    
    LuaRegFunc(clearParameters);    
    LuaRegFunc(clearOutput);         
    LuaRegFunc(watch);
    
    //Sound Commands
    LuaRegFunc(sound);
    LuaRegFunc(soundBufferSize);
    
    //Persistence Commands
    LuaRegFunc(readLocalData);
    LuaRegFunc(saveLocalData);
    LuaRegFunc(clearLocalData);
    LuaRegFunc(readProjectData);
    LuaRegFunc(saveProjectData);
    LuaRegFunc(clearProjectData);
    LuaRegFunc(readGlobalData);
    LuaRegFunc(saveGlobalData);
    LuaRegFunc(readProjectInfo);
    LuaRegFunc(saveProjectInfo);
    LuaRegFunc(saveDocumentsImage);
    LuaRegFunc(saveProjectImage);
    
    //OS Commands
    LuaRegFunc(openURL);    

//    //Physics Commands
//    LuaRegFunc(setPhysicsIterations);
//    LuaRegFunc(pausePhysics);
//    LuaRegFunc(resumePhysics);
//    LuaRegFunc(setGravity);
    
    //Graphics Commands
    LuaRegFunc(noise);
    LuaRegFunc(rsqrt);
    
    // Device Commands
    LuaRegFunc(deviceMetrics);
    
    // registry
    create_obj_registry(L);     

    //Setup library globals
    setupDisplayGlobals(self);
    setupSoundGlobals(self);
}

- (void) createWithFakeLibs
{
    if( L != 0 )
    {
        lua_close(L);
    }
    
    L = lua_open();
    
    //luaL_openlibs(L);
    
    //Load only a subset of Lua libs
    codify_openlibs(L);

    LuaDudFunc(setInstructionLimit);
    
    //Push the render functions
    LuaDudFunc(background);
    
    LuaDudFunc(tint);
    LuaDudFunc(noTint);            
    
    LuaDudFunc(fill);
    LuaDudFunc(noFill);    
    
    LuaDudFunc(stroke);
    LuaDudFunc(noStroke);    
    
    LuaDudFunc(strokeWidth); 
    LuaDudFunc(pointSize);     
    
    LuaDudFunc(font);
    LuaDudFunc(fontSize);
    LuaDudFunc(fontMetrics);        
    LuaDudFunc(textWrapWidth);
    LuaDudFunc(textAlign);       
    LuaDudFunc(textSize);           
    
    LuaDudFunc(perspective);
    LuaDudFunc(ortho);
    LuaDudFunc(camera);    
    LuaDudFunc(applyMatrix);
    LuaDudFunc(modelMatrix);
    LuaDudFunc(viewMatrix);
    LuaDudFunc(projectionMatrix);    

    //LuaDudFunc(drawImage);    
    LuaDudFunc(sprite);    
    LuaDudFunc(rect);
    LuaDudFunc(ellipse);    
    LuaDudFunc(text);    
    LuaDudFunc(point);     
    LuaDudFunc(line);     
    LuaDudFunc(triangulate);   
    
    LuaDudFunc(spriteSize);    
    
    LuaDudFunc(setContext);

    LuaDudFunc(rectMode);
    LuaDudFunc(ellipseMode);            
    LuaDudFunc(spriteMode); 
    LuaDudFunc(textMode);          
    LuaDudFunc(lineCapMode); 
    
    LuaDudFunc(smooth); 
    LuaDudFunc(noSmooth); 

    LuaDudFunc(pushMatrix);    
    LuaDudFunc(popMatrix);
    LuaDudFunc(resetMatrix);    
    
    LuaDudFunc(pushStyle);    
    LuaDudFunc(popStyle);
    LuaDudFunc(resetStyle);            
    
    LuaDudFunc(translate);        
    LuaDudFunc(rotate);
    LuaDudFunc(scale); 
    LuaDudFunc(zLevel);        
    
    LuaDudFunc(backingMode);
    LuaDudFunc(displayMode);
    LuaRegFunc(supportedOrientations);    
    LuaDudFunc(close);    
    LuaDudFunc(showKeyboard);
    LuaDudFunc(hideKeyboard);    
    LuaDudFunc(keyboardBuffer);     
    LuaDudFunc(startRecording);
    LuaDudFunc(stopRecording);    
    LuaDudFunc(isRecording);        
    
    LuaDudFunc(clip);
    LuaDudFunc(noClip);    

    //Override the Lua print function
    LuaDudFunc(print);
    
    //Additional scripting commands
    LuaDudFunc(parameter);
    LuaDudFunc(iparameter);
    LuaDudFunc(clearParameters); 
    LuaDudFunc(clearOutput);     
    LuaDudFunc(watch);              
    
    //Sound Commands
    LuaDudFunc(sound);
    LuaDudFunc(soundBufferSize);
    
    //Persistence Commands
    LuaRegFunc(readLocalData);
    LuaDudFunc(saveLocalData);
    LuaDudFunc(clearLocalData);
    LuaRegFunc(readProjectData);
    LuaDudFunc(saveProjectData);
    LuaDudFunc(clearProjectData);
    LuaRegFunc(readGlobalData);
    LuaDudFunc(saveGlobalData);
    LuaRegFunc(readProjectInfo);
    LuaDudFunc(saveProjectInfo);      
    LuaDudFunc(saveDocumentsImage);
    LuaDudFunc(saveProjectImage);
        
    //OS Commands
    LuaDudFunc(openURL);        
    
    //Graphics Commands - don't use dud here because this returns values
    LuaRegFunc(noise); 
    LuaRegFunc(rsqrt); 
    
    //Device Commands
    LuaRegFunc(deviceMetrics);    
    
    //Set instruction for initial parse
    lua_sethook(L, &TooManyLinesFunc, LUA_MASKCOUNT, kMaxLineCount);    
    
    //Setup library globals
    setupDisplayGlobals(self);
    setupSoundGlobals(self);    
}

- (void) close
{
    lua_close(L);
    L = 0;
}

#pragma mark - Memory

- (void) dealloc
{
    if( L != 0 )
    {
        lua_close(L);
    }
    
    [super dealloc];
}

@end
