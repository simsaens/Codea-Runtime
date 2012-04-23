//
//  KeyboardInputView.m
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

#import "KeyboardInputView.h"

@implementation KeyboardInputView

@synthesize active, delegate;

- (void) setup
{
    // Initialization code
    self.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];      
    
    hiddenTextView = [[UITextView alloc] initWithFrame:self.bounds];
    
    hiddenTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    hiddenTextView.autocorrectionType = UITextAutocorrectionTypeNo;    
    hiddenTextView.spellCheckingType = UITextSpellCheckingTypeNo;
    hiddenTextView.delegate = self;
    
    [self addSubview:hiddenTextView];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) 
    {
        [self setup];
    }
    
    return self;        
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self setup];
    }
    
    return self;    
}
    
- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [hiddenTextView release];
    [super dealloc];
}

- (void)didEnterBackground 
{
    if (self.active)
        [hiddenTextView resignFirstResponder];
}

- (void)didBecomeActive 
{
    if (self.active)
        [hiddenTextView becomeFirstResponder];
}

#pragma mark - Text Field Delegate

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if( [delegate respondsToSelector:@selector(keyboardInputView:WillInsertText:)] )
    {
        [delegate keyboardInputView:self WillInsertText:text];
    }
    
    return YES;    
}

#pragma mark - Properties

- (NSString*) currentText
{
    return hiddenTextView.text;
}

- (void) setActive:(BOOL)newActive
{
    active = newActive;
    
    if( active )
    {
        if( ![hiddenTextView isFirstResponder] )
        {
            hiddenTextView.text = @"";
            [hiddenTextView becomeFirstResponder];
        }
    }
    else
    {
        if( [hiddenTextView isFirstResponder] )
        {   
            hiddenTextView.text = @"";
            [hiddenTextView resignFirstResponder];
        }
    }
}

@end
