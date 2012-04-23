//
//  PhysicsCommands.mm
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

#import "PhysicsCommands.h"
#import "PhysicsManager.h"

#ifdef __cplusplus
extern "C" {
#endif    
#import "lua.h"
#import "lauxlib.h"
#import "vec2.h"
#import "vec3.h"
#import "object_reg.h"
#import "body.h"
#ifdef __cplusplus
}
#endif    

extern float PTM_RATIO;

// This class captures the closest hit shape.
class RaycastCallback : public b2RayCastCallback
{
public:
    RaycastCallback()
    {
        m_fixture = NULL;
        m_maskBits = 0;
    }
    
    float32 ReportFixture(b2Fixture* fixture, const b2Vec2& point, const b2Vec2& normal, float32 fraction)
    {
        // If filtering is enabled, skip filtered fixtures
        if (m_maskBits != 0 && (fixture->GetFilterData().categoryBits & m_maskBits) == 0)
        {
            return 1;
        }
        m_fixture = fixture;
        m_point = point;
        m_normal = normal;
        m_fraction = fraction;
        return fraction;
    }
    b2Fixture* m_fixture;
    b2Vec2 m_point;
    b2Vec2 m_normal;
    float32 m_fraction;
    uint16 m_maskBits;
};

// This class captures the closest hit shape.
class RaycastAllCallback : public b2RayCastCallback
{
public:
    RaycastAllCallback()
    {
        m_maskBits = 0;
        m_tableIndex = 1;
    }
    
    float32 ReportFixture(b2Fixture* fixture, const b2Vec2& point, const b2Vec2& normal, float32 fraction)
    {
        // If filtering is enabled, skip filtered fixtures
        if (m_maskBits != 0 && (fixture->GetFilterData().categoryBits & m_maskBits) == 0)
        {
            return 1;
        }

        
        lua_newtable(L);                
        
        lua_pushstring(L, "body");
        push_obj(L, (body_wrapper_type*)fixture->GetBody()->GetUserData());
        lua_settable(L, -3);   
        
        lua_pushstring(L, "point");
        pushvec2(L, point.x * PTM_RATIO, point.y * PTM_RATIO);
        lua_settable(L, -3);
        
        lua_pushstring(L, "normal");
        pushvec2(L, normal.x, normal.y);
        lua_settable(L, -3);
        
        lua_pushstring(L, "fraction");
        lua_pushnumber(L, fraction);
        lua_settable(L, -3);
        
        lua_rawseti(L, -2, m_tableIndex);
        m_tableIndex++;
        

        return fraction;
    }
    
    struct lua_State* L;
    uint16 m_maskBits;
    int m_tableIndex;
};

class QueryCallback : public b2QueryCallback
{
public:    
    QueryCallback()
    {
        m_tableIndex = 1;
    }
    
    bool ReportFixture(b2Fixture* fixture)
    {
        push_obj(L, (body_wrapper_type*)fixture->GetBody()->GetUserData());        
        lua_rawseti(L, -2, m_tableIndex);
        m_tableIndex++;        
        
        // Return true to continue the query.
        return true;
    }
    
    struct lua_State* L;
    int m_tableIndex;    
};

PhysicsManager *physicsAPI;

void pc_initialize(PhysicsManager *api)
{
    physicsAPI = api;
}

PhysicsManager *getPhysicsAPI()
{
    return physicsAPI;
}

int pause(lua_State *L)
{    
    [physicsAPI setPaused:YES];
    return 0;    
}

int resume(lua_State *L)
{
    [physicsAPI setPaused:NO];    
    return 0;    
}

int iterations(struct lua_State *L)
{
    if (lua_gettop(L) == 2)
    {
        [physicsAPI setVelocityIterations:CLAMP(luaL_checkinteger(L, 1), 1, 100) positionIterations:CLAMP(luaL_checkinteger(L, 2), 1, 100)];    
    }    
    return 0;
}

int pixelToMeterRatio(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n == 0)
    {
        lua_pushnumber(L, getPhysicsAPI().pixelToMeterRatio);
        return 1;
    }
    else if (n == 1)
    {
        getPhysicsAPI().pixelToMeterRatio = luaL_checknumber(L, 1);
    }
    return 0;
}

int gravity(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n == 0)
    {
        b2Vec2 g = getPhysicsAPI().world->GetGravity();
        pushvec2(L, g.x * PTM_RATIO, g.y * PTM_RATIO);
        return 1;
    }
    else if (n == 1)
    {
        if (isudatatype(L, 1, "vec2"))
        {            
            // vec2 means setGravity(vec2(x,y))                                
            lua_Number* v2 = checkvec2(L, 1);            
            getPhysicsAPI().world->SetGravity(b2Vec2(v2[0] * INV_PTM_RATIO, v2[1] * INV_PTM_RATIO));    
        }
        else if (isudatatype(L, 1, "vec3"))
        {
            // One parameter vec3 means setGravity(Gravity)                                
            lua_Number* v3 = checkvec3(L, 1);                        
            getPhysicsAPI().world->SetGravity(9.8f * b2Vec2(v3[0], v3[1]));
        }
    }
    else if (n == 2)
    {
        // Two parameters means setGravity(x,y)
        lua_Number x = luaL_checknumber(L, 1);
        lua_Number y = luaL_checknumber(L, 2);        
        getPhysicsAPI().world->SetGravity(b2Vec2(x * INV_PTM_RATIO, y * INV_PTM_RATIO));            
    }
    return 0;
}

int raycastAll(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n >= 2)
    {
        lua_Number* v1 = checkvec2(L, 1);
        lua_Number* v2 = checkvec2(L, 2);
        
        b2Vec2 point1(v1[0] * INV_PTM_RATIO, v1[1] * INV_PTM_RATIO);
        b2Vec2 point2(v2[0] * INV_PTM_RATIO, v2[1] * INV_PTM_RATIO);        
        
        RaycastAllCallback callback;
        callback.L = L;
        
        // If there are more than 2 arguments, treat the rest as filter categories
        if (n > 2)
        {
            uint16 maskBits = 0;
            for (int i = 3; i <= n; i++)
            {
                // Make sure bit shifts are clamped in range of 16 bit integer            
                luaL_checknumber(L, i);
                maskBits |= 1 << MAX(MIN(luaL_checkinteger(L, -1), 15), 0);
            }   
            callback.m_maskBits = maskBits;            
        }
        
        lua_newtable(L);        
        physicsAPI.world->RayCast(&callback, point1, point2);        
        return 1;
    }    
    
    return 0;
}

int raycast(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n >= 2)
    {
        lua_Number* v1 = checkvec2(L, 1);
        lua_Number* v2 = checkvec2(L, 2);
        
        b2Vec2 point1(v1[0] * INV_PTM_RATIO, v1[1] * INV_PTM_RATIO);
        b2Vec2 point2(v2[0] * INV_PTM_RATIO, v2[1] * INV_PTM_RATIO);        

        RaycastCallback callback;
        
        // If there are more than 2 arguments, treat the rest as filter categories
        if (n > 2)
        {
            uint16 maskBits = 0;
            for (int i = 3; i <= n; i++)
            {
                // Make sure bit shifts are clamped in range of 16 bit integer            
                luaL_checknumber(L, i);
                maskBits |= 1 << MAX(MIN(luaL_checkinteger(L, -1), 15), 0);
            }   
            callback.m_maskBits = maskBits;            
        }
        
        physicsAPI.world->RayCast(&callback, point1, point2);        
        
        if (callback.m_fixture)
        {
            lua_newtable(L);                
            
            lua_pushstring(L, "body");
            push_obj(L, (body_wrapper_type*)callback.m_fixture->GetBody()->GetUserData());
            lua_settable(L, -3);   
            
            lua_pushstring(L, "point");
            pushvec2(L, callback.m_point.x * PTM_RATIO, callback.m_point.y * PTM_RATIO);
            lua_settable(L, -3);
            
            lua_pushstring(L, "normal");
            pushvec2(L, callback.m_normal.x, callback.m_normal.y);
            lua_settable(L, -3);

            lua_pushstring(L, "fraction");
            lua_pushnumber(L, callback.m_fraction);
            lua_settable(L, -3);            
            
            return 1;
        }
        else
        {
            lua_pushnil(L);
            return 1;
        }
    }
    
    
    return 0;
}

int queryAABB(struct lua_State *L)
{
    int n = lua_gettop(L);
    if (n == 2)
    {
        lua_Number* v1 = checkvec2(L, 1);
        lua_Number* v2 = checkvec2(L, 2);
        
        b2Vec2 point1(v1[0] * INV_PTM_RATIO, v1[1] * INV_PTM_RATIO);
        b2Vec2 point2(v2[0] * INV_PTM_RATIO, v2[1] * INV_PTM_RATIO);        
        
        b2AABB aabb;
        aabb.lowerBound = point1;
        aabb.upperBound = point2;
        
        QueryCallback callback;
        callback.L = L;
        
        lua_newtable(L);        
        physicsAPI.world->QueryAABB(&callback, aabb);
        return 1;
    }        
    
    return 0;
}

static const luaL_Reg physicsLibs[] = 
{
    {"pause", pause},
    {"resume", resume},
    {"iterations", iterations},    
    {"gravity", gravity},
    {"pixelToMeterRatio", pixelToMeterRatio},
    {"raycast", raycast},
    {"raycastAll", raycastAll},
    {"queryAABB", queryAABB},
    {NULL, NULL}
};


LUALIB_API int (luaopen_physics) (lua_State *L)
{
    luaL_openlib(L, CODIFY_PHYSICSLIBNAME, physicsLibs, 0);
    return 1;
}


