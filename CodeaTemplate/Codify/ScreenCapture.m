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

#import "ScreenCapture.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "EAGLView.h"
#import "CCTexture2D.h"
#import "SharedRenderer.h"

@interface ScreenCapture(Private)
- (void) writeVideoFrameAtTime:(CMTime)time;
@end

@implementation ScreenCapture

@synthesize delegate, recording=_recording;
@synthesize renderTexture;
@synthesize renderBufferWidth, renderBufferHeight;
@synthesize watermarkTexture;
@synthesize frameBufferHandle;
@synthesize startedAt;

- (id) initWithGLView:(EAGLView*)glv
{
	self = [super init];
    if (self) 
    {
        glView = glv;    
        
        // The temporary path for the video before saving it to the photo album
        movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"Movie.MOV"]];
        [movieURL retain];
        
        // Initialization code
        _recording = false;
        videoWriter = nil;
        videoWriterInput = nil;
        avAdaptor = nil;
        startedAt = nil;
        
        watermarkTexture = [[CCTexture2D alloc] initWithImage:[UIImage imageNamed:@"MadeWithCodea.png"]];
	}
	return self;
}

- (void)cleanupWriter
{
	[avAdaptor release];
	avAdaptor = nil;
	
	[videoWriterInput release];
	videoWriterInput = nil;
	
	[videoWriter release];
	videoWriter = nil;
	
	[startedAt release];
	startedAt = nil;
 
    if (frameBufferHandle) 
    {
        glDeleteFramebuffers(1, &frameBufferHandle);
        frameBufferHandle = 0;
    }
    
    if (depthRenderbuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
        
    if (textureCache) 
    {
        CFRelease(textureCache);
        textureCache = 0;
    }
    
    if (renderTarget)
    {
        CVPixelBufferRelease( renderTarget );    
        renderTarget = 0;
    }
    
}

- (void)dealloc 
{
    [self cleanupWriter];
    [watermarkTexture release];
	[super dealloc];
}

- (NSURL*) tempFileURL 
{
	NSString* outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"output.mp4"];
	NSURL* outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];	
	[outputPath release];
	return [outputURL autorelease];
}

- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    });
}

- (void)removeTempFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [[self tempFileURL] path];
    if ([fileManager fileExistsAtPath:filePath]) 
    {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success)
        {
            [self showError:error];
        }            
    }
}

- (void)saveMovieToCameraRoll
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[self tempFileURL]                                
                                completionBlock:^(NSURL *assetURL, NSError *error) 
                                {
                                    if (error)
                                    {
                                        [self showError:error];
                                        [self removeTempFile];
                                    }
                                    else
                                    {
                                        [self removeTempFile];
                                    }                                    
//                                    dispatch_async(movieWritingQueue, ^
//                                    {
//                                        recordingWillBeStopped = NO;
//                                        self.recording = NO;
//                                        
//                                        [self.delegate recordingDidStop];
//                                    });
                                }];
    [library release];
}

- (void) discardMovie
{
    [self removeTempFile];
}

-(BOOL) setupWriter
{            
	NSError* error = nil;
    [self removeTempFile];
	videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(videoWriter);
	
	//Configure video
    float bitsPerPixel = 11.4;
    int numPixels = renderBufferWidth * renderBufferHeight;
    int bitsPerSecond = numPixels * bitsPerPixel;            
    
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                           [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
										   nil ];
	
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:renderBufferWidth], AVVideoWidthKey,
								   [NSNumber numberWithInt:renderBufferHeight], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	videoWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] retain];
	
	NSParameterAssert(videoWriterInput);
	videoWriterInput.expectsMediaDataInRealTime = YES;
	NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
//                                      [NSNumber numberWithInt:vw], kCVPixelBufferWidthKey,
//                                      [NSNumber numberWithInt:vh], kCVPixelBufferHeightKey,
//                                      [NSNumber numberWithInt:vw*4], kCVPixelBufferBytesPerRowAlignmentKey, nil];
    
	avAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes] retain];
	
    
	//add input
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);    
    
	[videoWriter addInput:videoWriterInput];
	[videoWriter startWriting];
	[videoWriter startSessionAtSourceTime:kCMTimeZero];
	
	return YES;
}

- (BOOL)initializeBuffers
{    
    glGenFramebuffers(1, &frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);

    renderBufferWidth = glView.frame.size.width * glView.contentScaleFactor;
    renderBufferHeight = glView.frame.size.height * glView.contentScaleFactor;   
    
    //Scale video recording down, if necessary
    if( renderBufferHeight > 1080 )
    {
        float aspect = (float)renderBufferWidth/(float)renderBufferHeight;
        renderBufferHeight = 1080;        
        renderBufferWidth = renderBufferHeight * aspect;        
    }

    // Create depth buffer    
    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, renderBufferWidth, renderBufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, frameBufferHandle);    
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }    
    
    DBLog(@"SCREENCAPTURE: Created Framebuffer (%d x %d)", renderBufferWidth, renderBufferHeight);
    
    //  Create a new CVOpenGLESTexture cache
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, glView.context, NULL, &textureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return NO;
    }
    
    NSDictionary *pbAttr = [NSDictionary dictionaryWithObject:[NSDictionary dictionary]
                                                       forKey:(id)kCVPixelBufferIOSurfacePropertiesKey]; 
        
    int status = CVPixelBufferCreate(kCFAllocatorDefault, renderBufferWidth, renderBufferHeight,
                                     kCVPixelFormatType_32BGRA,
                                     (CFDictionaryRef)pbAttr,
                                     &renderTarget);
    
    if(status != 0)
    {
        //could not get a buffer from the pool
        NSLog(@"Error creating pixel buffer:  status=%d", status);
        return NO;
    }
    
    return YES;
}

- (void) setupRenderTexture
{
    // first create a texture from our renderTarget
    // textureCache will be what you previously made with CVOpenGLESTextureCacheCreate
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                                 textureCache,
                                                                 renderTarget,
                                                                 NULL, // texture attributes
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA, // opengl format
                                                                 renderBufferWidth,
                                                                 renderBufferHeight,
                                                                 GL_BGRA, // native iOS format
                                                                 GL_UNSIGNED_BYTE,
                                                                 0,
                                                                 &renderTexture);
    if (!renderTexture || err) 
    {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);  
        return;
    }
    
    // Bind and set texture parameters    
    
    GLenum target = CVOpenGLESTextureGetTarget(renderTexture);
    GLuint name = CVOpenGLESTextureGetName(renderTexture);
    
    if( [delegate respondsToSelector:@selector(bindCaptureTextureTarget:name:)] )
    {
        if( ![delegate bindCaptureTextureTarget:target name:name] )
        {
            glBindTexture(target, name);            
        }
    }
    else
    {
        glBindTexture(target, name);
    }
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);  
        
    glViewport(0, 0, renderBufferWidth, renderBufferHeight);
    
    if( [delegate respondsToSelector:@selector(boundCaptureFrameBuffer:)] )
    {
        [delegate boundCaptureFrameBuffer:self];
    }
}

- (void) bindFramebuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);      
    glViewport(0, 0, renderBufferWidth, renderBufferHeight);    
    
    if( [delegate respondsToSelector:@selector(boundCaptureFrameBuffer:)] )
    {
        [delegate boundCaptureFrameBuffer:self];
    }    
}

- (void) flushCache
{
    CVOpenGLESTextureCacheFlush(textureCache, 0);
}

- (void) completeRecordingSession 
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[videoWriterInput markAsFinished];
    
    float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
    CMTime time = CMTimeMake((int)millisElapsed, 1000);
    [videoWriter endSessionAtSourceTime:time];
	
	// Wait for the video
	int status = videoWriter.status;
	while (status == AVAssetWriterStatusUnknown) 
    {
		DBLog(@"SCREENCAPTURE: Waiting...");
		[NSThread sleepForTimeInterval:0.5f];
		status = videoWriter.status;
	}
	
	@synchronized(self) 
    {
		BOOL success = [videoWriter finishWriting];
		if (!success) 
        {
			NSLog(@"finishWriting returned NO: %@", videoWriter.error);
		}
		
		[self cleanupWriter];
		
		id delegateObj = self.delegate;
		NSString *outputPath = [[NSString alloc] initWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"output.mp4"];
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
		
		DBLog(@"SCREENCAPTURE: Completed recording, file is stored at:  %@", outputURL);
		if ([delegateObj respondsToSelector:@selector(recordingFinished:)]) 
        {
			[delegateObj performSelectorOnMainThread:@selector(recordingFinished:) withObject:(success ? outputURL : nil) waitUntilDone:YES];
		}
		
		[outputPath release];
		[outputURL release];
	}
	
	[pool drain];
}

- (bool) startRecording
{
	bool result = NO;
	@synchronized(self) 
    {
		if (! _recording) 
        {
            glView.layer.borderWidth = 2; 
            glView.layer.borderColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.6f].CGColor;
            
            [self initializeBuffers];
			result = [self setupWriter];
            
			startedAt = [[NSDate date] retain];
			_recording = true;
		}
	}
	
	return result;
}

- (void) stopRecordingAndDiscard
{
	@synchronized(self) 
    {
		if (_recording) 
        {
            glView.layer.borderWidth = 0;            
			_recording = false;
			[self completeRecordingSession];
            [self removeTempFile];
		}
	}    
}

- (void) stopRecording 
{
	@synchronized(self) 
    {
		if (_recording) 
        {
            glView.layer.borderWidth = 0;            
			_recording = false;
			[self completeRecordingSession];
		}
	}
}

-(void) recordFrame
{
    if (_recording && [videoWriterInput isReadyForMoreMediaData] && renderTexture)
    {                                
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        CMTime time = CMTimeMake((int)millisElapsed, 1000);        
        
        if (kCVReturnSuccess == CVPixelBufferLockBaseAddress(renderTarget, kCVPixelBufferLock_ReadOnly)) 
        {                            
            // process pixels how you like!            
            BOOL success = [avAdaptor appendPixelBuffer:renderTarget withPresentationTime:time];
            if (!success)
            {
                NSLog(@"Warning:  Unable to write buffer to video");
            }                            
            
            CVPixelBufferUnlockBaseAddress(renderTarget, kCVPixelBufferLock_ReadOnly);            
        }       
        else
        {
            NSLog(@"Warning:  Unable to lock pixel buffer");
        }
	}	
        
    // Flush the CVOpenGLESTexture cache and release the texture
    CVOpenGLESTextureCacheFlush(textureCache, 0);        
    
    if( renderTexture )
    {
        CFRelease(renderTexture);		    
        renderTexture = 0;
    }
}

@end