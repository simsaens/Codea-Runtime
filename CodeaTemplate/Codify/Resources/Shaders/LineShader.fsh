//
//  LineShader.fsh
//  Codea
//
//  Created by Dylan Sale on 24/09/11.
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

varying highp vec2 vTexCoord;

uniform lowp vec4 StrokeColor;
uniform mediump vec2 Size;

void main()
{
    mediump vec2 nTexCoord = vec2( (vTexCoord.x + 1.0)*Size.x, (vTexCoord.y + 1.0)*Size.y ) * 0.5;
    mediump float closestDist =  min(min(nTexCoord.x, Size.x - nTexCoord.x), min( nTexCoord.y, Size.y - nTexCoord.y ));

    //Regular blend
    //gl_FragColor = mix( vec4(StrokeColor.rgb,0), StrokeColor, smoothstep(0.0, 2.5, closestDist) );     
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), StrokeColor, smoothstep(0.0, 2.5, closestDist) ); 
}

