//
//  BasicRendererViewController.h
//  Codea
//
//  Created by Simeon Nasilowski on 23/04/12.
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

#import <UIKit/UIKit.h>

#import <CoreMotion/CoreMotion.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "LuaState.h"

#import "touch.h"

#import "KeyboardInputView.h"
#import "ScreenCapture.h"

#define RendererViewControllerWillAppearNotification @"RendererViewControllerWillAppearNotification"

@class EAGLView;
@class RenderManager;
@class PhysicsManager;
@class Project;

@interface BasicRendererViewController : UIViewController<LuaStateDelegate,
                                                          ScreenCaptureDelegate,
                                                          KeyboardInputViewDelegate>
{
@protected
    EAGLContext *context;
    
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
    
    RenderManager *renderManager;
    PhysicsManager *physicsManager;
    
    CMMotionManager *motionManager;
    
    //UI stuff
    EAGLView *glView;
    KeyboardInputView *keyboardInputView;    
    
    touch_type *currentTouch;
    lua_Number *currentGravity;
    lua_Number *currentUserAccel;
    
    //Time tracking
    NSTimeInterval elapsedTime;
    NSTimeInterval prevTick;
    
    //Screen recording
    ScreenCapture* screenCapture;    
    
    //For filtering
    lua_Number gravX, gravY, gravZ;
    lua_Number userX, userY, userZ;  
    
    NSMutableSet *supportedOrientations; 
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

@property (nonatomic, retain) IBOutlet KeyboardInputView *keyboardInputView;
@property (nonatomic, readonly) ScreenCapture *screenCapture;

@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (nonatomic, retain) IBOutlet Project *project;
@property (retain, nonatomic) IBOutlet UILabel *recordingTimeLabel;

@property (nonatomic, readonly) NSSet *supportedOrientations;

@property (nonatomic, assign) BOOL fullscreen;
@property (nonatomic, assign) BOOL showButtons;

- (void) setup;
- (void) startAnimation;
- (void) stopAnimation;

- (void) setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

- (void)startRecording;
- (void)stopRecording;
- (void)stopRecordingAndDiscard;

- (void) finalizeOpenGL;

- (void) prepareViewForDisplay;

- (void) clearSupportedOrientations;
- (void) addSupportedOrientation:(NSUInteger)codeaOrientation;

- (void) setupDataStore;
- (void) setupRenderGlobals;
- (void) setupPhysicsGlobals;
- (void) setupAccelerometerValues;

@end
