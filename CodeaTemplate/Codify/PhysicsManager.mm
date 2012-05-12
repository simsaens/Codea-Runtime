//
//  PhysicsManager.mm
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

#import "PhysicsManager.h"

#include <Box2d.h>
#include <Box2D/ConvexDecomposition/b2Polygon.h>

#ifdef __cplusplus
extern "C" {
#endif     
#import "LuaState.h"     
#import "lua.h"
#import "lauxlib.h"
#import "object_reg.h"
#import "vec2.h"
#import "body.h"
#import "joint.h"
#import "contact.h"
#ifdef __cplusplus
}
#endif    

float PTM_RATIO = 0;

@implementation PhysicsManager

@synthesize world;
@synthesize alpha;
@synthesize timeStep;
@synthesize invTimeStep;

-(id) init
{
    self = [super init];
    if (self)
    {
        [self reset];
    }
    return self;
}

-(void) reset
{
    if (world)
    {
        delete world;
        delete contactListener;
        delete destructionListener;
    }
    world = new b2World(b2Vec2(DEFAULT_WORLD_GRAVITY_X, DEFAULT_WORLD_GRAVITY_Y));   
    world->SetContinuousPhysics(true);
    contactListener = new ContactListener();
    destructionListener = new DestructionListener();
    world->SetContactListener(contactListener);
    world->SetDestructionListener(destructionListener);
    
    velocityIterations = 10;
    positionIterations = 8;
    timeStep = 1.0f / 60.0f;
    invTimeStep = 60.0f;
    accum = 0;
    alpha = 0;
    PTM_RATIO = 32.0f;
    paused = NO;
}

-(void) setVelocityIterations:(int)velIter positionIterations:(int)posIter
{
    velocityIterations = velIter;
    positionIterations = posIter;
}

-(void) setPixelToMeterRatio:(float)ptm
{
    PTM_RATIO = MAX(1, ptm);
}

-(float) pixelToMeterRatio
{
    return PTM_RATIO;
}

-(void) step:(float)dt
{
    if (!paused)
    {
        lua_State* L = [LuaState sharedInstance].L;      
        
        // based on http://gafferongames.com/game-physics/fix-your-timestep/
        accum += dt;
        while (accum >= timeStep)
        {
            accum -= timeStep;
            
            if (accum < timeStep)
            {
                // Save current physics transforms
                for (b2Body* body = world->GetBodyList(); body; body = body->GetNext())
                {
                    b2Vec2 pos = body->GetPosition();
                    body_wrapper_type* bw = (body_wrapper_type*)body->GetUserData();
                    bw->prevX = pos.x;
                    bw->prevY = pos.y;
                    bw->prevAngle = body->GetAngle();
                }
            }
            
            world->Step(timeStep, velocityIterations, positionIterations); 
            world->ClearForces();
            
            [self processContacts:L];
            
            // TODO call physics update callback
        }
        
        alpha = accum / dt;
        
        for (b2Body* body = world->GetBodyList(); body; body = body->GetNext())
        {
            b2Vec2 pos = body->GetPosition();
            body_wrapper_type* bw = (body_wrapper_type*)body->GetUserData();
            bw->renderX = pos.x * alpha + bw->prevX * (1-alpha) ;
            bw->renderY = pos.y * alpha + bw->prevY * (1-alpha) ;
            bw->renderAngle = body->GetAngle() * alpha + bw->prevAngle * (1-alpha);
        }
        
        // TODO sub-step interpolation (make optional)
    }
}

-(void) setPaused:(BOOL)p
{
    paused = p;
}

-(BOOL) processContacts:(lua_State*)L
{        
    LuaState *script = [LuaState sharedInstance];
    
    lua_getglobal(L, "collide");
    if( !lua_isfunction(L, -1) )
    {         
        // Erase stale contacts
        std::vector<ContactPoint>::iterator iter = contactListener->contacts.begin();
        while (iter != contactListener->contacts.end())
        {
            ContactPoint& cp = (*iter);            
            if (cp.state == CONTACT_ENDED)
            {
                iter = contactListener->contacts.erase(iter);
            }
            else if (cp.state == CONTACT_BEGAN)
            {
                cp.state = CONTACT_PERSIST;
                ++iter;
            }
            else if (cp.state == CONTACT_PERSIST)
            {
                ++iter;
            }
            else
            {
                ++iter;
            }            
        }        
        
        lua_pop(L,1);
        return NO;
    }
    else
    {
        //NSLog(@"Contact count = %d, Body count = %d", contactListener->contacts.size(), world->GetBodyCount());
        
        std::vector<ContactPoint>::iterator iter = contactListener->contacts.begin();
        while (iter != contactListener->contacts.end())
        {
            ContactPoint& cp = (*iter);
            
            push_contact(L, &cp);
            
            //Call "collide" and print any errors
            [script printErrors:lua_pcall(L, 1, 0, 0)];
            
            lua_getglobal(L, "collide");              
            
            if (cp.state == CONTACT_ENDED)
            {
                iter = contactListener->contacts.erase(iter);
            }
            else if (cp.state == CONTACT_BEGAN)
            {
                cp.state = CONTACT_PERSIST;
                ++iter;
            }
            else if (cp.state == CONTACT_PERSIST)
            {
                ++iter;
            }
            else
            {
                ++iter;
            }            
        }    
        lua_pop(L, 1); //remove extra function
        return YES;
    }
}

-(b2Body*) createCircle:(float)x y:(float)y radius:(float)radius
{
    b2BodyDef bd;
    bd.position = b2Vec2(x * INV_PTM_RATIO, y * INV_PTM_RATIO);
    bd.type = b2_dynamicBody;
    b2Body* body = world->CreateBody(&bd);

    b2FixtureDef fd;    
    fd.density = 1.0f;
    b2CircleShape shape;
    shape.m_radius = radius * INV_PTM_RATIO;    
    fd.shape = &shape;
    
    body->CreateFixture(&fd);
    
    //DBLog(@"Created circle (%f, %f, %f)!", x, y, radius);
        
    return body;
}

-(b2Body*) createPolygon:(CGPoint)position x:(float*)x y:(float*)y numPoints:(int)numPoints
{
    b2BodyDef bd;
    bd.position = b2Vec2(position.x * INV_PTM_RATIO, position.y * INV_PTM_RATIO);
    bd.type = b2_dynamicBody;
    
    // Convert points to physics scale
    b2Polygon polygon(x,y,numPoints);
    for (int i = 0; i < numPoints; i++)
    {
        polygon.x[i] *= INV_PTM_RATIO;
        polygon.y[i] *= INV_PTM_RATIO;        
    }

    if (!polygon.IsCCW())
    {
        ReversePolygon(polygon.x, polygon.y, polygon.nVertices);
    }
    
    b2Body* body = world->CreateBody(&bd);        
    b2FixtureDef fd;    
    fd.density = 1.0f;
    
    // TODO: error handling for bad polygons
    DecomposeConvexAndAddTo(&polygon, body, &fd);            
    return body;
}

-(b2Body*) createChain:(CGPoint)position x:(float*)x y:(float*)y numPoints:(int)numPoints loop:(BOOL)loop
{
    b2BodyDef bd;
    bd.position = b2Vec2(position.x * INV_PTM_RATIO, position.y * INV_PTM_RATIO);
    bd.type = b2_staticBody;
    
    b2Vec2* vs = new b2Vec2[numPoints];
    
    for (int i = 0; i < numPoints; i++)
    {
        vs[i].x = x[i] * INV_PTM_RATIO;
        vs[i].y = y[i] * INV_PTM_RATIO;        
    }
        
    b2Body* body = world->CreateBody(&bd);        
    b2FixtureDef fd;    
    fd.density = 0.0f;
    
    b2ChainShape chainShape;
    fd.shape = &chainShape;
    if (loop)
    {
        chainShape.CreateLoop(vs, numPoints);
    }
    else
    {
        chainShape.CreateChain(vs, numPoints);        
    }

    body->CreateFixture(&fd);
    
    delete[] vs;

    return body;
}

-(b2Body*) createEdge:(CGPoint)position pointA:(CGPoint)pointA pointB:(CGPoint)pointB
{
    b2BodyDef bd;
    bd.position = b2Vec2(position.x * INV_PTM_RATIO, position.y * INV_PTM_RATIO);
    bd.type = b2_staticBody;

    b2Body* body = world->CreateBody(&bd);        
    b2FixtureDef fd;    
    fd.density = 0.0f;

    b2EdgeShape edgeShape;
    edgeShape.Set(b2Vec2(pointA.x * INV_PTM_RATIO, pointA.y * INV_PTM_RATIO), b2Vec2(pointB.x * INV_PTM_RATIO, pointB.y * INV_PTM_RATIO));    
    fd.shape = &edgeShape;
    
    body->CreateFixture(&fd);
    return body;
}

-(void) destroyBody:(b2Body*)body
{
    world->DestroyBody(body);
}

-(b2Joint*) createJoint:(b2JointType)type bodyA:(b2Body*)bodyA bodyB:(b2Body*)bodyB anchorA:(b2Vec2)anchorA anchorB:(b2Vec2)anchorB maxLength:(float)maxLength
{
    if (type == e_revoluteJoint)
    {
        b2RevoluteJointDef jd;
        jd.Initialize(bodyA, bodyB, anchorA);
        return world->CreateJoint(&jd);
    }
    if (type == e_weldJoint)
    {
        b2WeldJointDef jd;
        jd.Initialize(bodyA, bodyB, anchorA);
        return world->CreateJoint(&jd);
    }    
    else if (type == e_distanceJoint)
    {
        b2DistanceJointDef jd;
        jd.Initialize(bodyA, bodyB, anchorA, anchorB);
        return world->CreateJoint(&jd);
    }
    else if (type == e_ropeJoint)
    {
        b2RopeJointDef jd;
        jd.bodyA = bodyA;
        jd.bodyB = bodyB;        
        jd.localAnchorA = bodyA->GetLocalPoint(anchorA);
        jd.localAnchorB = bodyB->GetLocalPoint(anchorB);        
        jd.maxLength = maxLength;
        return world->CreateJoint(&jd);
    }
    else if (type == e_prismaticJoint)
    {
        b2PrismaticJointDef jd;
        // anchorB is an axis rather than anchor
        anchorB.x *= PTM_RATIO; 
        anchorB.y *= PTM_RATIO;
        jd.Initialize(bodyA, bodyB, anchorA, anchorB);
        return world->CreateJoint(&jd);
    }
    
    return NULL;
}

-(void) destroyJoint:(b2Joint*)joint
{   
    NSAssert(joint != NULL, @"Cannot destroy NULL joint");
    world->DestroyJoint(joint);
}

-(void) dealloc
{
    if (world)
    {
        delete world;
        delete contactListener;        
        delete destructionListener;
    }
    [super dealloc];
}

@end

void ContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
{
//    b2Fixture* fA = contact->GetFixtureA();
//    b2Fixture* fB = contact->GetFixtureB();
//
//    ContactPoint temp;
//    temp.fixtureA = fA;
//    temp.fixtureB = fB;
//    
//    // Update existing contact if it exists
//    std::vector<ContactPoint>::iterator pos;
//    pos = std::find(contacts.begin(), contacts.end(), temp);
//    if (pos != contacts.end()) 
//    {
//        ContactPoint& cp = *pos;
//
//        b2WorldManifold worldManifold;
//        contact->GetWorldManifold(&worldManifold);    
//        
//        cp.normal = worldManifold.normal;
//        cp.position = b2Vec2(0,0);
//        cp.pointCount = contact->GetManifold()->pointCount;
//        for (int i = 0; i < cp.pointCount ; i++)
//        {
//            cp.points[i] = worldManifold.points[i];
//            cp.position += worldManifold.points[i];
//        }
//        cp.position *= (1.0f / cp.pointCount);
//    }        
}

void ContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse)
{
    b2Fixture* fA = contact->GetFixtureA();
    b2Fixture* fB = contact->GetFixtureB();
    
    ContactPoint temp;
    temp.fixtureA = fA;
    temp.fixtureB = fB;
    temp.childIndexA = contact->GetChildIndexA();
    temp.childIndexB = contact->GetChildIndexB();
    
    
    // Update existing contact if it exists
    std::vector<ContactPoint>::iterator pos;
    pos = std::find(contacts.begin(), contacts.end(), temp);
    if (pos != contacts.end()) 
    {
        ContactPoint& cp = *pos;
        cp.touching = contact->IsTouching();
        
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);            
        
        cp.normal = worldManifold.normal;
        cp.position = b2Vec2(0,0);        
        cp.normalImpulse = 0;
        cp.tangentImpulse = 0;
        cp.pointCount = contact->GetManifold()->pointCount;
        for (int i = 0; i < cp.pointCount ; i++)
        {
            cp.points[i] = worldManifold.points[i];
            cp.position += worldManifold.points[i];
            cp.normalImpulses[i] = impulse->normalImpulses[i];
            cp.tangentImpulses[i] = impulse->tangentImpulses[i];
            cp.normalImpulse += cp.normalImpulses[i];
            cp.tangentImpulse += cp.tangentImpulses[i];
        }
        float inv = (1.0f / cp.pointCount);
        cp.position *= inv;
        cp.normalImpulse *= inv;
        cp.tangentImpulse *= inv;        
    }            
}

void ContactListener::BeginContact(b2Contact* contact)
{
    b2Fixture* fA = contact->GetFixtureA();
    b2Fixture* fB = contact->GetFixtureB();
    
    ContactPoint cp;
    cp.ref = -1;
    cp.ID = currentID++;
    cp.fixtureA = fA;
    cp.fixtureB = fB;
    cp.childIndexA = contact->GetChildIndexA();
    cp.childIndexB = contact->GetChildIndexB();
    cp.state = CONTACT_BEGAN;
    cp.touching = contact->IsTouching();
    
    b2WorldManifold worldManifold;
	contact->GetWorldManifold(&worldManifold);    
    
    cp.normal = worldManifold.normal;
    cp.position = b2Vec2(0,0);
    cp.pointCount = contact->GetManifold()->pointCount;
    for (int i = 0; i < cp.pointCount ; i++)
    {
        cp.points[i] = worldManifold.points[i];
        cp.position += worldManifold.points[i];
    }
    cp.position *= (1.0f / cp.pointCount);
    
    contacts.push_back(cp);
}

void ContactListener::EndContact(b2Contact* contact)
{
    b2Fixture* fA = contact->GetFixtureA();
    b2Fixture* fB = contact->GetFixtureB();
    
    ContactPoint cp;
    cp.fixtureA = fA;
    cp.fixtureB = fB;
    cp.childIndexA = contact->GetChildIndexA();
    cp.childIndexB = contact->GetChildIndexB();

    std::vector<ContactPoint>::iterator pos;
    pos = std::find(contacts.begin(), contacts.end(), cp);
    if (pos != contacts.end()) 
    {
        (*pos).state = CONTACT_ENDED;
    }    
}

void DestructionListener::SayGoodbye(b2Joint* joint)
{
    LuaState* scriptState = [LuaState sharedInstance];
    lua_State* L = scriptState.L;
    
    if (joint->GetUserData())
    {
        joint_wrapper_type* j = (joint_wrapper_type*)joint->GetUserData();
        if (j->joint)
        {
            luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefA);
            j->bodyRefA = LUA_NOREF;
            luaL_unref(L, LUA_REGISTRYINDEX, j->bodyRefB);                        
            j->bodyRefB = LUA_NOREF;
            j->joint = NULL;
        }
        
    }
    
}

