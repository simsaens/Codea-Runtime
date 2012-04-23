//
//  body.m
//  Codea
//
//  Created by John Millard on 9/11/11.
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

#include "body.h"
#import "PhysicsManager.h"
#import "PhysicsCommands.h"

#define RIGIDBODY_TYPE   "body"
#define RIGIDBODY_SIZE   sizeof(body_wrapper_type)

extern float PTM_RATIO;

body_wrapper_type* checkRigidbody(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        body_wrapper_type *poly = (body_wrapper_type*)luaL_checkudata(L, i, RIGIDBODY_TYPE);        
        luaL_argcheck(L, poly != NULL, 1, "`body' expected");        
        return poly;
    }    
    return NULL;
}

static body_wrapper_type* Pget( lua_State *L, int i )
{
    if (luaL_checkudata(L,i,RIGIDBODY_TYPE)==NULL) luaL_typerror(L,i,RIGIDBODY_TYPE);
    return (body_wrapper_type*)lua_touserdata(L,i);
}

static body_wrapper_type* Pnew( lua_State *L )
{
    body_wrapper_type *v= (body_wrapper_type*)lua_newuserdata(L,RIGIDBODY_SIZE);
    luaL_getmetatable(L,RIGIDBODY_TYPE);
    lua_setmetatable(L,-2);
    return (body_wrapper_type*)v;
}

static int Lnew(lua_State *L)			/** circleBody(x, y, r) */
{
    int argCount = lua_gettop(L);
    
    rigidbody_shape_type type = (rigidbody_shape_type)luaL_checkinteger(L, 1);
    
    b2Body* body = NULL;
//    int pointsRef = LUA_NOREF;
    float* x = NULL;
    float* y = NULL;
    int pointCount = 0;
    
    body_wrapper_type** children;
    int childCount = 0;
    
    if (type == RIGIDBODY_POLYGON && argCount >= 4)
    {
        // Must specify at least 3 points
        pointCount = argCount-1;
        x = new float[argCount-1];
        y = new float[argCount-1];
        for (int i = 2; i <= argCount; i++)
        {
            lua_Number* v = checkvec2(L, i);
            // invalid parameter
            if (v == NULL)
            {
                return 0;
            }
            x[i-2] = v[0];
            y[i-2] = v[1];        
        }
        
        body = [getPhysicsAPI() createPolygon:CGPointMake(0, 0) x:x y:y numPoints:argCount-1];        
    }
    else if (type == RIGIDBODY_CHAIN && argCount >= 4)
    {
        BOOL loop = lua_toboolean(L, 2);
        
        // Must specify at least 2 points
        pointCount = argCount-2;
        x = new float[pointCount];
        y = new float[pointCount];
        for (int i = 3; i <= argCount; i++)
        {
            lua_Number* v = checkvec2(L, i);
            x[i-3] = v[0];
            y[i-3] = v[1];        
        }
            
        body = [getPhysicsAPI() createChain:CGPointMake(0, 0) x:x y:y numPoints:pointCount loop:loop];        
    }
    else if (type == RIGIDBODY_EDGE && argCount >= 3)
    {
        lua_Number* pA = checkvec2(L, 2);
        lua_Number* pB = checkvec2(L, 3);
        pointCount = 2;
        x = new float[pointCount];
        y = new float[pointCount];
        x[0] = pA[0];
        y[0] = pA[1];
        x[1] = pB[0];
        y[1] = pB[1];
        body = [getPhysicsAPI() createEdge:CGPointMake(0, 0) pointA:CGPointMake(pA[0], pA[1]) pointB:CGPointMake(pB[0], pB[1])];        
    }
    else if (type == RIGIDBODY_CIRCLE && argCount >= 2)
    {
        lua_Number radius = luaL_checknumber(L, 2);
        body = [getPhysicsAPI() createCircle:0 y:0 radius:radius];
    }
    else if (type == RIGIDBODY_COMPOUND && argCount >= 3)
    {
        childCount = argCount-1;
        
        children = new body_wrapper_type*[childCount];
        for (int i = 2; i <= argCount; i++)
        {
            
        }
    }
    
    // Only return new rigidbody object if we could create one from arguments
    if (body)
    {
        body_wrapper_type *rb;
        rb=Pnew(L);    
        rb->body = body;
        rb->type = type;
        rb->parent = NULL;
        rb->interpolate = false;
        
        if ((type == RIGIDBODY_POLYGON || type == RIGIDBODY_CHAIN || type == RIGIDBODY_EDGE) && pointCount > 0)
        {
            rb->pointCount = pointCount;
            rb->x = x;
            rb->y = y;            
        }
        else
        {
            rb->pointCount = 0;
            rb->x = NULL;
            rb->y = NULL;
        }
        
        register_obj(L, -1, rb);
        
        body->SetUserData(rb);
        
        return 1;
    }
    
    return 0;
}


static int Lget( lua_State *L)
{
    body_wrapper_type *body = checkRigidbody(L, 1);
    const char* c = luaL_checkstring(L,2);
 
    if (body->body == NULL) return 0;    
    
    b2Fixture* fixture = body->body->GetFixtureList();
    
    if( strcmp(c, "x") == 0 )
    {
        if (body->interpolate)
        {
            lua_pushnumber(L, body->renderX * PTM_RATIO);       
        }
        else
        {
            lua_pushnumber(L, body->body->GetPosition().x * PTM_RATIO);    
        }        
    }
    else if( strcmp(c, "y") == 0 )
    {
        if (body->interpolate)
        {
            lua_pushnumber(L, body->renderY * PTM_RATIO);       
        }
        else
        {        
            lua_pushnumber(L, body->body->GetPosition().y * PTM_RATIO);        
        }        
    }
    else if (strcmp(c, "position") == 0 )
    {
        if (body->interpolate)
        {
            pushvec2(L, body->renderX * PTM_RATIO, body->renderY * PTM_RATIO);
        }
        else
        {        
            pushvec2(L, body->body->GetPosition().x * PTM_RATIO, body->body->GetPosition().y * PTM_RATIO);
        }        
    }        
    else if( strcmp(c, "angle") == 0 )
    {
        if (body->interpolate)
        {
            lua_pushnumber(L, body->renderAngle / M_PI * 180.0f);        
        }
        else
        {        
            lua_pushnumber(L, body->body->GetAngle() / M_PI * 180.0f);        
        }                
    }    
    else if (strcmp(c, "linearVelocity") == 0 )
    {
        pushvec2(L, body->body->GetLinearVelocity().x * PTM_RATIO, body->body->GetLinearVelocity().y * PTM_RATIO);
    }            
    else if( strcmp(c, "angularVelocity") == 0 )
    {
        lua_pushnumber(L, body->body->GetAngularVelocity() / M_PI * 180.0f);        
    }    
    else if ( strcmp(c, "awake") == 0 )
    {
        lua_pushboolean(L, fixture->GetBody()->IsAwake());
    }         
    else if ( strcmp(c, "type") == 0 )
    {
        lua_pushinteger(L, (lua_Integer)body->body->GetType());
    }
    else if ( strcmp(c, "density") == 0 )
    {
        lua_pushnumber(L, fixture->GetDensity());        
    }    
    else if ( strcmp(c, "mass") == 0 )
    {
        lua_pushnumber(L, body->body->GetMass());        
    }        
    else if ( strcmp(c, "inertia") == 0 )
    {
        lua_pushnumber(L, body->body->GetInertia());        
    }        
    else if ( strcmp(c, "sensor") == 0 )
    {
        lua_pushboolean(L, fixture->IsSensor());        
    }     
    else if ( strcmp(c, "bullet") == 0 )
    {
        lua_pushboolean(L, body->body->IsBullet());        
    }         
    else if ( strcmp(c, "friction") == 0 )
    {
        lua_pushnumber(L, fixture->GetFriction());        
    }        
    else if ( strcmp(c, "restitution") == 0 )
    {
        lua_pushnumber(L, fixture->GetRestitution());        
    }        
    else if ( strcmp(c, "fixedRotation") == 0 )
    {
        body->body->IsFixedRotation();
    }
    else if ( strcmp(c, "active") == 0 )
    {
        lua_pushboolean(L, fixture->GetBody()->IsActive());
    }
    else if ( strcmp(c, "sleepingAllowed") == 0 )
    {
        lua_pushboolean(L, fixture->GetBody()->IsSleepingAllowed());
    }
    else if ( strcmp(c, "linearDamping") == 0 )
    {            
        lua_pushboolean(L, body->body->GetLinearDamping());
    }    
    else if ( strcmp(c, "angularDamping") == 0 )
    {            
        lua_pushboolean(L, body->body->GetAngularDamping());
    }        
    else if ( strcmp(c, "interpolate") == 0 )
    {            
        lua_pushboolean(L, body->interpolate);
    }    
    else if ( strcmp(c, "gravityScale") == 0)
    {
        lua_pushnumber(L, body->body->GetGravityScale());
    }    
    else if ( strcmp(c, "categories") == 0)
    {
                
        if( body && body->body)
        {
            
            b2Filter filter(body->body->GetFixtureList()->GetFilterData());
            int n = 0;
            for (int i = 0; i <= 15; i++)
            {
                if (filter.categoryBits & (1 << i))
                {
                    n++;
                }
            }        
            
            lua_createtable(L, n, 0);
            int count = 1;
            for (int i = 0; i <= 15; i++)
            {
                if (filter.categoryBits & (1 << i))
                {
                    lua_pushinteger(L, i);
                    lua_rawseti(L, -2, count);
                    count++;
                }
            }        
         
            return 1;
        }
    }        
    else if ( strcmp(c, "mask") == 0)
    {
        
        if( body && body->body)
        {
            
            b2Filter filter(body->body->GetFixtureList()->GetFilterData());
            int n = 0;
            for (int i = 0; i <= 15; i++)
            {
                if (filter.maskBits & (1 << i))
                {
                    n++;
                }
            }        
            
            lua_createtable(L, n, 0);
            int count = 1;
            for (int i = 0; i <= 15; i++)
            {
                if (filter.maskBits & (1 << i))
                {
                    lua_pushinteger(L, i);
                    lua_rawseti(L, -2, count);
                    count++;
                }
            }        
            
            return 1;
        }
    }        
    else if ( strcmp(c, "shapeType") == 0)
    {
        lua_pushnumber(L, body->type);
    }        
    else if ( strcmp(c, "radius") == 0 && body->type == RIGIDBODY_CIRCLE)
    {
        b2Fixture* fixture = body->body->GetFixtureList();
        b2CircleShape* circle = (b2CircleShape*)fixture->GetShape();
        lua_pushnumber(L, circle->m_radius * PTM_RATIO);
    }
    else if ( strcmp(c, "info") == 0 )
    {
        lua_getfenv(L, 1);
        
//        if (body->infoRef != LUA_NOREF)
//        {
//            lua_rawgeti(L, LUA_REGISTRYINDEX, body->infoRef);
//        }
//        else
//        {
//            lua_pushnil(L);
//        }
    }
    else if ( strcmp(c, "points") == 0 && body->pointCount > 0)
    {
        // Create table for points and leave on the stack
        lua_newtable(L);
        for (int i = 0; i < body->pointCount; i++)
        {
            lua_pushnumber(L, i+1);
            pushvec2(L, body->x[i], body->y[i]);
            lua_settable(L, -3);
        }        
    }
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, RIGIDBODY_TYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);
    }    
    
    return 1;
}

int Lset(lua_State *L) 
{
    body_wrapper_type *body = checkRigidbody(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if (body->body == NULL) return 0;
    
    if (strcmp(c, "position") == 0 )
    {
        lua_Number* v = checkvec2(L, 3);
        if (v)
        {
            b2Vec2 pos = b2Vec2(v[0] * INV_PTM_RATIO, v[1] * INV_PTM_RATIO);
            body->body->SetTransform(pos, 0);          
            body->prevX = body->renderX = pos.x;
            body->prevY = body->renderY = pos.y;
        }

        return 1;        
    }
    else if (strcmp(c, "linearVelocity") == 0 )
    {
        lua_Number* v = checkvec2(L, 3);        
        if (v)
        {
            b2Vec2 pos = b2Vec2(v[0] * INV_PTM_RATIO, v[1] * INV_PTM_RATIO);            
            body->body->SetLinearVelocity(pos);            
        }
        return 1;        
    }    
    else if (strcmp(c, "angularVelocity") == 0 )
    {
        body->body->SetAngularVelocity(luaL_checknumber(L,3) * M_PI / 180.0f);
        return 1;        
    }        
    else if( strcmp(c, "x") == 0 )
    {       
        b2Vec2 pos = body->body->GetPosition();
        pos.x = luaL_checknumber(L,3) * INV_PTM_RATIO;
        body->body->SetTransform(pos, body->body->GetAngle());
        body->prevX = body->renderX = pos.x;
        return 1;        
    }
    else if( strcmp(c, "y") == 0 )
    {       
        b2Vec2 pos = body->body->GetPosition();
        pos.y = luaL_checknumber(L,3) * INV_PTM_RATIO;
        body->body->SetTransform(pos, body->body->GetAngle());
        body->prevY = body->renderY = pos.y;
        return 1;        
    }
    else if (strcmp(c, "angle") == 0 )
    {
        b2Vec2 pos = body->body->GetPosition();        
        body->body->SetTransform(pos, luaL_checknumber(L,3) * M_PI / 180.0f);
        body->renderAngle = body->prevAngle = body->body->GetAngle();
        return 1;        
    }    
    else if (strcmp(c, "type") == 0 )
    {
        body->body->SetType(CLAMP((b2BodyType)luaL_checkinteger(L,3), b2_staticBody, b2_dynamicBody));
        return 1;        
    }
    else if ( strcmp(c, "density") == 0 )
    {
        float density = CLAMP(luaL_checknumber(L,3), 0, b2_maxFloat);
        for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
        {
            f->SetDensity(density);
        }
        body->body->ResetMassData();
        return 1;        
    }    
    else if ( strcmp(c, "mass") == 0 )
    {
        float mass = CLAMP(luaL_checknumber(L,3), 0, b2_maxFloat);
        b2MassData massData;
        body->body->GetMassData(&massData);
        massData.mass = mass;
        body->body->SetMassData(&massData);
        return 1;        
    }        
    else if ( strcmp(c, "sensor") == 0 )
    {
        BOOL sensor = lua_toboolean(L, 3);
        for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
        {
            f->SetSensor(sensor);
        }
        return 1;        
    }
    else if ( strcmp(c, "bullet") == 0 )
    {
        body->body->SetBullet(lua_toboolean(L, 3));
    }
    else if ( strcmp(c, "sleepingAllowed") == 0 )
    {
        body->body->SetSleepingAllowed(lua_toboolean(L, 3));
    }
    else if ( strcmp(c, "friction") == 0 )
    {              
        float friction = CLAMP(luaL_checknumber(L,3), 0, b2_maxFloat);
        for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
        {
            f->SetFriction(friction);
        }
        return 1;        
    }        
    else if ( strcmp(c, "restitution") == 0 )
    {
        float restitution = CLAMP(luaL_checknumber(L,3), 0, b2_maxFloat);
        for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
        {
            f->SetRestitution(restitution);
        }
        return 1;        
    }          
    else if ( strcmp(c, "fixedRotation") == 0 )
    {
        body->body->SetFixedRotation(lua_toboolean(L, 3));
        return 1;
    }    
    else if ( strcmp(c, "active") == 0 )
    {            
        body->body->SetActive(lua_toboolean(L, 3));
        return 1;
    }        
    else if ( strcmp(c, "linearDamping") == 0 )
    {            
        body->body->SetLinearDamping(luaL_checknumber(L, 3));
        return 1;
    }   
    else if ( strcmp(c, "angularDamping") == 0 )
    {            
        body->body->SetAngularDamping(luaL_checknumber(L, 3));
        return 1;
    }       
    else if ( strcmp(c, "interpolate") == 0 )
    {            
        body->interpolate = lua_toboolean(L, 3);
        return 1;
    }
    else if ( strcmp(c, "gravityScale") == 0)
    {
        body->body->SetGravityScale(CLAMP(luaL_checknumber(L, 3), -b2_maxFloat, b2_maxFloat));
        return 1;
    }    
    else if ( strcmp(c, "categories") == 0)
    {
        
        /* 1st argument must be a table (t) */
        luaL_checktype(L, 3, LUA_TTABLE);
        
        int n = luaL_getn(L, 3);  /* get size of table */
                
        if( body && body->body && n >= 1)
        {
            b2Filter filter(body->body->GetFixtureList()->GetFilterData());
            filter.categoryBits = 0;
            for (int i = 1; i <= n; i++)
            {
                // Make sure bit shifts are clamped in range of 16 bit integer            
                lua_rawgeti(L, 3, i);
                filter.categoryBits |= 1 << MAX(MIN(luaL_checkinteger(L, -1), 15), 0);
                lua_pop(L, 1);
            }        
            for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
            {
                f->SetFilterData(filter);
            }        
        }
                
        return 1;
    }    
    else if ( strcmp(c, "mask") == 0)
    {
        
        /* 1st argument must be a table (t) */
        luaL_checktype(L, 3, LUA_TTABLE);
        
        int n = luaL_getn(L, 3);  /* get size of table */
        
        if( body && body->body && n >= 1)
        {
            b2Filter filter(body->body->GetFixtureList()->GetFilterData());
            filter.maskBits = 0;
            for (int i = 1; i <= n; i++)
            {
                // Make sure bit shifts are clamped in range of 16 bit integer            
                lua_rawgeti(L, 3, i);
                filter.maskBits |= 1 << MAX(MIN(luaL_checkinteger(L, -1), 15), 0);
                lua_pop(L, 1);
            }        
            for (b2Fixture* f = body->body->GetFixtureList(); f; f = f->GetNext())
            {
                f->SetFilterData(filter);
            }        
        }
        
        return 1;
    }        
    else if ( strcmp(c, "info") == 0)
    {
        lua_pushvalue(L, 3);
        lua_setfenv(L, 1);
        
//        // unref previous info value
//        if (body->infoRef != LUA_NOREF && body->infoRef != LUA_REFNIL)
//        {
//            luaL_unref(L, LUA_REGISTRYINDEX, body->infoRef);
//        }
//        // ref new info value
//        lua_pushvalue(L, 3);
//        body->infoRef = luaL_ref(L, LUA_REGISTRYINDEX);                
        return 1;
    }    
    
    return 0;
}

static int Ltostring(lua_State *L)
{
    body_wrapper_type *poly=(body_wrapper_type*)Pget(L,1);
    char s[128];
    sprintf(s,"rigidbody: %p", poly);
    lua_pushstring(L,s);
    return 1;
}

static int Ldestroy(lua_State *L)
{
    body_wrapper_type *rb = checkRigidbody(L, 1);
    if (rb->body)
    {
        [getPhysicsAPI() destroyBody:rb->body];
        rb->body = NULL;
    }
    return 0;
}


static int Lgc(lua_State *L)
{
    body_wrapper_type *poly = Pget(L,1);
    unregister_obj(L, poly);
    
//    if (poly->infoRef != LUA_NOREF && poly->infoRef != LUA_REFNIL)
//    {
//        luaL_unref(L, LUA_REGISTRYINDEX, poly->infoRef);
//    }
    
    // clean up polygon points
    if (poly->pointCount > 0)
    {
        delete[] poly->x;
        delete[] poly->y;
    }
    
    if (poly->body)
    {
        [getPhysicsAPI() destroyBody:poly->body];        
    }
    return 1;
}

static int Leq(lua_State *L)
{
    body_wrapper_type *p1 = checkRigidbody(L, -1);
    body_wrapper_type *p2 = checkRigidbody(L, -2);
    
    if( p1 && p2 )
    {
        lua_pushboolean(L, p1 == p2);                        
        return 1;
    }    
    return 0;
}

static int LapplyForce(lua_State *L)
{
    int numArgs = lua_gettop(L);
    
    body_wrapper_type *poly = checkRigidbody(L, 1);
    if( poly && poly->body && numArgs >= 2 )
    {
        lua_Number* force = checkvec2(L, 2);
        if (numArgs == 2)
        {
            poly->body->ApplyForceToCenter(b2Vec2(force[0], force[1]));
        }
        else if (numArgs == 3)
        {
            lua_Number* point = checkvec2(L, 3);
            poly->body->ApplyForce(b2Vec2(force[0], force[1]), b2Vec2(point[0] * INV_PTM_RATIO, point[1] * INV_PTM_RATIO));
        }        
    }
    
    return 0;
}

static int LapplyTorque(lua_State *L)
{
    int numArgs = lua_gettop(L);
    
    body_wrapper_type *poly = checkRigidbody(L, 1);
    if( poly && poly->body && numArgs == 2 )
    {
        lua_Number torque = luaL_checknumber(L, 2);
        poly->body->ApplyTorque(torque);        
    }    
    return 0;
}


static int LtestPoint(lua_State *L)
{    
    body_wrapper_type *poly = checkRigidbody(L, 1);
    if( poly && poly->body)
    {
        lua_Number* vec = checkvec2(L, 2);
        if (vec != NULL)
        {
            b2Vec2 worldPoint(vec[0] * INV_PTM_RATIO, vec[1] * INV_PTM_RATIO);
            
            bool test = false;
            for (b2Fixture* f = poly->body->GetFixtureList(); f; f = f->GetNext())
            {
                if (f->TestPoint(worldPoint))
                {
                    test = true;
                    break;
                }
            }
            
            lua_pushboolean(L, test);        
            return 1;                    
        }
    }
    
    return 0;
}

static int LtestOverlap(lua_State *L)
{
    body_wrapper_type *bodyA = checkRigidbody(L, 1);    
    if( bodyA && bodyA->body)
    {        
        if (lua_gettop(L) == 2)
        {
            body_wrapper_type *bodyB = checkRigidbody(L, 2);
            if (bodyB && bodyB->body && bodyA != bodyB)
            {
                bool test = false;                
                for (b2Fixture* fA = bodyA->body->GetFixtureList(); fA; fA = fA->GetNext())
                {                    
                    for (b2Fixture* fB = bodyB->body->GetFixtureList(); fB; fB = fB->GetNext())
                    {
                        if (b2TestOverlap(fA->GetShape(), 0, fB->GetShape(), 0, bodyA->body->GetTransform(), bodyB->body->GetTransform()))
                        {
                            test = true;
                            break;
                        }
                    }             
                    if (test)
                    {
                        break;
                    }
                }        
                lua_pushboolean(L, test);
                return 1;
            }
        }
        
    }
    return 0;
}

static int LgetLocalPoint(lua_State *L)
{    
    body_wrapper_type *poly = checkRigidbody(L, 1);
    if( poly && poly->body)
    {
        lua_Number* vec = checkvec2(L, 2);
        if (vec != NULL)
        {
            b2Vec2 worldPoint(vec[0] * INV_PTM_RATIO, vec[1] * INV_PTM_RATIO);
            b2Vec2 localPoint;
            
            if (poly->interpolate)
            {
                b2Transform tx;
                tx.Set(b2Vec2(poly->renderX, poly->renderY), poly->renderAngle);
                localPoint = b2MulT(tx, worldPoint);
            }
            else
            {
                localPoint = poly->body->GetLocalPoint(worldPoint);
            }
            
            pushvec2(L, localPoint.x * PTM_RATIO, localPoint.y * PTM_RATIO);            
        }
        return 1;        
    }
    
    return 0;
}

static int LgetWorldPoint(lua_State *L)
{    
    body_wrapper_type *poly = checkRigidbody(L, 1);
    if(poly && poly->body)
    {
        lua_Number* vec = checkvec2(L, 2);
        if (vec != NULL)
        {
            b2Vec2 localPoint(vec[0] * INV_PTM_RATIO, vec[1] * INV_PTM_RATIO);            
            b2Vec2 worldPoint;
            
            if (poly->interpolate)
            {
                b2Transform tx;
                tx.Set(b2Vec2(poly->renderX, poly->renderY), poly->renderAngle);
                worldPoint = b2Mul(tx, localPoint);
            }
            else
            {
                worldPoint = poly->body->GetWorldPoint(localPoint);
            }
            
            
            pushvec2(L, worldPoint.x * PTM_RATIO, worldPoint.y * PTM_RATIO);
            return 1;                    
        }
    }
    
    return 0;
}

static int LgetLinearVelocityFromWorldPoint(lua_State *L)
{
    body_wrapper_type *rb = checkRigidbody(L, 1);
    if(rb && rb->body)
    {
        lua_Number* vec = checkvec2(L, 2);        

        if (vec != NULL)
        {
            b2Vec2 worldPoint(vec[0] * INV_PTM_RATIO, vec[1] * INV_PTM_RATIO);            
            b2Vec2 velocity = rb->body->GetLinearVelocityFromWorldPoint(worldPoint);            
            pushvec2(L, velocity.x * PTM_RATIO, velocity.y * PTM_RATIO);
            return 1;
        }
    }
    
    return 0;
}

static int LgetLinearVelocityFromLocalPoint(lua_State *L)
{
    body_wrapper_type *rb = checkRigidbody(L, 1);
    if(rb && rb->body)
    {
        lua_Number* vec = checkvec2(L, 2);        
        
        if (vec != NULL)
        {
            b2Vec2 localPoint(vec[0] * INV_PTM_RATIO, vec[1] * INV_PTM_RATIO);            
            b2Vec2 velocity = rb->body->GetLinearVelocityFromLocalPoint(localPoint);            
            pushvec2(L, velocity.x * PTM_RATIO, velocity.y * PTM_RATIO);
            return 1;
        }
    }
    
    return 0;
}


//static int LsetFilterCategories(lua_State *L)
//{
//    body_wrapper_type *poly = checkRigidbody(L, 1);
//    int numArgs = lua_gettop(L);    
//    if( poly && poly->body && numArgs > 1)
//    {
//        b2Filter filter(poly->body->GetFixtureList()->GetFilterData());
//        filter.categoryBits = 0;
//        for (int i = 2; i <= numArgs; i++)
//        {
//            // Make sure bit shifts are clamped in range of 16 bit integer            
//            filter.categoryBits |= 2 << MAX(MIN(luaL_checkinteger(L, i), 15), 0);
//        }        
//        for (b2Fixture* f = poly->body->GetFixtureList(); f; f = f->GetNext())
//        {
//            f->SetFilterData(filter);
//        }        
//    }
//    
//    return 0;
//}
//
//static int LsetFilterMask(lua_State *L)
//{
//    body_wrapper_type *poly = checkRigidbody(L, 1);
//    int numArgs = lua_gettop(L);    
//    if( poly && poly->body && numArgs > 1)
//    {
//        b2Filter filter(poly->body->GetFixtureList()->GetFilterData());
//        filter.maskBits = 0;
//        for (int i = 2; i <= numArgs; i++)
//        {
//            // Make sure bit shifts are clamped in range of 16 bit integer
//            filter.maskBits |= 2 << MAX(MIN(luaL_checkinteger(L, i), 15), 0);
//        }        
//        for (b2Fixture* f = poly->body->GetFixtureList(); f; f = f->GetNext())
//        {
//            f->SetFilterData(filter);
//        }        
//    }
//    
//    return 0;
//}

static const luaL_reg R[] =
{
    { "__index", Lget },
	{ "__newindex",	Lset},    
    { "__tostring", Ltostring },
    { "__eq", Leq},
    { "__gc", Lgc },
    { "applyForce", LapplyForce },
    { "applyTorque", LapplyTorque },
    { "testPoint", LtestPoint },
    { "testOverlap", LtestOverlap },
    { "getLocalPoint", LgetLocalPoint },
    { "getWorldPoint", LgetWorldPoint },
    { "getLinearVelocityFromWorldPoint", LgetLinearVelocityFromWorldPoint },
    { "getLinearVelocityFromLocalPoint", LgetLinearVelocityFromLocalPoint },    
//    { "setFilterCategories", LsetFilterCategories },
//    { "setFilterMask", LsetFilterMask },   
    { "destroy", Ldestroy },
    { NULL, NULL }
};

static const luaL_reg P[] =
{
    { RIGIDBODY_TYPE, Lnew },
    { NULL, NULL }
};

LUALIB_API int luaopen_rigidbody(lua_State *L)
{
    luaL_newmetatable(L,RIGIDBODY_TYPE);    
    luaL_openlib(L,NULL,R,0);
    //lua_register(L,RIGIDBODY_TYPE,Lnew);    
    luaL_openlib(L,CODIFY_PHYSICSLIBNAME, P, 0);
    return 1;
}

