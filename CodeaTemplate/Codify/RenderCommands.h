//
//  RenderCommands.h
//  Codea
//
//  Created by Simeon Nasilowski on 18/05/11.
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

@class RenderManager;
struct lua_State;

#ifdef __cplusplus
extern "C" {
#endif 

void rc_initialize(RenderManager *api);

//Copy processing API
int background(struct lua_State *L);

int tint(struct lua_State *L);
int noTint(struct lua_State *L);
int fill(struct lua_State *L);
int noFill(struct lua_State *L);

int stroke(struct lua_State *L);
int noStroke(struct lua_State *L);

int strokeWidth(struct lua_State *L);
int pointSize(struct lua_State *L);
    
#pragma mark - Fonts & Text    
    
int font(struct lua_State *L);
int fontSize(struct lua_State *L);   
int fontMetrics(struct lua_State *L);
int textWrapWidth(struct lua_State *L);       
int textAlign(struct lua_State *L); 
int textSize(struct lua_State *L); 
    
#pragma mark - Matrix Manipulation

int perspective(struct lua_State *L);    
int ortho(struct lua_State *L);    
int camera(struct lua_State *L);    
int applyMatrix(struct lua_State *L);
int modelMatrix(struct lua_State *L);    
int viewMatrix(struct lua_State *L);    
int projectionMatrix(struct lua_State *L);
    
#pragma mark - Drawing & Style
    
int rectMode(struct lua_State *L);
int ellipseMode(struct lua_State *L);
int spriteMode(struct lua_State *L);
int textMode(struct lua_State *L);    
int lineCapMode(struct lua_State *L);
    
int spriteSize(struct lua_State *L);
    
int smooth(struct lua_State *L);    
int noSmooth(struct lua_State *L);    
    
int drawImage(struct lua_State *L );
int sprite(struct lua_State *L);
int rect(struct lua_State *L);
int ellipse(struct lua_State *L);
int text(struct lua_State *L);
int point(struct lua_State *L);
int line(struct lua_State *L);
int drawMesh(struct lua_State *L);
    
int setContext(struct lua_State *L);     
    
int pushMatrix(struct lua_State *L);
int popMatrix(struct lua_State *L);
int resetMatrix(struct lua_State *L);
    
int pushStyle(struct lua_State *L);
int popStyle(struct lua_State *L);
int resetStyle(struct lua_State *L);    

int translate(struct lua_State *L);
int rotate(struct lua_State *L);
int scale(struct lua_State *L);
    
int zLevel(struct lua_State *L);
    
int scissorTest(struct lua_State *L);
int noScissorTest(struct lua_State *L);

int clip(struct lua_State *L);
int noClip(struct lua_State *L);
    
int triangulate(struct lua_State *L);
    
#ifdef __cplusplus
}
#endif 