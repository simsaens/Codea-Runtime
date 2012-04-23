//
//  ColorTextureTransform.vsh
//
//  Created by John Millard on 7/01/12.
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

uniform mat4 ModelView;
uniform bool SpriteMode;

attribute vec4 Vertex;
attribute vec4 Color;
attribute vec2 TexCoord;

varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    gl_Position = ModelView * Vertex;
    
    if (SpriteMode)
    {
        vColor.rgb = Color.rgb * Color.a;
        vColor.a = Color.a;        
        vTexCoord = highp vec2(TexCoord.s, 1.0-TexCoord.t);
    }
    else
    {
        vColor.rgb = Color.rgb * Color.a;
        vColor.a = Color.a;
        vTexCoord = TexCoord;
    }
}
