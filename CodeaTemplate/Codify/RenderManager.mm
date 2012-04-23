//
//  RenderManager.m
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

#import "RenderManager.h"
#import "ShaderManager.h"

#import "SharedRenderer.h"
#import "CodifyAppDelegate.h"
#import "EAGLView.h"
#import "CCTexture2D.h"
#import "image.h"
#import "TextRenderer.h"
#import "ScreenCapture.h"

#define kMaxMatrixStackSize 100
#define kMaxStyleStackSize  100

int printOglError(const char *file, int line)
{
    
    GLenum glErr;
    int    retCode = 0;
    
    glErr = glGetError();
    if (glErr != GL_NO_ERROR)
    {
        printf("glError in file %s @ line %d: %d\n",
               file, line, glErr);
        retCode = 1;
    }
    return retCode;
}

@implementation RenderManager

@synthesize currentRenderTarget, textRenderer, frameCount, capture;

- (id) init
{
    self = [super init];
    if( self )
    {
        [self reset];        
    }
    return self;
}

- (void) deleteOffscreenFramebuffer
{
    if( offscreenFramebuffer )
    {
        glDeleteFramebuffers(1, &offscreenFramebuffer);   
        offscreenFramebuffer = 0;
    }
}

- (void) resetOffscreenFramebuffer
{
    if( offscreenFramebuffer )
        glDeleteFramebuffers(1, &offscreenFramebuffer);
    glGenFramebuffers(1, &offscreenFramebuffer);        
}

- (void) dealloc
{
    [textRenderer release];
    [capture release];
    
    [super dealloc];
}

- (void) clearModelMatrixStack
{
    modelMatrixStack.clear();
    modelMatrixStack.push_back(glm::mat4());
}

- (void) setupNextFrameState
{
    [self noScissorTest];    
        
    if( styleStack.empty() )
    {
        styleStack.push_back(GraphicsStyle());
    }
    else
    {
        styleStack.erase( styleStack.begin() + 1, styleStack.end() );
    }
    
    modelMatrixStack.clear();
    modelMatrixStack.push_back(glm::mat4());
    
    viewMatrix = glm::mat4();    
    projectionMatrix = glm::mat4();   
    fixMatrix = glm::ortho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    
    currentBlendMode = BLEND_MODE_NONE;
    [self setBlendMode:BLEND_MODE_PREMULT];
    
    [textRenderer flushCacheForFrame:frameCount];
    
    frameCount++;
}

- (void) reset
{
    frameCount = 0;
    currentTexture = 0;
    activeTexture = 0;

    lastShaderTransform.clear();
    lastShaderFill.clear();
    lastShaderTint.clear();
    lastShaderStroke.clear();
    shaderActiveAttribs.clear();
    
    [self deleteOffscreenFramebuffer];
    [self noScissorTest];
    
    styleStack.clear();
    styleStack.push_back(GraphicsStyle());
    
    modelMatrixStack.clear();
    modelMatrixStack.push_back(glm::mat4());
    
    viewMatrix = glm::mat4();    
    projectionMatrix = glm::mat4();        
    fixMatrix = glm::ortho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    
    currentBlendMode = BLEND_MODE_NONE;
    [self setBlendMode:BLEND_MODE_PREMULT];
    
    if( textRenderer == nil )
        textRenderer = [[TextRenderer alloc] init];
    
    [textRenderer flushCache];
}

#pragma mark - Helper functions to reduce redundancy

- (void) uploadModelViewMatrixForShader:(Shader*)shader
{
    XFormCache::iterator xit = lastShaderTransform.find(shader.programHandle);
    
    if( xit != lastShaderTransform.end() )
    {
        //glm::mat4& lastMatrix = (*xit).second;
        //if( !(modelViewMatrix == lastMatrix) )
        
        const float *lastMatrix = glm::value_ptr( (*xit).second );
        const float *curMatrix = self.modelViewMatrix;
        
        bool areSame = true;
        for( int i = 0; i < 16; i++ )
        {
            if( lastMatrix[i] != curMatrix[i] )
            {
                areSame = false;
                break;
            }
        }
        
        if( !areSame )
        {
            //Recache matrix for this shader
            lastShaderTransform[shader.programHandle] = modelViewMatrix;            
            //Upload uniform
            glUniformMatrix4fv([shader uniformLocation:@"ModelView"], 1, false, curMatrix);               
        }
    }    
    else
    {
        //Recache matrix for this shader
        lastShaderTransform[shader.programHandle] = modelViewMatrix;        
        //Upload uniform
        glUniformMatrix4fv([shader uniformLocation:@"ModelView"], 1, false, self.modelViewMatrix);                       
    }    
    
}

- (void) uploadColorUniform:(NSString*)uniform 
                  withCache:(ColorCache*)cache 
               currentValue:(glm::vec4*)color
                  forShader:(Shader*)shader
{
    ColorCache::iterator xit = cache->find(shader.programHandle);
    
    if( xit != cache->end() )
    {
        if( (*color) != (*xit).second )
        {   
            //Recache matrix for this shader
            (*cache)[shader.programHandle] = (*color);            
            //Upload uniform
            float *v = glm::value_ptr(*color);
            glUniform4fv([shader uniformLocation:uniform], 1, v);               
        }
    }    
    else
    {
        //Recache matrix for this shader
        (*cache)[shader.programHandle] = (*color);            
        //Upload uniform
        float *v = glm::value_ptr(*color);        
        glUniform4fv([shader uniformLocation:uniform], 1, v);               
    }        
}

#pragma mark - Shaders

- (Shader*) useShader:(NSString*)shaderName
{
    Shader *shader = [[ShaderManager sharedManager] shaderForName:shaderName];
    
    [self useShaderDirectly:shader];
    
    return shader;
}

- (void) useShaderDirectly:(Shader*)shader
{
//    [shader useShader];
//    
//    [self uploadModelViewMatrixForShader:shader];
//    
//    if( [shader hasUniform:@"FillColor"] )
//        glUniform4fv([shader uniformLocation:@"FillColor"], 1, self.fillColor);
//    
//    if( [shader hasUniform:@"TintColor"] )
//        glUniform4fv([shader uniformLocation:@"TintColor"], 1, self.tintColor);    
//    
//    if( [shader hasUniform:@"StrokeColor"] )
//        glUniform4fv([shader uniformLocation:@"StrokeColor"], 1, self.strokeColor);    
//    
//    if( [shader hasUniform:@"StrokeWidth"] )        
//        glUniform1fv([shader uniformLocation:@"StrokeWidth"], 1, self.strokeWidth); 
    
    [shader useShader];
    
    [self uploadModelViewMatrixForShader:shader];
    
    if( [shader hasUniform:@"FillColor"] )
    {
        if( currentBlendMode == BLEND_MODE_NORMAL )
        {
            [self uploadColorUniform:@"FillColor" 
                           withCache:&lastShaderFill 
                        currentValue:&styleStack.back().fillColor 
                           forShader:shader];            
        }
        else if( currentBlendMode == BLEND_MODE_PREMULT )
        {
        
            //glUniform4fv([shader uniformLocation:@"FillColor"], 1, self.fillColor);
            glm::vec4 multColor = styleStack.back().fillColor;
            
            multColor.r *= multColor.a;
            multColor.g *= multColor.a;
            multColor.b *= multColor.a;                        
            
            [self uploadColorUniform:@"FillColor" 
                           withCache:&lastShaderFill 
                        currentValue:&multColor
                           forShader:shader];
        }
    }
    
    if( [shader hasUniform:@"TintColor"] )
    {
        if( currentBlendMode == BLEND_MODE_NORMAL )
        {
            //glUniform4fv([shader uniformLocation:@"TintColor"], 1, self.tintColor);  
            [self uploadColorUniform:@"TintColor" 
                           withCache:&lastShaderTint 
                        currentValue:&styleStack.back().tintColor
                           forShader:shader];            
        }
        else if( currentBlendMode == BLEND_MODE_PREMULT )
        {
            glm::vec4 multColor = styleStack.back().tintColor;
            
            multColor.r *= multColor.a;
            multColor.g *= multColor.a;
            multColor.b *= multColor.a;            
            
            [self uploadColorUniform:@"TintColor" 
                           withCache:&lastShaderTint 
                        currentValue:&multColor
                           forShader:shader];                        
            
            //glUniform4fv([shader uniformLocation:@"TintColor"], 1, glm::value_ptr(multTintColor));                
        }            
    }
    
    if( [shader hasUniform:@"StrokeColor"] )
    {
        if( currentBlendMode == BLEND_MODE_NORMAL )
        {
            [self uploadColorUniform:@"StrokeColor" 
                           withCache:&lastShaderStroke 
                        currentValue:&styleStack.back().strokeColor 
                           forShader:shader];                    
        }
        else
        {
            glm::vec4 multColor = styleStack.back().strokeColor;
            
            multColor.r *= multColor.a;
            multColor.g *= multColor.a;
            multColor.b *= multColor.a;                        
            
            //glUniform4fv([shader uniformLocation:@"StrokeColor"], 1, self.strokeColor);    
            [self uploadColorUniform:@"StrokeColor" 
                           withCache:&lastShaderStroke 
                        currentValue:&multColor
                           forShader:shader];        
        }
    }
    
    if( [shader hasUniform:@"StrokeWidth"] )        
        glUniform1fv([shader uniformLocation:@"StrokeWidth"], 1, self.strokeWidth);    
}

- (void) useTexture:(GLuint)textureName withTarget:(GLenum)target
{
    if( textureName != currentTexture )
    {
        currentTexture = textureName;
        
        glBindTexture(target, currentTexture);
    }
}

- (void) useTexture:(GLuint)textureName
{
    [self useTexture:textureName withTarget:GL_TEXTURE_2D];
}

- (void) setAttributeNamed:(NSString*)name withPointer:(const GLvoid*)ptr size:(GLint)size andType:(GLenum)type
{
    Shader *current = [[ShaderManager sharedManager] currentShader];
    
    if( current )
    {
        GLuint loc = [current attributeHandle:name];
        glVertexAttribPointer(loc, size, type, 0, 0, ptr);
        
        AttribLocCache::iterator ait = shaderActiveAttribs.find( current.programHandle );
        
        if( ait != shaderActiveAttribs.end() )
        {
            std::set<GLuint>& locSet = shaderActiveAttribs[current.programHandle];
            
            std::set<GLuint>::iterator lit = locSet.find( loc );
            
            if( lit == locSet.end() )
            {
                locSet.insert(loc);                
                glEnableVertexAttribArray(loc);                            
            }
        }
        else
        {
            //Create set with loc, enable loc
            std::set<GLuint>& locSet = shaderActiveAttribs[current.programHandle];
            locSet.insert(loc);
            
            glEnableVertexAttribArray(loc);            
        }        
    }
}

- (void) disableAttributeNamed:(NSString*)name
{
    Shader *current = [[ShaderManager sharedManager] currentShader];
    
    if( current )
    {
        GLuint loc = [current attributeHandle:name];
        //glDisableVertexAttribArray(loc);
        
        AttribLocCache::iterator ait = shaderActiveAttribs.find( current.programHandle );        
        if( ait != shaderActiveAttribs.end() )
        {
            std::set<GLuint>& locSet = shaderActiveAttribs[current.programHandle];
            
            std::set<GLuint>::iterator lit = locSet.find( loc );
            
            if( lit != locSet.end() )
            {
                locSet.erase(lit);
                glDisableVertexAttribArray(loc);                            
            }
        }
        else
        {
            glDisableVertexAttribArray(loc);            
        }                
    }    
}

#pragma mark - Framebuffer

- (BOOL) flushCurrentRenderTarget
{
    //If we had a previous render target, read the pixels from viewport
    BOOL didFlush = NO;
    
    if( currentRenderTarget )
    {
        glReadPixels(0, 0, currentRenderTarget->rawWidth, currentRenderTarget->rawHeight, GL_RGBA, GL_UNSIGNED_BYTE, currentRenderTarget->data);

        currentRenderTarget->dataChanged = YES;
        currentRenderTarget = NULL;                   
        
        didFlush = YES;
        
        [self deleteOffscreenFramebuffer];
                
        glEnable(GL_DEPTH_TEST);        
    }    
    
    return didFlush;
}

- (void) setFramebuffer:(struct image_type_t*)image
{
    BOOL didFlush = [self flushCurrentRenderTarget];    
    
    if( image == NULL )
    {        
        //Set default framebuffer
        if( didFlush )
        {
            if (capture.recording)
            {
                [capture bindFramebuffer];
            }
            else
            {
                [[SharedRenderer renderer].glView setFramebuffer];    
            }
        }
    }
    else
    {       
        //Set the new image as the current render target
        currentRenderTarget = image;        
        
        currentRenderTarget->premultiplied = 1;
        
        updateImageTextureIfRequired(currentRenderTarget);
        
        glDisable(GL_DEPTH_TEST);
        
        [self resetOffscreenFramebuffer];        
        
        [self useTexture:currentRenderTarget->texture.name];
        
//        if (offscreenFramebuffer == 0)
//        {
//            glGenFramebuffers(1, &offscreenFramebuffer);   
//        }    
        
        glBindFramebuffer(GL_FRAMEBUFFER, offscreenFramebuffer);                
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, currentRenderTarget->texture.name, 0);              
        
        if( capture.recording )
        {
            //If recording, apply the proper projection
            
            [self setFixMatrix:glm::ortho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f)];
            
            //EAGLView *glView = [SharedRenderer renderer].glView;
            
            //[self orthoLeft:0 right:glView.bounds.size.width bottom:0 top:glView.bounds.size.height zNear:-10 zFar:10];            
        }
        
        //glViewport(0, 0, currentRenderTarget->width, currentRenderTarget->height);
    }
}

#pragma mark - Projection setup

- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top
{
    projectionMatrix = glm::ortho(left, right, bottom, top);
}

- (void) orthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top zNear:(float)near zFar:(float)far
{
    projectionMatrix = glm::ortho(left, right, bottom, top, near, far);    
}

- (void) perspectiveFOV:(float)fovy aspect:(float)aspect zNear:(float)near zFar:(float)far
{
    projectionMatrix = glm::perspective(fovy, aspect, near, far);
}

#pragma mark - Scissor testing

- (void) scissorTestX:(int)x y:(int)y width:(int)w height:(int)h
{
    // Invert scissor test while recording
    if (capture.recording)
    {
        y = capture.renderBufferHeight - y - h;
    }
    
    float scaleFactor = [SharedRenderer renderer].glView.contentScaleFactor;

    glEnable(GL_SCISSOR_TEST);
    glScissor(x * scaleFactor, y * scaleFactor, w * scaleFactor, h * scaleFactor);
}

- (void) noScissorTest
{
    glDisable(GL_SCISSOR_TEST);
}

#pragma mark - Tranforming the current matrix

- (void) rotateModel:(float)angle x:(float)x y:(float)y z:(float)z
{
    glm::mat4& modelMatrix = modelMatrixStack.back();    
    modelMatrix = glm::rotate(modelMatrix, angle, glm::vec3(x,y,z));
}

- (void) scaleModel:(float)x y:(float)y z:(float)z
{
    glm::mat4& modelMatrix = modelMatrixStack.back();
    modelMatrix = glm::scale(modelMatrix, glm::vec3(x,y,z));
}

- (void) translateModel:(float)x y:(float)y z:(float)z
{
    glm::mat4& modelMatrix = modelMatrixStack.back();    
    modelMatrix = glm::translate(modelMatrix, glm::vec3(x,y,z));    
}

#pragma mark - Matrix management 

- (void) pushMatrix
{
    if( modelMatrixStack.size() < kMaxMatrixStackSize )
    {
        modelMatrixStack.push_back( modelMatrixStack.back() );
    }
    else
    {
        //TODO: Print a warning to the user console
    }
}

- (void) popMatrix
{
    if( modelMatrixStack.size() > 1 )
    {
        modelMatrixStack.pop_back();
    }
    else
    {
        //TODO: Print a warning to the user console
    }
}

- (void) resetMatrix
{
    glm::mat4& modelMatrix = modelMatrixStack.back();    
    modelMatrix = glm::mat4();
}

- (void) multMatrix:(const glm::mat4&)matrix
{
    glm::mat4& modelMatrix = modelMatrixStack.back();
    modelMatrix = modelMatrix * matrix;
}

- (void) setMatrix:(const glm::mat4&)matrix
{
    glm::mat4& modelMatrix = modelMatrixStack.back();
    modelMatrix = matrix;
}

- (void) setViewMatrix:(const glm::mat4&)matrix
{
    viewMatrix = matrix;
}

- (void) setProjectionMatrix:(const glm::mat4&)matrix
{
    projectionMatrix = matrix;
}

- (void) setFixMatrix:(const glm::mat4&)matrix
{
    fixMatrix = matrix;
}

- (const float *) modelMatrix
{
    return glm::value_ptr(modelMatrixStack.back());
}

- (const float *) viewMatrix
{
    return glm::value_ptr(viewMatrix);
}

- (const float *) projectionMatrix 
{
    return glm::value_ptr(projectionMatrix);
}

- (const float *) modelViewMatrix
{
    modelViewMatrix = fixMatrix * projectionMatrix * (viewMatrix * modelMatrixStack.back());
    
    return glm::value_ptr(modelViewMatrix);
}

#pragma mark - Should use stroke

- (BOOL) useStroke
{
    GraphicsStyle& style = styleStack.back();
    return style.strokeWidth > 0;
}

#pragma mark - Fonts

- (CGFloat) fontSize
{
    GraphicsStyle& style = styleStack.back();
    return style.fontSize;
}

- (CGFloat) textWrapWidth
{
    GraphicsStyle& style = styleStack.back();
    return style.textWrapWidth;
}

- (GraphicsStyle::TextAlign) textAlign
{
    GraphicsStyle& style = styleStack.back();
    return style.textAlign;
}

- (const char*) fontName
{
    GraphicsStyle& style = styleStack.back();
    return style.fontName.c_str();
}

#pragma mark - Transforming the current style

- (void) setStyleFontName:(const char*)name
{
    GraphicsStyle& style = styleStack.back();
    style.fontName = name;
}

- (void) setStyleFontSize:(CGFloat)size
{
    GraphicsStyle& style = styleStack.back();
    style.fontSize = size;
}

- (void) setStyleTextWrapWidth:(CGFloat)wrap
{
    GraphicsStyle& style = styleStack.back();
    style.textWrapWidth = wrap;    
}

- (void) setStyleTextAlign:(GraphicsStyle::TextAlign)align
{
    GraphicsStyle& style = styleStack.back();
    style.textAlign = align;
}

- (void) setStyleTintColor:(glm::vec4)tint
{
    GraphicsStyle& style = styleStack.back();
    style.tintColor = tint;    
}

- (void) setStyleFillColor:(glm::vec4)fill
{
    GraphicsStyle& style = styleStack.back();
    style.fillColor = fill;
}

- (void) setStyleStrokeColor:(glm::vec4)stroke
{
    GraphicsStyle& style = styleStack.back();    
    style.strokeColor = stroke;
}

- (void) setStyleStrokeWidth:(float)width
{
    GraphicsStyle& style = styleStack.back();    
    style.strokeWidth = width;
}

- (void) setStylePointSize:(float)size
{
    GraphicsStyle& style = styleStack.back();    
    style.pointSize = size;
}

- (void) setStyleSpriteMode:(GraphicsStyle::ShapeMode)mode
{    
    if( mode == GraphicsStyle::SHAPE_MODE_CORNER || mode == GraphicsStyle::SHAPE_MODE_CORNERS || 
       mode == GraphicsStyle::SHAPE_MODE_CENTER || mode == GraphicsStyle::SHAPE_MODE_RADIUS )
    {
        GraphicsStyle& style = styleStack.back();            
        style.spriteMode = mode;
    }
}

- (void) setStyleRectMode:(GraphicsStyle::ShapeMode)mode
{    
    if( mode == GraphicsStyle::SHAPE_MODE_CORNER || mode == GraphicsStyle::SHAPE_MODE_CORNERS || 
        mode == GraphicsStyle::SHAPE_MODE_CENTER || mode == GraphicsStyle::SHAPE_MODE_RADIUS )
    {
        GraphicsStyle& style = styleStack.back();            
        style.rectMode = mode;
    }
}

- (void) setStyleEllipseMode:(GraphicsStyle::ShapeMode)mode
{
    if( mode == GraphicsStyle::SHAPE_MODE_CORNER || mode == GraphicsStyle::SHAPE_MODE_CORNERS || 
        mode == GraphicsStyle::SHAPE_MODE_CENTER || mode == GraphicsStyle::SHAPE_MODE_RADIUS )
    {
        GraphicsStyle& style = styleStack.back();        
        style.ellipseMode = mode;
    }
}

- (void) setStyleTextMode:(GraphicsStyle::ShapeMode)mode
{
    if( mode == GraphicsStyle::SHAPE_MODE_CORNER || mode == GraphicsStyle::SHAPE_MODE_CENTER )
    {
        GraphicsStyle& style = styleStack.back();        
        style.textMode = mode;
    }    
}

- (void) setStyleLineCapMode:(GraphicsStyle::LineCapMode)mode
{
    if( mode < GraphicsStyle::LINE_CAP_NUM_MODES )
    {
        GraphicsStyle& style = styleStack.back();        
        style.lineCapMode = mode;
    }
}

- (void) setStyleSmooth:(BOOL)smooth
{
    GraphicsStyle& style = styleStack.back();        
    style.smooth = smooth;
}

- (const float *) strokeWidth
{
    GraphicsStyle& style = styleStack.back();
    return &style.strokeWidth;
}

- (const float *) strokeColor
{
    GraphicsStyle& style = styleStack.back();
    return glm::value_ptr(style.strokeColor);
}

- (const float *) tintColor
{
    GraphicsStyle& style = styleStack.back();
    return glm::value_ptr(style.tintColor);
}

- (const float *) fillColor
{
    GraphicsStyle& style = styleStack.back();
    return glm::value_ptr(style.fillColor);
}

- (const float *) pointSize
{
    GraphicsStyle& style = styleStack.back();
    return &style.pointSize;
}

- (GraphicsStyle::ShapeMode) spriteMode
{
    GraphicsStyle& style = styleStack.back();
    return style.spriteMode;
}

- (GraphicsStyle::ShapeMode) rectMode
{
    GraphicsStyle& style = styleStack.back();
    return style.rectMode;
}

- (GraphicsStyle::ShapeMode) ellipseMode
{
    GraphicsStyle& style = styleStack.back();
    return style.ellipseMode;
}

- (GraphicsStyle::ShapeMode) textMode
{
    GraphicsStyle& style = styleStack.back();
    return style.textMode;
}

- (GraphicsStyle::LineCapMode) lineCapMode
{
    GraphicsStyle& style = styleStack.back();
    return style.lineCapMode;
}

- (BOOL) smooth
{
    GraphicsStyle& style = styleStack.back();
    return style.smooth;    
}

#pragma mark - Style management

- (void) pushStyle
{
    if( styleStack.size() < kMaxStyleStackSize )
    {
        styleStack.push_back( styleStack.back() );
    }
    else
    {
        //TODO: Print a warning to the user console
    }    
}

- (void) popStyle
{
    if( styleStack.size() > 1 )
    {
        styleStack.pop_back();
    }
    else
    {
        //TODO: Print a warning to the user console
    }    
}

- (void) resetStyle
{
    GraphicsStyle& style = styleStack.back();
    style = GraphicsStyle();
}

#pragma mark - Blending

- (void) setBlendMode:(RenderManagerBlendingMode)blendMode
{
    if (blendMode != currentBlendMode) 
    {
        currentBlendMode = blendMode;
        switch (currentBlendMode) 
        {
            case BLEND_MODE_NORMAL:
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                break;
            case BLEND_MODE_PREMULT:
                glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
                break;
            default:
                break;
        }
    }
}

#pragma mark - Active texture

- (void) setActiveTexture:(GLenum)newActiveTexture
{
    if( newActiveTexture != activeTexture )
    {
        activeTexture = newActiveTexture;
        glActiveTexture(activeTexture);
    }
}

@end
