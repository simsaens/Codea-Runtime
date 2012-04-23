//
//  KeyboardInputView.h
//  Codea
//
//  Created by Simeon Nasilowski on 14/01/12.
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

@class KeyboardInputView;

@protocol KeyboardInputViewDelegate <NSObject>

- (void) keyboardInputView:(KeyboardInputView*)view WillInsertText:(NSString*)text;

@end

@interface KeyboardInputView : UIView<UITextViewDelegate>
{
    UITextView *hiddenTextView;
}

@property (assign, nonatomic) BOOL active;
@property (assign, nonatomic) id<KeyboardInputViewDelegate> delegate;
@property (readonly, nonatomic) NSString *currentText;

@end
