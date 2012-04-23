//
//  joint.c
//  Codea
//
//  Created by John Millard on 10/11/11.
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

#include <stdio.h>
#include "joint.h"
#include "body.h"
#import "PhysicsManager.h"
#import "PhysicsCommands.h"

#define JOINT_TYPE   "joint"
#define JOINT_SIZE   sizeof(joint_wrapper_type)

extern float PTM_RATIO;

joint_wrapper_type* checkJoint(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        joint_wrapper_type *poly = (joint_wrapper_type*)luaL_checkudata(L, i, JOINT_TYPE);        
        luaL_argcheck(L, poly != NULL, 1, "`joint' expected");        
        return poly;
    }    
    return NULL;
}

static joint_wrapper_type* Pnew( lua_State *L )
{
    joint_wrapper_type *joint = (joint_wrapper_type*)lua_newuserdata(L, JOINT_SIZE);
    luaL_getmetatable(L, JOINT_TYPE);
    lua_setmetatable(L, -2);
    return joint;
}

static int Lnew(lua_State *L)			/** joint(t, b1, b1, a) */
{
    if (lua_gettop(L) >= 4)
    {
        int type = luaL_checkinteger(L, 1);    
        body_wrapper_type *bA = (body_wrapper_type*)lua_touserdata(L,2);
        body_wrapper_type *bB = (body_wrapper_type*)lua_touserdata(L,3);    
        lua_Number* a = checkvec2(L, 4);
        lua_Number* b = lua_gettop(L) >= 5 ? b = checkvec2(L, 5) : NULL;
        lua_Number maxLen = lua_gettop(L) >= 6 ? luaL_checknumber(L, 6) : 0;
    
        if (bA && bB && a)
        {
            b2Vec2 anchorA(a[0] * INV_PTM_RATIO, a[1] * INV_PTM_RATIO);    
            b2Vec2 anchorB = b != NULL ? b2Vec2(b[0] * INV_PTM_RATIO, b[1] * INV_PTM_RATIO) : b2Vec2(0,0);
            
            b2Joint* joint = [getPhysicsAPI() createJoint:(b2JointType)type bodyA:bA->body bodyB:bB->body anchorA:anchorA anchorB:anchorB maxLength:maxLen * INV_PTM_RATIO];
            
            joint_wrapper_type *j;
            j = Pnew(L);    
            j->joint = joint;
            
            // Save reference to bodyA
            lua_pushvalue(L, 2);
            j->bodyRefA = luaL_ref(L, LUA_REGISTRYINDEX);

            // Save reference to bodyB
            lua_pushvalue(L, 3);
            j->bodyRefB = luaL_ref(L, LUA_REGISTRYINDEX);
            
            register_obj(L, -1, j);
            joint->SetUserData(j);
            
            return 1;
        }
    }
    return 0;
}


static int Lget( lua_State *L)
{
    joint_wrapper_type *j = checkJoint(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if (j->joint)
    {                        
        if (j->joint->GetType() == e_revoluteJoint)
        {
            b2RevoluteJoint* joint = (b2RevoluteJoint*)j->joint;
            if ( strcmp(c, "enableMotor") == 0 )
            {
                lua_pushboolean(L, joint->IsMotorEnabled());
                return 1;
            }
            else if ( strcmp(c, "motorSpeed") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetMotorSpeed()));
                return 1;            
            }        
            else if ( strcmp(c, "maxMotorTorque") == 0 )
            {
                lua_pushnumber(L, joint->GetMaxMotorTorque());
                return 1;            
            }                
            else if ( strcmp(c, "enableLimit") == 0 )
            {
                lua_pushboolean(L, joint->IsLimitEnabled());
                return 1;            
            }
            else if ( strcmp(c, "lowerLimit") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetLowerLimit()));
                return 1;            
            }
            else if ( strcmp(c, "upperLimit") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetUpperLimit()));
                return 1;            
            }       
            else if ( strcmp(c, "jointAngle") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetJointAngle()));
                return 1;            
            }       
            else if ( strcmp(c, "jointSpeed") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetJointSpeed()));
                return 1;            
            }               
            else if ( strcmp(c, "referenceAngle") == 0 )
            {
                lua_pushnumber(L, joint->GetReferenceAngle());
                return 1;            
            }       
            else if ( strcmp(c, "collideConnected") == 0 )
            {
                lua_pushboolean(L, joint->GetCollideConnected());
                return 1;            
            }               
        }
        else if (j->joint->GetType() == e_distanceJoint)
        {
            b2DistanceJoint* joint = (b2DistanceJoint*)j->joint;
            
            if ( strcmp(c, "length") == 0 )
            {
                lua_pushnumber(L, joint->GetLength() * PTM_RATIO);
                return 1;
            }        
            else if ( strcmp(c, "frequency") == 0 )
            {
                lua_pushnumber(L, joint->GetFrequency());
                return 1;            
            }                
            else if ( strcmp(c, "dampingRatio") == 0 )
            {
                lua_pushnumber(L, joint->GetDampingRatio());
                return 1;            
            } 
        }
        else if (j->joint->GetType() == e_weldJoint)
        {
            b2WeldJoint* joint = (b2WeldJoint*)j->joint;
            
            if ( strcmp(c, "frequency") == 0 )
            {
                lua_pushnumber(L, joint->GetFrequency());
                return 1;            
            }                
            else if ( strcmp(c, "dampingRatio") == 0 )
            {
                lua_pushnumber(L, joint->GetDampingRatio());
                return 1;            
            }   
        }
        else if (j->joint->GetType() == e_prismaticJoint)
        {
            b2PrismaticJoint* joint = (b2PrismaticJoint*)j->joint;
            if ( strcmp(c, "enableMotor") == 0 )
            {
                lua_pushboolean(L, joint->IsMotorEnabled());
                return 1;
            }
            else if ( strcmp(c, "motorSpeed") == 0 )
            {
                lua_pushnumber(L, joint->GetMotorSpeed() * PTM_RATIO);
                return 1;            
            }                    
            else if ( strcmp(c, "maxMotorForce") == 0 )
            {
                lua_pushnumber(L, joint->GetMaxMotorForce() * PTM_RATIO);
                return 1;            
            }                                
            else if ( strcmp(c, "referenceAngle") == 0 )
            {
                lua_pushnumber(L, RADIANS_TO_DEGREES(joint->GetReferenceAngle()));
                return 1;            
            }                    
            else if ( strcmp(c, "jointTranslation") == 0 )
            {
                lua_pushnumber(L, joint->GetJointTranslation() * PTM_RATIO);
                return 1;
            }
            else if ( strcmp(c, "jointSpeed") == 0 )
            {
                lua_pushnumber(L, joint->GetJointSpeed() * PTM_RATIO);
                return 1;
            }            
            else if ( strcmp(c, "enableLimit") == 0 )
            {
                lua_pushboolean(L, joint->IsLimitEnabled());
                return 1;            
            }            
            else if ( strcmp(c, "lowerLimit") == 0 )
            {
                lua_pushnumber(L, joint->GetLowerLimit() * PTM_RATIO);
                return 1;            
            }
            else if ( strcmp(c, "upperLimit") == 0 )
            {
                lua_pushnumber(L, joint->GetUpperLimit() * PTM_RATIO);
                return 1;            
            }        
            else if ( strcmp(c, "motorForce") == 0 )
            {
                float force = joint->GetMotorForce(getPhysicsAPI().invTimeStep);
                lua_pushnumber(L, force);
                return 1;
            }            
        }
        
        // Common methods
        if ( strcmp(c, "type") == 0 )
        {
            lua_pushnumber(L, (int)j->joint->GetType());
            return 1;
        }                
        else if ( strcmp(c, "anchorA") == 0 )
        {
            b2Vec2 anchor = j->joint->GetAnchorA();
            pushvec2(L, anchor.x * PTM_RATIO, anchor.y * PTM_RATIO);
            return 1;            
        }               
        else if ( strcmp(c, "anchorB") == 0 )
        {
            b2Vec2 anchor = j->joint->GetAnchorB();
            pushvec2(L, anchor.x * PTM_RATIO, anchor.y * PTM_RATIO);
            return 1;            
        }    
        else if ( strcmp(c, "bodyA") == 0 )
        {
            push_obj(L, (body_wrapper_type*)j->joint->GetBodyA()->GetUserData());
            return 1;
        }
        else if ( strcmp(c, "bodyB") == 0 )
        {
            push_obj(L, (body_wrapper_type*)j->joint->GetBodyB()->GetUserData());
            return 1;
        }    
        else if ( strcmp(c, "reactionTorque") == 0 )
        {
            float torque = j->joint->GetReactionTorque(getPhysicsAPI().invTimeStep);
            lua_pushnumber(L, torque);
            return 1;
        }
        else if ( strcmp(c, "reactionForce") == 0 )
        {
            b2Vec2 force = j->joint->GetReactionForce(getPhysicsAPI().invTimeStep);
            pushvec2(L, force.x * PTM_RATIO, force.y * PTM_RATIO);
            return 1;
        }        
    }

    
    {        
        //Load the metatable and value for key
        luaL_getmetatable(L, JOINT_TYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);    
    }
    return 1;
}

static int Lset(lua_State *L)
{   
    joint_wrapper_type *j = checkJoint(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if (j->joint == NULL) return 0;
    
    if (j->joint->GetType() == e_revoluteJoint)
    {
        b2RevoluteJoint* joint = (b2RevoluteJoint*)j->joint;
        if ( strcmp(c, "enableMotor") == 0 )
        {
            joint->EnableMotor(lua_toboolean(L, 3));
        }
        else if ( strcmp(c, "motorSpeed") == 0 )
        {
            joint->SetMotorSpeed(DEGREES_TO_RADIANS(luaL_checknumber(L, 3)));
        }        
        else if ( strcmp(c, "maxMotorTorque") == 0 )
        {
            joint->SetMaxMotorTorque(luaL_checknumber(L, 3));
        }                
        else if ( strcmp(c, "enableLimit") == 0 )
        {
            joint->EnableLimit(lua_toboolean(L, 3));
        }
        else if ( strcmp(c, "lowerLimit") == 0 )
        {
            joint->SetLimits(DEGREES_TO_RADIANS(luaL_checknumber(L, 3)), joint->GetUpperLimit());
        }
        else if ( strcmp(c, "upperLimit") == 0 )
        {
            joint->SetLimits(joint->GetLowerLimit(), DEGREES_TO_RADIANS(luaL_checknumber(L, 3)));
        }        
    }
    else if (j->joint->GetType() == e_distanceJoint)
    {
        b2DistanceJoint* joint = (b2DistanceJoint*)j->joint;

        if ( strcmp(c, "length") == 0 )
        {
            joint->SetLength(luaL_checknumber(L, 3) * INV_PTM_RATIO);
        }        
        else if ( strcmp(c, "frequency") == 0 )
        {
            joint->SetFrequency(luaL_checknumber(L, 3));
        }                
        else if ( strcmp(c, "dampingRatio") == 0 )
        {
            joint->SetDampingRatio(luaL_checknumber(L, 3));
        }        
    }
    else if (j->joint->GetType() == e_weldJoint)
    {
        b2WeldJoint* joint = (b2WeldJoint*)j->joint;
        
        if ( strcmp(c, "frequency") == 0 )
        {
            joint->SetFrequency(luaL_checknumber(L, 3));
        }                
        else if ( strcmp(c, "dampingRatio") == 0 )
        {
            joint->SetDampingRatio(luaL_checknumber(L, 3));
        }        
    }
    else if (j->joint->GetType() == e_prismaticJoint)
    {
        b2PrismaticJoint* joint = (b2PrismaticJoint*)j->joint;
        
        if ( strcmp(c, "enableMotor") == 0 )
        {
            joint->EnableMotor(lua_toboolean(L, 3));
        }
        else if ( strcmp(c, "motorSpeed") == 0 )
        {
            joint->SetMotorSpeed(luaL_checknumber(L, 3) * INV_PTM_RATIO);
        }
        else if ( strcmp(c, "maxMotorForce") == 0 )
        {            
            joint->SetMaxMotorForce(luaL_checknumber(L, 3));
        }                        
        else if ( strcmp(c, "enableLimit") == 0 )
        {
            joint->EnableLimit(lua_toboolean(L, 3));
        }
        else if ( strcmp(c, "lowerLimit") == 0 )
        {
            joint->SetLimits(luaL_checknumber(L, 3) * INV_PTM_RATIO, joint->GetUpperLimit());
        }
        else if ( strcmp(c, "upperLimit") == 0 )
        {
            joint->SetLimits(joint->GetLowerLimit(), luaL_checknumber(L, 3) * INV_PTM_RATIO);
        }        
        

    }
    
    
    return 1;
}

static int Ltostring(lua_State *L)
{
    joint_wrapper_type *j = checkJoint(L,1);
    char s[128];
    sprintf(s,"joint: %p", j);
    lua_pushstring(L,s);
    return 1;
}

static int Ldestroy(lua_State *L)
{
    joint_wrapper_type *j = checkJoint(L, 1);
    if (j->joint)
    {
        luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefA);
        luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefB);        
        [getPhysicsAPI() destroyJoint:j->joint];
        j->joint = NULL;
    }
    return 0;
}

static int Lgc(lua_State *L)
{
    joint_wrapper_type *j = checkJoint(L, 1);
    unregister_obj(L, j);
    
    if (j->joint)
    {
        luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefA);
        j->bodyRefA = LUA_NOREF;
        luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefB);                        
        j->bodyRefB = LUA_NOREF;
        [getPhysicsAPI() destroyJoint:j->joint];        
    }
    return 1;
}

static const luaL_reg R[] =
{
    { "__index", Lget },
	{ "__newindex",	Lset},
    { "__tostring", Ltostring },
    { "__gc", Lgc },
    { "destroy", Ldestroy },
    { NULL, NULL }
};

static const luaL_reg P[] =
{
    { JOINT_TYPE, Lnew },
    { NULL, NULL }
};

LUALIB_API int luaopen_joint(lua_State *L)
{
    luaL_newmetatable(L, JOINT_TYPE);    
    luaL_openlib(L, NULL, R, 0);
    //lua_register(L, JOINT_TYPE, Lnew);    
    luaL_openlib(L, CODIFY_PHYSICSLIBNAME, P, 0);
    return 1;
}



