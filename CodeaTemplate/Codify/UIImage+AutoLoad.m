//
//  UIImage+AutoLoad.m
//  Codea
//
//  Created by Simeon Nasilowski on 27/02/12.
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

#import "UIImage+AutoLoad.h"

@implementation UIImage (AutoLoad)

+ (id) imageNamedAuto:(NSString*)name
{
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        //Base name
        NSString *ext = [name pathExtension];
        NSString *base = [name stringByDeletingPathExtension];
        
        NSString *new = [NSString stringWithFormat:@"%@@2x", base];
        
        if( [[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:new ofType:ext]] )
        {
            return [UIImage imageNamed:[new stringByAppendingPathExtension:ext]];
        }
    }
    
    return [UIImage imageNamed:name];
}

@end
