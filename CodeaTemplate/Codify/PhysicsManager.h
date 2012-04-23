//
//  PhysicsManager.h
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

#import <Foundation/Foundation.h>

#include <Box2d.h>
#include <vector>
#include <algorithm>

#define INV_PTM_RATIO 1.0f/PTM_RATIO
#define DEFAULT_WORLD_GRAVITY_X 0
#define DEFAULT_WORLD_GRAVITY_Y -9.8f

struct lua_State;

typedef enum BodyType
{
    BODY_STATIC = 0,
    BODY_KINEMATIC,
    BODY_DYNAMIC
} BodyType;

const int kMaxContactPoints = 2048;

typedef enum ContactState
{
    CONTACT_BEGAN=0,
    CONTACT_PERSIST,
    CONTACT_ENDED
} ContactState;

struct ContactPoint
{
    int ref;
    int ID;
    bool touching;
	b2Fixture* fixtureA;
	b2Fixture* fixtureB;
    int childIndexA;
    int childIndexB;
	b2Vec2 normal;
	b2Vec2 position;
    float normalImpulse;
    float tangentImpulse;
    b2Vec2 points[b2_maxManifoldPoints];
    float normalImpulses[b2_maxManifoldPoints];
    float tangentImpulses[b2_maxManifoldPoints];
    int pointCount;
	ContactState state;

    bool operator==(const ContactPoint& other) const
    {
        return (fixtureA == other.fixtureA) && (fixtureB == other.fixtureB) &&
               (childIndexA == other.childIndexA) && (childIndexB == other.childIndexB);
    }    
};

class ContactListener : public b2ContactListener
{
public:

	virtual void BeginContact(b2Contact* contact);
	virtual void EndContact(b2Contact* contact);
	virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
	virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
    std::vector<ContactPoint> contacts;
    int currentID;
};

class DestructionListener : public b2DestructionListener
{
    virtual void SayGoodbye(b2Joint* joint);
    virtual void SayGoodbye(b2Fixture* fixture) {}

};

@interface PhysicsManager : NSObject 
{
    b2World* world;    
    ContactListener* contactListener;
    DestructionListener* destructionListener;
    int velocityIterations;
    int positionIterations;
    BOOL paused;
    
    float timeStep;
    float invTimeStep;
    float accum;
    float alpha;
}

@property(nonatomic, readonly) b2World* world;
@property(nonatomic, readonly) float alpha;
@property(nonatomic, readonly) float timeStep;
@property(nonatomic, readonly) float invTimeStep;
@property(nonatomic, assign) float pixelToMeterRatio;

-(void) step:(float)dt;
-(BOOL) processContacts:(lua_State*)L;
-(void) reset;
-(void) setVelocityIterations:(int)velIter positionIterations:(int)posIter;
-(void) setPaused:(BOOL)p;

-(b2Body*) createCircle:(float)x y:(float)y radius:(float)radius;
-(b2Body*) createPolygon:(CGPoint)position x:(float*)x y:(float*)y numPoints:(int)numPoints;
-(b2Body*) createChain:(CGPoint)position x:(float*)x y:(float*)y numPoints:(int)numPoints loop:(BOOL)loop;
-(b2Body*) createEdge:(CGPoint)position pointA:(CGPoint)pointA pointB:(CGPoint)pointB;
-(void) destroyBody:(b2Body*)body;

-(b2Joint*) createJoint:(b2JointType)type bodyA:(b2Body*)bodyA bodyB:(b2Body*)bodyB anchorA:(b2Vec2)anchorA anchorB:(b2Vec2)anchorB maxLength:(float)maxLength;

-(void) destroyJoint:(b2Joint*)joint;

@end


