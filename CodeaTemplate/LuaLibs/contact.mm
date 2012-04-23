//
//  contact.mm
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

#include "contact.h"
#import "PhysicsManager.h"
#import "PhysicsCommands.h"

#define CONTACT_TYPE   "contact"
#define CONTACT_SIZE   sizeof(contact_wrapper_type)

extern float PTM_RATIO;

contact_wrapper_type* checkContact(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        contact_wrapper_type *contact = (contact_wrapper_type*)luaL_checkudata(L, i, CONTACT_TYPE);        
        luaL_argcheck(L, contact != NULL, 1, "`contact' expected");        
        return contact;
    }    
    return NULL;
}

static contact_wrapper_type* Pget( lua_State *L, int i )
{
    if (luaL_checkudata(L,i,CONTACT_TYPE)==NULL) luaL_typerror(L,i,CONTACT_TYPE);
    return (contact_wrapper_type*)lua_touserdata(L,i);
}

static contact_wrapper_type* Pnew( lua_State *L )
{
    contact_wrapper_type *cw = (contact_wrapper_type*)lua_newuserdata(L,CONTACT_SIZE);
    luaL_getmetatable(L,CONTACT_TYPE);
    lua_setmetatable(L,-2);
    return (contact_wrapper_type*)cw;
}

void push_contact(lua_State *L, ContactPoint* cp)
{
    contact_wrapper_type* cw = Pnew(L);
    cw->contact = (ContactPoint*)malloc(sizeof(ContactPoint));
    // Make a copy of the existing contact point
    *cw->contact = *cp;
    
    // store references to bodies used in contact in environment table
    lua_newtable(L);    
    push_obj(L, cw->contact->fixtureA->GetBody()->GetUserData());    
    lua_rawseti(L, -2, 1);
    push_obj(L, cw->contact->fixtureB->GetBody()->GetUserData());    
    lua_rawseti(L, -2, 2);
    lua_setfenv(L, -2);
}


//static int Lnew(lua_State *L)			/** circleBody(x, y, r) */
//{
//    int argCount = lua_gettop(L);
//    
//    rigidbody_shape_type type = (rigidbody_shape_type)luaL_checkinteger(L, 1);
//    
//    b2Body* body = NULL;
//    //    int pointsRef = LUA_NOREF;
//    float* x = NULL;
//    float* y = NULL;
//    int pointCount = 0;
//    
//    body_wrapper_type** children;
//    int childCount = 0;
//    
//    if (type == RIGIDBODY_POLYGON && argCount >= 4)
//    {
//        // Must specify at least 3 points
//        pointCount = argCount-1;
//        x = new float[argCount-1];
//        y = new float[argCount-1];
//        for (int i = 2; i <= argCount; i++)
//        {
//            lua_Number* v = checkvec2(L, i);
//            x[i-2] = v[0];
//            y[i-2] = v[1];        
//        }
//        
//        body = [getPhysicsAPI() createPolygon:CGPointMake(0, 0) x:x y:y numPoints:argCount-1];        
//    }
//    else if (type == RIGIDBODY_CIRCLE && argCount >= 2)
//    {
//        lua_Number radius = luaL_checknumber(L, 2);
//        body = [getPhysicsAPI() createCircle:0 y:0 radius:radius];
//    }
//    else if (type == RIGIDBODY_COMPOUND && argCount >= 3)
//    {
//        childCount = argCount-1;
//        
//        children = new body_wrapper_type*[childCount];
//        for (int i = 2; i <= argCount; i++)
//        {
//            
//        }
//    }
//    
//    // Only return new rigidbody object if we could create one from arguments
//    if (body)
//    {
//        body_wrapper_type *rb;
//        rb=Pnew(L);    
//        rb->body = body;
//        rb->type = type;
//        rb->parent = NULL;
//        rb->interpolate = false;
//        
//        if (type == RIGIDBODY_POLYGON && pointCount > 0)
//        {
//            rb->pointCount = pointCount;
//            rb->x = x;
//            rb->y = y;            
//        }
//        else
//        {
//            rb->pointCount = 0;
//            rb->x = NULL;
//            rb->y = NULL;
//        }
//        
//        register_obj(L, -1, rb);
//        
//        body->SetUserData(rb);
//        
//        return 1;
//    }
//    
//    return 0;
//}


static int Lget( lua_State *L)
{
    contact_wrapper_type *cw = checkContact(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if (cw->contact == NULL) 
    {
        return 0;    
    }
    
    
    if (strcmp(c, "id") == 0 )
    {
        lua_pushinteger(L, cw->contact->ID);        
    }
    else if (strcmp(c, "state") == 0 )
    {
        lua_pushinteger(L, cw->contact->state);
    }
    else if (strcmp(c, "touching") == 0 )
    {
        lua_pushinteger(L, cw->contact->touching);
    }    
    else if (strcmp(c, "position") == 0 )
    {
        pushvec2(L, cw->contact->position.x * PTM_RATIO, cw->contact->position.y * PTM_RATIO);    
    }        
    else if (strcmp(c, "normal") == 0 )
    {
        pushvec2(L, cw->contact->normal.x, cw->contact->normal.y);    
    }    
    else if (strcmp(c, "normalImpulse") == 0 )
    {
        lua_pushnumber(L, cw->contact->normalImpulse);
    }    
    else if (strcmp(c, "tangentImpulse") == 0 )
    {
        lua_pushnumber(L, cw->contact->tangentImpulse);
    }    
    else if (strcmp(c, "pointCount") == 0 )
    {
        lua_pushinteger(L, cw->contact->pointCount);
    }    
    else if (strcmp(c, "points") == 0 )
    {
        lua_createtable(L, cw->contact->pointCount, 0);        
        for (int i = 0; i < cw->contact->pointCount; i++)
        {
            pushvec2(L, cw->contact->points[i].x * PTM_RATIO, cw->contact->points[i].y * PTM_RATIO);
            lua_rawseti(L, -2, i+1);                
        }
    }
    else if (strcmp(c, "bodyA") == 0 )
    {
        // push environment table
        lua_getfenv(L, 1);
        // push bodyA reference
        lua_rawgeti(L, -1, 1);
        // remove environment table
        lua_remove(L, -2);        
        
        //push_obj(L, cw->contact->fixtureA->GetBody()->GetUserData());
    }   
    else if (strcmp(c, "bodyB") == 0 )
    {
        // push environment table
        lua_getfenv(L, 1);
        // push bodyA reference
        lua_rawgeti(L, -1, 2);
        // remove environment table
        lua_remove(L, -2);        
        
        //        push_obj(L, cw->contact->fixtureB->GetBody()->GetUserData());
    }   
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, CONTACT_TYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);
    }    
    
    return 1;
}

static int Lgc(lua_State *L)
{
    contact_wrapper_type *cw = Pget(L,1);
    free(cw->contact);
    return 1;
}

static int Ltostring(lua_State *L)
{
    contact_wrapper_type *cw = Pget(L, 1);
    char s[128];
    sprintf(s,"contact: %p", cw);
    lua_pushstring(L,s);
    return 1;
}

static const luaL_reg R[] =
{
    { "__index", Lget },
    { "__gc", Lgc },
    { "__tostring", Ltostring },
    { NULL, NULL }
};

LUALIB_API int luaopen_contact(lua_State *L)
{
    luaL_newmetatable(L,CONTACT_TYPE);    
    luaL_openlib(L,NULL,R,0);
    return 1;
}

