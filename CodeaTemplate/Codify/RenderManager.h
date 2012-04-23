//
//  RenderManager.h
//  Codea
//
//  Created by Simeon Nasilowski on 28/05/11.
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

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <vector>
#include <string>
#include <map>
#include <set>

#define printOpenGLError() printOglError(__FILE__, __LINE__)

int printOglError(const char *file, int line);

@class Shader;
@class TextRenderer;
@class ScreenCapture;

struct image_type_t;

enum RenderManagerBlendingMode
{
    BLEND_MODE_NONE,
    BLEND_MODE_NORMAL,
    BLEND_MODE_PREMULT
};

struct GraphicsStyle
{
    enum ShapeMode
    {
        SHAPE_MODE_CORNER,
        SHAPE_MODE_CORNERS,  
        SHAPE_MODE_CENTER,
        SHAPE_MODE_RADIUS,
    };
    
    enum LineCapMode
    {
        LINE_CAP_ROUND,
        LINE_CAP_SQUARE,
        LINE_CAP_PROJECT, //square, but same size as ROUND
        LINE_CAP_NUM_MODES,
    };
    
    enum TextAlign
    {
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_CENTER = SHAPE_MODE_CENTER,        
    };
    
    GraphicsStyle() :
        strokeWidth(0.0f), strokeColor(1,1,1,1), fillColor(0.5,0.5,0.5,1), tintColor(1,1,1,1), pointSize(3.0f),
        spriteMode(SHAPE_MODE_CENTER), rectMode(SHAPE_MODE_CORNER), ellipseMode(SHAPE_MODE_CENTER), textMode(SHAPE_MODE_CENTER), lineCapMode(LINE_CAP_ROUND), smooth(YES), textAlign(TEXT_ALIGN_LEFT), fontSize(17.0f), textWrapWidth(0), fontName("Helvetica")
    {}
    
    float       strokeWidth;
    glm::vec4   strokeColor;    
    
    glm::vec4   fillColor;    
    float       pointSize;      
    
    glm::vec4   tintColor;
    
    ShapeMode   rectMode;
    ShapeMode   ellipseMode;  
    ShapeMode   spriteMode;
    ShapeMode   textMode;
    
    LineCapMode lineCapMode;
    
    std::string fontName;
    float       fontSize;
    float       textWrapWidth;
    TextAlign   textAlign;        
        
    BOOL        smooth;    
};

typedef std::map<GLuint, glm::mat4> XFormCache;
typedef std::map<GLuint, glm::vec4> ColorCache;
typedef std::map<GLuint, std::set<GLuint> > AttribLocCache;

@interface RenderManager : NSObject 
{
    std::vector<glm::mat4>      modelMatrixStack;
    std::vector<GraphicsStyle>  styleStack;
    
    //Eliminate redundant calls (caches)
    XFormCache lastShaderTransform;
    ColorCache lastShaderFill; 
    ColorCache lastShaderTint;     
    ColorCache lastShaderStroke;        
    AttribLocCache shaderActiveAttribs;
    
    
    glm::mat4 modelViewMatrix;    
    glm::mat4 viewMatrix;
    glm::mat4 projectionMatrix;
    
    //This matrix is used to invert for video recording
    glm::mat4 fixMatrix;
    
    GLuint currentTexture;   
    
    TextRenderer *textRenderer;
    
    RenderManagerBlendingMode currentBlendMode;
    GLenum activeTexture;
    
    struct image_type_t *currentRenderTarget;
    GLuint offscreenFramebuffer;
    
    NSUInteger frameCount;    
    ScreenCapture* capture;
}

@property (nonatomic, assign) NSUInteger frameCount;

#pragma mark - Text renderer
@property (nonatomic, readonly) TextRenderer *textRenderer;

#pragma mark - Render target
@property (nonatomic, readonly) struct image_type_t *currentRenderTarget;

#pragma mark - Raw model matrix pointers 
@property (nonatomic, readonly) const float *modelMatrix;
@property (nonatomic, readonly) const float *viewMatrix;
@property (nonatomic, readonly) const float *projectionMatrix;
@property (nonatomic, readonly) const float *modelViewMatrix;

#pragma mark - Fonts
@property (nonatomic, readonly) const char *fontName;
@property (nonatomic, readonly) CGFloat fontSize;
@property (nonatomic, readonly) CGFloat textWrapWidth;
@property (nonatomic, readonly) GraphicsStyle::TextAlign textAlign;

#pragma mark - Raw style pointers 
@property (nonatomic, readonly) const float *strokeWidth;
@property (nonatomic, readonly) const float *strokeColor;
@property (nonatomic, readonly) const float *fillColor;
@property (nonatomic, readonly) const float *tintColor;
@property (nonatomic, readonly) const float *pointSize;

@property (nonatomic, readonly) GraphicsStyle::ShapeMode rectMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode spriteMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode ellipseMode;
@property (nonatomic, readonly) GraphicsStyle::ShapeMode textMode;
@property (nonatomic, readonly) GraphicsStyle::LineCapMode lineCapMode;

@property (nonatomic, readonly) BOOL smooth;
@property (nonatomic, assign) ScreenCapture* capture;

- (id) init;
- (void) reset;
- (void) setupNextFrameState;
- (void) resetOffscreenFramebuffer;
- (void) deleteOffscreenFramebuffer;
- (void) clearModelMatrixStack;

- (Shader*) useShader:(NSString*)shaderName;
- (void) useShaderDirectly:(Shader*)shader;
- (void) useTexture:(GLuint)textureName;
- (void) useTexture:(GLuint)textureName withTarget:(GLenum)target;

#pragma mark - Framebuffer

- (void) setFramebuffer:(struct image_type_t*)image;
- (BOOL) flushCurrentRenderTarget;

#pragma mark - View
- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top;
- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top zNear:(float)near zFar:(float)far;
- (void) perspectiveFOV:(float)fovy aspect:(float)aspect zNear:(float)near zFar:(float)far;

- (void) scissorTestX:(int)x y:(int)y width:(int)w height:(int)h;
- (void) noScissorTest;

#pragma mark - Attributes
- (void) setAttributeNamed:(NSString*)name withPointer:(const GLvoid*)ptr size:(GLint)size andType:(GLenum)type;
- (void) disableAttributeNamed:(NSString*)name;

#pragma mark - Transform

- (void) rotateModel:(float)angle x:(float)x y:(float)y z:(float)z;
- (void) scaleModel:(float)x y:(float)y z:(float)z;
- (void) translateModel:(float)x y:(float)y z:(float)z;

- (void) pushMatrix;
- (void) popMatrix;
- (void) resetMatrix;
- (void) multMatrix:(const glm::mat4&)matrix;
- (void) setMatrix:(const glm::mat4&)matrix;
- (void) setViewMatrix:(const glm::mat4&)matrix;
- (void) setProjectionMatrix:(const glm::mat4&)matrix;
- (void) setFixMatrix:(const glm::mat4&)matrix;

#pragma mark - Style
- (BOOL) useStroke;

- (void) setStyleFontName:(const char*)name;
- (void) setStyleFontSize:(CGFloat)size;
- (void) setStyleTextWrapWidth:(CGFloat)wrap;
- (void) setStyleTextAlign:(GraphicsStyle::TextAlign)align;

- (void) setStyleTintColor:(glm::vec4)tint;
- (void) setStyleFillColor:(glm::vec4)fill;
- (void) setStyleStrokeColor:(glm::vec4)stroke;
- (void) setStyleStrokeWidth:(float)width;
- (void) setStylePointSize:(float)size;

- (void) setStyleSpriteMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleRectMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleEllipseMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleTextMode:(GraphicsStyle::ShapeMode)mode;
- (void) setStyleLineCapMode:(GraphicsStyle::LineCapMode)mode;
- (void) setStyleSmooth:(BOOL)smooth;

- (void) pushStyle;
- (void) popStyle;
- (void) resetStyle;

#pragma mark - Blending
- (void) setBlendMode:(RenderManagerBlendingMode)blendMode;

#pragma mark - Active texture
- (void) setActiveTexture:(GLenum)activeTexture;

@end
