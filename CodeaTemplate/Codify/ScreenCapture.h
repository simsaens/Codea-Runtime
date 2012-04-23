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
#import <AVFoundation/AVFoundation.h>

/**
 * Delegate protocol.  Implement this if you want to receive a notification when the
 * view completes a recording.
 *
 * When a recording is completed, the ScreenCaptureView will notify the delegate, passing
 * it the path to the created recording file if the recording was successful, or a value
 * of nil if the recording failed/could not be saved.
 */

@class ScreenCapture;

@protocol ScreenCaptureDelegate <NSObject>
- (void) boundCaptureFrameBuffer:(ScreenCapture*)capture;
- (BOOL) bindCaptureTextureTarget:(GLenum)target name:(GLuint)name;
- (void) recordingFinished:(NSString*)outputPathOrNil;
@end

/**
 * ScreenCaptureView, a UIView subclass that periodically samples its current display
 * and stores it as a UIImage available through the 'currentScreen' property.  The
 * sample/update rate can be configured (within reason) by setting the 'frameRate'
 * property.
 *
 * This class can also be used to record real-time video of its subviews, using the
 * 'startRecording' and 'stopRecording' methods.  A new recording will overwrite any
 * previously made recording file, so if you want to create multiple recordings per
 * session (or across multiple sessions) then it is your responsibility to copy/back-up
 * the recording output file after each session.
 *
 * To use this class, you must link against the following frameworks:
 *
 *  - AssetsLibrary
 *  - AVFoundation
 *  - CoreGraphics
 *  - CoreMedia
 *  - CoreVideo
 *  - QuartzCore
 *
 */

@class EAGLView;
@class CCTexture2D;

@interface ScreenCapture : NSObject 
{
    // Buffers
    int renderBufferWidth;
    int renderBufferHeight;    
    GLuint frameBufferHandle;
    GLuint depthFrameBufferHandle;
    GLuint depthRenderbuffer;
    
    // Texture cache
    CVOpenGLESTextureCacheRef textureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;    
    EAGLView* glView;
    
	//video writing
	AVAssetWriter *videoWriter;
	AVAssetWriterInput *videoWriterInput;
	AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
    
	//recording state
	BOOL _recording;
	NSDate* startedAt;
    NSURL* movieURL;
    
    // Watermark
    CCTexture2D* watermarkTexture;
}

//for recording video
- (bool) startRecording;
- (void) stopRecording;
- (void) stopRecordingAndDiscard;
- (void) saveMovieToCameraRoll;
- (void) discardMovie;
- (void) setupRenderTexture;
- (void) bindFramebuffer;
- (void) recordFrame;
- (void) flushCache;

//for accessing the current screen and adjusting the capture rate, etc.
@property(nonatomic, assign) id<ScreenCaptureDelegate> delegate;
@property(nonatomic, assign) BOOL recording;
@property(nonatomic, readonly) CVOpenGLESTextureRef renderTexture;
@property(nonatomic, readonly) int renderBufferWidth;
@property(nonatomic, readonly) int renderBufferHeight;
@property(nonatomic, readonly) CCTexture2D* watermarkTexture;
@property(nonatomic, readonly) GLuint frameBufferHandle;
@property(nonatomic, readonly) NSDate *startedAt;

- (id) initWithGLView:(EAGLView*)glv;

@end