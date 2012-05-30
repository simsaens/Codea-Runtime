//
//  BasicRendererViewController.m
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

#import "BasicRendererViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CodifyAppDelegate.h"
#import "LuaState.h"
#import "EAGLView.h"
#import "KeyboardInputView.h"
#import "RenderManager.h"
#import "RenderCommands.h"
#import "PhysicsManager.h"
#import "DisplayCommands.h"
#import "PhysicsCommands.h"
#import "CodifyScriptExecute.h"
#import "Project.h"
#import "ShaderManager.h"
#import "TextureCache.h"
#import "SpriteManager.h"
#import "CaptureVideoPanel.h"

#import "SoundCommands.h" //In order to update sound buffers
#import "body.h"
#import "Persistence.h"

#define kFilteringFactor    0.1 //For low and high pass filters on non gyro devices

#pragma mark - Private Interface

@interface BasicRendererViewController ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) CADisplayLink *displayLink;

- (void)initialDrawSetup;
- (void)updateScriptOrientation;

@end

#pragma mark - Basic Renderer

@implementation BasicRendererViewController

@synthesize keyboardInputView;
@synthesize glView;
@synthesize recordingTimeLabel;
@synthesize animating, context, displayLink;
@synthesize supportedOrientations;
@synthesize screenCapture;
@synthesize project;
@synthesize fullscreen;
@synthesize showButtons;

#pragma mark - Orientation helper

- (int) orientationFromUIOrientation:(UIInterfaceOrientation)uio
{
    switch (uio) 
    {
        case UIInterfaceOrientationPortrait:
            return ORIENTATION_PORTRAIT;            
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return ORIENTATION_PORTRAIT_UPSIDE_DOWN;            
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            return ORIENTATION_LANDSCAPE_LEFT;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            return ORIENTATION_LANDSCAPE_RIGHT;            
            break;
            
        default:
            return ORIENTATION_ANY;
            break;
    }
}

#pragma mark - Internal Initialization

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self){
		supportedOrientations = [[NSMutableSet alloc] initWithCapacity:4];
		[self addSupportedOrientation:ORIENTATION_ANY];
	}
	
	return self;
}

- (void) setup
{
    self.showButtons = NO;
    self.fullscreen = YES;
    
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext) 
    {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    renderManager = [[RenderManager alloc] init];
    physicsManager = [[PhysicsManager alloc] init];
    
    if (!aContext)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
        NSLog(@"Failed to set ES context current");
    
	self.context = aContext;
	[aContext release];
	
    self.glView.multipleTouchEnabled = YES;
    
    [self.glView setTouchResponder:self];
    [self.glView setContext:context];
    [self.glView setFramebuffer];
    
    if ([context API] == kEAGLRenderingAPIOpenGLES2)
    {
        [[ShaderManager sharedManager] createShader:@"Circle" withFile:@"CircleShader.plist"];
        [[ShaderManager sharedManager] createShader:@"CircleNoStroke" withFile:@"CircleShaderNoStroke.plist"];        
        [[ShaderManager sharedManager] createShader:@"Sprite" withFile:@"SpriteShader.plist"];    
        [[ShaderManager sharedManager] createShader:@"SpriteNoTint" withFile:@"SpriteShaderNoTint.plist"];    
        [[ShaderManager sharedManager] createShader:@"SpriteTintAlpha" withFile:@"SpriteShaderTintAlpha.plist"];    
        [[ShaderManager sharedManager] createShader:@"SpriteTintRGB" withFile:@"SpriteShaderTintRGB.plist"];            
        [[ShaderManager sharedManager] createShader:@"Text" withFile:@"TextShader.plist"];            
        [[ShaderManager sharedManager] createShader:@"Rect" withFile:@"RectShader.plist"];        
        [[ShaderManager sharedManager] createShader:@"RectNoStroke" withFile:@"RectShaderNoStroke.plist"];     
        [[ShaderManager sharedManager] createShader:@"RectNoSmooth" withFile:@"RectShaderNoSmooth.plist"];        
        [[ShaderManager sharedManager] createShader:@"RectNoStrokeNoSmooth" withFile:@"RectShaderNoStrokeNoSmooth.plist"];             
        [[ShaderManager sharedManager] createShader:@"Line" withFile:@"LineShader.plist"];        
        [[ShaderManager sharedManager] createShader:@"LineRoundCap" withFile:@"LineRoundCapShader.plist"];        
        [[ShaderManager sharedManager] createShader:@"SimpleLine" withFile:@"SimpleLineShader.plist"];  
        
        [[ShaderManager sharedManager] createShader:@"Mesh2D" withFile:@"Mesh2DShader.plist"];                
        [[ShaderManager sharedManager] createShader:@"Mesh2DTextured" withFile:@"Mesh2DTexturedShader.plist"];                        
        [[ShaderManager sharedManager] createShader:@"MeshFillColor" withFile:@"MeshFillColorShader.plist"];                        
        [[ShaderManager sharedManager] createShader:@"MeshFillColorTexture" withFile:@"MeshFillColorTextureShader.plist"];                                
        
        [[ShaderManager sharedManager] createShader:@"PassThrough" withFile:@"PassThroughShader.plist"];  
    }
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;    
    
    [LuaState sharedInstance].delegate = self;
    
    screenCapture = [[ScreenCapture alloc] initWithGLView:glView];
    screenCapture.delegate = self;
}

- (void) setupRenderGlobals
{    
    //Create a global touch
    currentTouch = (touch_type*)[[LuaState sharedInstance] createGlobalUserData:sizeof(touch_type) withTypeName:@"touch" andName:@"CurrentTouch"];
    //setupEmptyTouch(currentTouch);
    
    currentGravity = (lua_Number*)[[LuaState sharedInstance] createGlobalUserData:3*sizeof(lua_Number) withTypeName:@"vec3" andName:@"Gravity"];
    if( currentGravity )
    {
        currentGravity[0] = 0; currentGravity[1] = 0; currentGravity[2] = 0;
    }
    
    currentUserAccel = (lua_Number*)[[LuaState sharedInstance] createGlobalUserData:3*sizeof(lua_Number) withTypeName:@"vec3" andName:@"UserAcceleration"];
    if( currentUserAccel )
    {
        currentUserAccel[0] = 0; currentUserAccel[1] = 0; currentUserAccel[2] = 0;
    }        
    
    [[LuaState sharedInstance] setGlobalInteger:[self orientationFromUIOrientation:self.interfaceOrientation] withName:@"CurrentOrientation"];        
    
    //Init frame delta
    elapsedTime = 0;    
    [[LuaState sharedInstance] setGlobalNumber:elapsedTime withName:@"ElapsedTime"];
    [[LuaState sharedInstance] setGlobalNumber:0.0 withName:@"DeltaTime"];                   
    [[LuaState sharedInstance] setGlobalNumber:[UIScreen mainScreen].scale withName:@"ContentScaleFactor"];                       
    
    //Push touch state vars
    [[LuaState sharedInstance] setGlobalInteger:TOUCH_STATE_BEGAN withName:@"BEGAN"];
    [[LuaState sharedInstance] setGlobalInteger:TOUCH_STATE_MOVING withName:@"MOVING"];       
    [[LuaState sharedInstance] setGlobalInteger:TOUCH_STATE_STATIONARY withName:@"STATIONARY"];  
    [[LuaState sharedInstance] setGlobalInteger:TOUCH_STATE_INACTIVE withName:@"CANCELLED"];  
    [[LuaState sharedInstance] setGlobalInteger:TOUCH_STATE_ENDED withName:@"ENDED"];           
    
    //Push additional variables about the display
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.width withName:@"WIDTH"];
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.height withName:@"HEIGHT"];    
    
    //Push variables relating to drawing modes
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::SHAPE_MODE_CORNER withName:@"CORNER"];
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::SHAPE_MODE_CORNERS withName:@"CORNERS"];    
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::SHAPE_MODE_CENTER withName:@"CENTER"];    
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::SHAPE_MODE_RADIUS withName:@"RADIUS"];  
    
    //Push variables relating to text alignment
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::TEXT_ALIGN_LEFT withName:@"LEFT"];       
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::TEXT_ALIGN_RIGHT withName:@"RIGHT"];      
    
    //Push variables for line cap modes
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::LINE_CAP_ROUND withName:@"ROUND"];    
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::LINE_CAP_SQUARE withName:@"SQUARE"];    
    [[LuaState sharedInstance] setGlobalInteger:GraphicsStyle::LINE_CAP_PROJECT withName:@"PROJECT"];      
}

- (void)setupPhysicsGlobals
{
    // Body types
    [[LuaState sharedInstance] setGlobalInteger:BODY_STATIC withName:@"STATIC"];    
    [[LuaState sharedInstance] setGlobalInteger:BODY_KINEMATIC withName:@"KINEMATIC"];
    [[LuaState sharedInstance] setGlobalInteger:BODY_DYNAMIC withName:@"DYNAMIC"]; 
    
    // Shape types
    [[LuaState sharedInstance] setGlobalInteger:RIGIDBODY_CIRCLE withName:@"CIRCLE"];    
    [[LuaState sharedInstance] setGlobalInteger:RIGIDBODY_EDGE withName:@"EDGE"];            
    [[LuaState sharedInstance] setGlobalInteger:RIGIDBODY_POLYGON withName:@"POLYGON"];        
    [[LuaState sharedInstance] setGlobalInteger:RIGIDBODY_CHAIN withName:@"CHAIN"];        
    [[LuaState sharedInstance] setGlobalInteger:RIGIDBODY_COMPOUND withName:@"COMPOUND"];
    
    // Joint types
    [[LuaState sharedInstance] setGlobalInteger:e_revoluteJoint withName:@"REVOLUTE"];            
    [[LuaState sharedInstance] setGlobalInteger:e_prismaticJoint withName:@"PRISMATIC"];                
    [[LuaState sharedInstance] setGlobalInteger:e_distanceJoint withName:@"DISTANCE"];                    
    [[LuaState sharedInstance] setGlobalInteger:e_weldJoint withName:@"WELD"];                        
    [[LuaState sharedInstance] setGlobalInteger:e_ropeJoint withName:@"ROPE"];                            
    //[[LuaState sharedInstance] setGlobalInteger:e_mouseJoint withName:@"MOUSE"];                                
}

#pragma mark - Lua State Delegate 

- (void) luaState:(LuaState *)state errorOccured:(NSString *)error
{   
    [self stopAnimation];
}

- (void)luaState:(LuaState*)state printedText:(NSString *)text
{
    //Lua script has printed some text. Show it to the user
    DBLog(@"%@",text);
}

- (void) luaState:(LuaState *)state registerWatch:(NSString*)expression
{
    //Register a watch expression
}

- (void) luaState:(LuaState*)state registerFloatParameter:(NSString*)text initialValue:(CGFloat)value withMin:(CGFloat)min andMax:(CGFloat)max editable:(BOOL)editable
{
    //Register a float slider parameter with the specified settings
    
    //We just set the default value here    
    [state setGlobalNumber:value withName:text];
}

- (void) luaState:(LuaState*)state registerIntegerParameter:(NSString*)text initialValue:(NSInteger)value withMin:(NSInteger)min andMax:(NSInteger)max editable:(BOOL)editable
{
    //Register an integer slider parameter with the specified settings
    
    //We just set the default value here
    [state setGlobalInteger:value withName:text];
}

- (void) removeAllParametersForLuaState:(LuaState*)state
{
    //Remove all parameters 
}

- (void) clearOutputForLuaState:(LuaState*)state
{
    //You can clear your output buffer here
}

#pragma mark - Memory 

- (void)dealloc
{    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [[ShaderManager sharedManager] removeAllShaders];    
    
    SAFE_RELEASE(motionManager);
    
    [project release];
    [renderManager release];
    [physicsManager release];
    [context release];
    [supportedOrientations release];
    [keyboardInputView release];
    [glView release];   
    [screenCapture release];
    [recordingTimeLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    [[TextureCache sharedInstance] flushUnusedTextures];
}

#pragma mark - Setting the project

- (void) setProject:(Project *)newProject
{
    if( project != newProject && project.isLoaded )
    {
        [project unload];
        [project release];
        project = nil;
    }    
    else 
    {
        [project release];
        project = nil;
    }
    
    if( newProject )
    {
        project = [newProject retain];
        
        if( !project.isLoaded )
        {
            [project load];        
        }
    }
}

#pragma mark - Screen capture delegate

- (void) boundCaptureFrameBuffer:(ScreenCapture *)capture
{
    //Invert fix matrix    
    [renderManager setFixMatrix:glm::ortho(-1.f, 1.f, 1.f, -1.f, -1.f, 1.f)];    
}

- (BOOL) bindCaptureTextureTarget:(GLenum)target name:(GLuint)name
{
    [renderManager useTexture:name];
    
    return YES;
}

- (void) recordingFinished:(NSString*)outputPathOrNil
{
    
}

#pragma mark - Accelerometer values

- (void)setupAccelerometerValues
{    
    if( motionManager.deviceMotionAvailable )
    {
        gravX = motionManager.deviceMotion.gravity.x;
        gravY = motionManager.deviceMotion.gravity.y;
        gravZ = motionManager.deviceMotion.gravity.z;    
        
        userX = motionManager.deviceMotion.userAcceleration.x;
        userY = motionManager.deviceMotion.userAcceleration.y;
        userZ = motionManager.deviceMotion.userAcceleration.z;        
    }
    else if( motionManager.accelerometerAvailable )
    {
        gravX = (motionManager.accelerometerData.acceleration.x * kFilteringFactor) + (gravX * (1.0 - kFilteringFactor));
        gravY = (motionManager.accelerometerData.acceleration.y * kFilteringFactor) + (gravY * (1.0 - kFilteringFactor));        
        gravZ = (motionManager.accelerometerData.acceleration.z * kFilteringFactor) + (gravZ * (1.0 - kFilteringFactor));                
        
        userX = motionManager.accelerometerData.acceleration.x - ( (motionManager.accelerometerData.acceleration.x * kFilteringFactor) + (userX * (1.0 - kFilteringFactor)) );
        userY = motionManager.accelerometerData.acceleration.y - ( (motionManager.accelerometerData.acceleration.y * kFilteringFactor) + (userY * (1.0 - kFilteringFactor)) );
        userZ = motionManager.accelerometerData.acceleration.z - ( (motionManager.accelerometerData.acceleration.z * kFilteringFactor) + (userZ * (1.0 - kFilteringFactor)) );        
    }
    
    
    //Set up current gravity
    switch ( self.interfaceOrientation ) 
    {
        case UIInterfaceOrientationLandscapeLeft:
            currentGravity[0] =  gravY;
            currentGravity[1] = -gravX;
            currentGravity[2] =  gravZ;                           
            break;
        case UIInterfaceOrientationLandscapeRight:
            currentGravity[0] = -gravY;
            currentGravity[1] =  gravX;
            currentGravity[2] =  gravZ;               
            break;
        case UIInterfaceOrientationPortrait:
            currentGravity[0] = gravX;
            currentGravity[1] = gravY;
            currentGravity[2] = gravZ;               
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            currentGravity[0] =  gravX;
            currentGravity[1] = -gravY;
            currentGravity[2] =  gravZ;               
            break;
        default:
            break;
    }
    
    currentUserAccel[0] = userX;
    currentUserAccel[1] = userY;
    currentUserAccel[2] = userZ;        
}

#pragma mark - Frame timing

-(void) updateElapsedTimeAndDelta
{
    NSTimeInterval curTick = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval delta = curTick - prevTick;
    
    elapsedTime += delta;
    
    [[LuaState sharedInstance] setGlobalNumber:elapsedTime withName:@"ElapsedTime"];
    [[LuaState sharedInstance] setGlobalNumber:delta withName:@"DeltaTime"];    
    
    [physicsManager step:delta];
    
    prevTick = curTick;
}

#pragma mark - Orientation updates

- (void) updateScriptOrientation
{
    int orientation = [self orientationFromUIOrientation:self.interfaceOrientation];
    
    [[LuaState sharedInstance] setGlobalInteger:orientation withName:@"CurrentOrientation"];    
    [[LuaState sharedInstance] callOrientationFunction:orientation];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if( (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) || (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) )
    {    
        self.glView.alpha = 0;     
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if( (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) || (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)) )
    {
        [UIView animateWithDuration:0.25 animations:^{
            self.glView.alpha = 1; 
        }];
    }    
    
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.width withName:@"WIDTH"];
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.height withName:@"HEIGHT"];     
    
    [self updateScriptOrientation];
}

#pragma mark - View preparation

- (void) prepareViewForDisplay
{
    //Do some basic GL setup    
    [self startAnimation];           
    [self initialDrawSetup];          
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{                                        
    [[NSNotificationCenter defaultCenter] postNotificationName:RendererViewControllerWillAppearNotification object:self];        
    
    [super viewWillAppear:animated];    
    
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.width withName:@"WIDTH"];
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.height withName:@"HEIGHT"];     
}

- (void)viewDidAppear:(BOOL)animated
{                          
    [super viewDidAppear:animated];    
    
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.width withName:@"WIDTH"];
    [[LuaState sharedInstance] setGlobalInteger:self.glView.bounds.size.height withName:@"HEIGHT"]; 
    
    [self updateScriptOrientation];    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [self finalizeOpenGL];
    
    setLocalDataPrefix(nil); //clear out any cached stuff
    setProjectDataPath(nil); //clear out any cached stuff
    setProjectInfoStore(nil); //clear out any cached stuff
    
    keyboardInputView.active = NO;
    
    [[TextureCache sharedInstance] flushTextures];
    
    [self stopRecordingAndDiscard];
    
    [super viewWillDisappear:animated];
}

- (void)loadView
{
    [super loadView];
    
    //Create gl view
    glView = [[EAGLView alloc] initWithFrame:self.view.bounds];
    glView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    //Create recording label
    recordingTimeLabel = [[UILabel alloc] init];

    [self.view addSubview:glView];
    [glView addSubview:recordingTimeLabel];
    
    [self setup]; 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];       
    
    recordingTimeLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    recordingTimeLabel.text = @"00:00:00";    
    recordingTimeLabel.font = [UIFont systemFontOfSize:17];    
    recordingTimeLabel.textColor = [UIColor whiteColor];    
    recordingTimeLabel.layer.cornerRadius = 4;
    recordingTimeLabel.hidden = YES;
    recordingTimeLabel.frame = CGRectMake(20, 20, 74, 18);
    recordingTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    keyboardInputView.delegate = self;
}

- (void)viewDidUnload
{    
    [self setGlView:nil];
    [self setKeyboardInputView:nil];
    
    [[ShaderManager sharedManager] removeAllShaders];
    
    [self setRecordingTimeLabel:nil];
	[super viewDidUnload];    
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
    
    //Unregister keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];        
}

#pragma mark - Recording the screen

- (void)startRecording
{
    if( !screenCapture.recording )
    {
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            //When recording video set the scaleFactor to 1 (on iPad)
            //Retina iPad is too large to save the resulting video to the user's Photo album
            glView.scaleFactor = 1;
        }
        
        [screenCapture startRecording];
    }
    
    recordingTimeLabel.text = @"00:00:00";    
    recordingTimeLabel.hidden = NO;
}

- (void)stopRecording
{
    if( screenCapture.recording )
    {
        [screenCapture stopRecording];
        
        glView.scaleFactor = [[UIScreen mainScreen] scale];        
    }    
    
    //Present capture video panel
    CaptureVideoPanel *capturePanel = [[CaptureVideoPanel alloc] initWithNibName:@"CaptureVideoPanel" bundle:nil];
    
    [self stopAnimation];
    
    [capturePanel presentInParentVC:self];
    
    capturePanel.recordingPanelTitle.text = [NSString stringWithFormat:@"Recording Length %@", recordingTimeLabel.text];
    
    //Reset recording time label
    recordingTimeLabel.text = @"00:00:00";
    recordingTimeLabel.hidden = YES;            
    
    capturePanel.completionHandler = ^(CapturedVideoCompletionType type)
    {
        switch (type) 
        {
            case CapturedVideoCompletionDiscard:
                [screenCapture discardMovie];
                [self startAnimation];
                break;
                
            case CapturedVideoCompletionSave:
                [screenCapture saveMovieToCameraRoll];
                [self startAnimation];
                break;
            default:
                break;
        }  
        
        [capturePanel release];
    };                
}

- (void)stopRecordingAndDiscard
{
    if( screenCapture.recording )
    {
        [screenCapture stopRecordingAndDiscard];
    }    
    
    recordingTimeLabel.text = @"00:00:00";
    recordingTimeLabel.hidden = YES;          
}

#pragma mark - Fullscreen mode

- (void) setFullscreen:(BOOL)newFullscreen
{
    [self setFullscreen:newFullscreen animated:NO];
}

- (void) setFullscreen:(BOOL)newFullscreen animated:(BOOL)animated
{
    //If you want to implement display modes, you can handle the changes here
    fullscreen = newFullscreen;
    
    //Resize your display
}

#pragma mark - Keyboard Show / Hide

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    //You can handle keyboard display events here
    // below code gets the new keyboard height, so you can shift your views appropriately
    
    /*
    NSDictionary* info = [aNotification userInfo];
    
    //Get keyboard frame and convert to rotated coordinates
    CGRect keyboardFrameBegin = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    keyboardFrameBegin = [self.view convertRect:keyboardFrameBegin fromView:nil];        
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];    
    
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    float keyboardHeight = keyboardFrameBegin.origin.y - keyboardFrame.origin.y;            
     */
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    //You can handle keyboard hide events here
    // below code gets the hide duration, so you can animate your views back  
    
    /*
    NSDictionary* info = [aNotification userInfo];    
    
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];              
     */
}

#pragma mark - Animation

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1) 
    {
        animationFrameInterval = frameInterval;
        
        if (animating) 
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating) 
    {
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
    
    prevTick = [NSDate timeIntervalSinceReferenceDate];
    
    if( motionManager == nil )
    {
        motionManager = [[CMMotionManager alloc] init];
        motionManager.accelerometerUpdateInterval = 1/30.0f;
    }
    
    if( motionManager.deviceMotionAvailable )
    {
        [motionManager startDeviceMotionUpdates];    
    }
    else if( motionManager.accelerometerAvailable )
    {
        [motionManager startAccelerometerUpdates];
    }    
}

- (void)stopAnimation
{
    if (animating) 
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
    
    if( motionManager )
    {
        if( motionManager.deviceMotionAvailable )
        {
            [motionManager stopDeviceMotionUpdates];    
        }
        else if( motionManager.accelerometerAvailable )
        {
            [motionManager stopAccelerometerUpdates];
        }
    }    
}

#pragma mark - Keyboard input

- (void) keyboardInputView:(KeyboardInputView *)view WillInsertText:(NSString *)text
{
    LuaState *scripting = [LuaState sharedInstance];   
    [scripting callKeyboardFunction:text];
}

#pragma mark - Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    currentTouch->ID = 0;
    
    currentTouch->state = TOUCH_STATE_BEGAN;
    
    if( touch.phase == UITouchPhaseStationary )
    {
        currentTouch->state = TOUCH_STATE_STATIONARY;        
    }
    
    currentTouch->tapCount = [touch tapCount];
    
    CGPoint curLoc = [touch locationInView:glView];
    currentTouch->x = curLoc.x;
    currentTouch->y = self.glView.bounds.size.height - curLoc.y;
    
    CGPoint prevLoc = [touch previousLocationInView:glView];    
    currentTouch->prevX = prevLoc.x;
    currentTouch->prevY = self.glView.bounds.size.height - prevLoc.y;    
    
    currentTouch->deltaX = currentTouch->x - currentTouch->prevX;
    currentTouch->deltaY = currentTouch->y - currentTouch->prevY;
    
    
    LuaState *scripting = [LuaState sharedInstance];    
    [scripting callTouchFunction:touches inView:self.glView];
    
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];   
    
    currentTouch->ID = 0;
    currentTouch->state = TOUCH_STATE_INACTIVE;
    currentTouch->tapCount = [touch tapCount];
    
    CGPoint curLoc = [touch locationInView:glView];
    currentTouch->x = curLoc.x;
    currentTouch->y = self.glView.bounds.size.height - curLoc.y;
    
    CGPoint prevLoc = [touch previousLocationInView:glView];    
    currentTouch->prevX = prevLoc.x;
    currentTouch->prevY = self.glView.bounds.size.height - prevLoc.y;
    
    currentTouch->deltaX = currentTouch->x - currentTouch->prevX;
    currentTouch->deltaY = currentTouch->y - currentTouch->prevY;        
    
    LuaState *scripting = [LuaState sharedInstance];    
    [scripting callTouchFunction:touches inView:self.glView];    
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];    
    
    currentTouch->ID = 0;
    currentTouch->state = TOUCH_STATE_MOVING;
    
    if( touch.phase == UITouchPhaseStationary )
    {
        currentTouch->state = TOUCH_STATE_STATIONARY;        
    }    
    
    currentTouch->tapCount = [touch tapCount];
    
    CGPoint curLoc = [touch locationInView:glView];
    currentTouch->x = curLoc.x;
    currentTouch->y = self.glView.bounds.size.height - curLoc.y;
    
    CGPoint prevLoc = [touch previousLocationInView:glView];    
    currentTouch->prevX = prevLoc.x;
    currentTouch->prevY = self.glView.bounds.size.height - prevLoc.y;    
    
    currentTouch->deltaX = currentTouch->x - currentTouch->prevX;
    currentTouch->deltaY = currentTouch->y - currentTouch->prevY;    
    
    LuaState *scripting = [LuaState sharedInstance];    
    [scripting callTouchFunction:touches inView:self.glView];    
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];   
    
    currentTouch->ID = 0;
    currentTouch->state = TOUCH_STATE_ENDED;
    currentTouch->tapCount = [touch tapCount];
    
    CGPoint curLoc = [touch locationInView:glView];
    currentTouch->x = curLoc.x;
    currentTouch->y = self.glView.bounds.size.height - curLoc.y;
    
    CGPoint prevLoc = [touch previousLocationInView:glView];    
    currentTouch->prevX = prevLoc.x;
    currentTouch->prevY = self.glView.bounds.size.height - prevLoc.y;
    
    currentTouch->deltaX = currentTouch->x - currentTouch->prevX;
    currentTouch->deltaY = currentTouch->y - currentTouch->prevY;        
    
    LuaState *scripting = [LuaState sharedInstance];    
    [scripting callTouchFunction:touches inView:self.glView];    
}

#pragma mark - Drawing

- (void) finalizeOpenGL
{
    [renderManager deleteOffscreenFramebuffer];
    [self.glView deleteFramebuffer];
}

- (void)initialDrawSetup
{    
    rc_initialize(renderManager);    
    
    [[ShaderManager sharedManager] reset];
    [renderManager reset];    
    
    [physicsManager reset];
    pc_initialize(physicsManager);    
    
    setLocalDataPrefix(self.project.name);
    setProjectDataPath(self.project.bundlePath);
    setProjectInfoStore(self.project.info);    
    setupGlobalData();        
    
    self.glView.retainedBacking = NO;    
    [self.glView setFramebuffer];    
    
    //Clear back buffer
    glClearColor(0, 0, 0, 1.0f);     
    glClearDepthf(0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);             
    
    if( glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
        NSLog(@"Framebuffer incomplete, status = %d, Line:%d", glCheckFramebufferStatus(GL_FRAMEBUFFER), __LINE__);                           
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_GEQUAL);    
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);                   
    
    //Load all buffers and call setup
    [[CodifyScriptExecute sharedInstance] runProject:self.project];             
    
    [self.glView presentFramebuffer];        
}

- (void)drawWatermark
{
    // Render watermark
    {            
        float x,y,w,h;
        w = screenCapture.watermarkTexture.pixelsWide * 0.75f;
        h = screenCapture.watermarkTexture.pixelsHigh * 0.75f;
        x = screenCapture.renderBufferWidth - w - 20;
        y = 20;
        
        GLfloat spriteVerts[] = 
        {
            x,   y,
            x+w, y,
            x,   y+h,
            x+w, y+h
        };        
        
        GLfloat spriteUV[] = 
        {
            0,  1,
            1,  1,
            0,  0,
            1,  0,
        };    
        
        GLfloat tint[] = 
        {
            1.0f, 1.0f, 1.0f, 0.3f
        };
        
        //Load uniforms into shader    
        Shader *shader = [renderManager useShader:@"Sprite"];        
        
        glUniform4fv([shader uniformLocation:@"TintColor"], 1, tint);    
        [renderManager setAttributeNamed:@"Vertex" withPointer:spriteVerts size:2 andType:GL_FLOAT];
        [renderManager setAttributeNamed:@"TexCoord" withPointer:spriteUV size:2 andType:GL_FLOAT];        
        
        //Tell the shader the Tex Unit 0 is for ColorTexture
        glUniform1i([shader uniformLocation:@"ColorTexture"], 0);
        
        //Bind sprite texture to tex unit 0
        [renderManager setActiveTexture:GL_TEXTURE0];
        [renderManager useTexture:screenCapture.watermarkTexture.name];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
    }    
}

- (void)drawFrame
{                
    [self setupAccelerometerValues];
    [self updateElapsedTimeAndDelta];
    
    [self.glView setFramebuffer];  
    glClear(GL_DEPTH_BUFFER_BIT);
    
    updateAudio();
    
    if( [context API] == kEAGLRenderingAPIOpenGLES2 )
    {
        [renderManager setupNextFrameState];                 
        [renderManager orthoLeft:0 right:self.glView.bounds.size.width bottom:0 top:self.glView.bounds.size.height zNear:-10 zFar:10];
    }        
    
    if (screenCapture.recording)
    {
        renderManager.capture = screenCapture;        
        [screenCapture setupRenderTexture];
        
        //[renderManager orthoLeft:0 right:self.glView.bounds.size.width bottom:0 top:self.glView.bounds.size.height zNear:-10 zFar:10];        
        
        // NOTE: This is why setContext was not working with capture!
        // **setContext relies on having the same projection as the scene**
        //
        // flip orthographic projection on the y-axis          
        [renderManager setFixMatrix:glm::ortho(-1.f, 1.f, 1.f, -1.f, -1.f, 1.f)];        
        [renderManager noScissorTest];
    }
    
    //Get the lua state and call draw or setup
    LuaState *scripting = [LuaState sharedInstance];        
    if( renderManager.frameCount == 1 )
    {
        [scripting callSimpleFunction:@"setup"];                        
    }
    else
    {
        [scripting callSimpleFunction:@"draw"];        
    }
    
    [renderManager setFramebuffer:NULL];    
    
    if (screenCapture.recording)
    {
        // Update recording label
        float seconds = [[NSDate date] timeIntervalSinceDate:screenCapture.startedAt];
        int hours = seconds / 60 / 60;
        int minutes = seconds / 60;
        int leftOverSeconds = seconds - (hours*60*60) - (minutes*60);
        
        recordingTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours,minutes,leftOverSeconds];
        
        // Reset render manager state
        [renderManager clearModelMatrixStack];
        [renderManager noScissorTest];
        
        [self drawWatermark];
        
        // Reset back to screen framebuffer and non-inverted projection matrix
        [glView setFramebuffer];
        [renderManager orthoLeft:0 right:self.glView.bounds.size.width bottom:0 top:self.glView.bounds.size.height zNear:-10 zFar:10];
        
        // Render offscreen texture back to the screen
        {            
            GLfloat spriteVerts[] = 
            {
                -1,   -1,
                1,   -1,
                -1,    1,
                1,    1,
            };        
            
            GLfloat spriteUV[] = 
            {
                0,  1,
                1,  1,
                0,  0,
                1,  0,
            };    
            
            //Load uniforms into shader    
            Shader* shader = [[ShaderManager sharedManager] useShader:@"PassThrough"];
            [renderManager setAttributeNamed:@"Vertex" withPointer:spriteVerts size:2 andType:GL_FLOAT];
            [renderManager setAttributeNamed:@"TexCoord" withPointer:spriteUV size:2 andType:GL_FLOAT];        
            
            //Tell the shader the Tex Unit 0 is for ColorTexture
            glUniform1i([shader uniformLocation:@"ColorTexture"], 0);
            
            //Bind sprite texture to tex unit 0
            [renderManager setActiveTexture:GL_TEXTURE0];
            [renderManager useTexture:CVOpenGLESTextureGetName(screenCapture.renderTexture)];
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
        }        
        
        glFlush();
        [screenCapture recordFrame];
    }            
    
    const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER,1,discards);    
    
    [self.glView presentFramebuffer];
}

#pragma mark - Orientation support

- (void) clearSupportedOrientations
{
    [supportedOrientations removeAllObjects];
}

- (void) addSupportedOrientation:(NSUInteger)codeaOrientation
{
    switch( codeaOrientation )
    {
        case ORIENTATION_PORTRAIT:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortrait]];            
            break;
        case ORIENTATION_PORTRAIT_UPSIDE_DOWN:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortraitUpsideDown]];                        
            break;            
        case ORIENTATION_LANDSCAPE_LEFT:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeLeft]];                        
            break;            
        case ORIENTATION_LANDSCAPE_RIGHT:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeRight]];                                    
            break;                        
        case ORIENTATION_PORTRAIT_ANY:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortrait]];            
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortraitUpsideDown]];                        
            break;            
        case ORIENTATION_LANDSCAPE_ANY:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeLeft]];                                    
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeRight]];                                                
            break;            
        case ORIENTATION_ANY:
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeLeft]];                                    
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeRight]];                                                
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortrait]];            
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationPortraitUpsideDown]];                                    
            break;
            
        default: //Default to landscape left and right
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeLeft]];                                    
            [supportedOrientations addObject:[NSNumber numberWithUnsignedInteger:UIInterfaceOrientationLandscapeRight]];                                                            
            break;
    }        
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if( screenCapture.recording )
    {
        return interfaceOrientation == self.interfaceOrientation;
    }
    else
    { 
        return [supportedOrientations containsObject:[NSNumber numberWithUnsignedInteger:interfaceOrientation]];
    }
}

@end
