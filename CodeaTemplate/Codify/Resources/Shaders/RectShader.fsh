//
//  Shader.fsh
//  Codea
//
//  Created by Simeon Nasilowski on 17/05/11.
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

/*
 
 (2,  1)
 (3,  5)
 (5,  8)
 (7, 10)
 _________________
 | __x_________  |
 | |           | |
 | |           | |
 | |           | | 
 | |  x        | |
 | |           | |
 | |           | | 
 | |     x     | |
 | |           | | 
 | |___________| | 
 |______________x|
 
*/
varying highp vec2 vTexCoord;

uniform lowp vec4 FillColor;
uniform lowp vec4 StrokeColor;

uniform mediump vec2 Size;
uniform mediump float StrokeWidth;

void main()
{
    mediump vec2 nTexCoord = vec2( vTexCoord.x + 1.0, vTexCoord.y + 1.0 ) * 0.5;
    mediump vec2 xyInset = vec2( nTexCoord.x * Size.x, nTexCoord.y * Size.y );
    mediump float closestDist = min( min( xyInset.x, Size.x - xyInset.x ), min( xyInset.y, Size.y - xyInset.y ) );

    //Regular
    //lowp vec4 fragCol = mix( StrokeColor, FillColor, smoothstep( StrokeWidth-2.5, StrokeWidth, closestDist ) );    
    
    //Premult
    lowp vec4 fragCol = mix( StrokeColor, FillColor, smoothstep( StrokeWidth-1.0, StrokeWidth, closestDist ) );

    //Regular
    //gl_FragColor = mix( vec4(fragCol.rgb,0), fragCol, smoothstep(0.0, 2.5, closestDist) );    
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), fragCol, smoothstep(0.0, 1.0, closestDist) );
}

