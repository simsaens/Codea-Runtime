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

varying highp vec2 vTexCoord;

uniform highp float Radius;

uniform lowp vec4 StrokeColor;

void main()
{
    highp float RadiusAA = Radius-2.5;
    
    //highp vec2 scaledPointSq = vec2( (vTexCoord.x * Radius) * (vTexCoord.x * Radius), (vTexCoord.y * Radius) * (vTexCoord.y * Radius) );
    
    highp vec2 pos = vTexCoord*Radius;
    highp float dist_squared = dot(pos, pos);
    
    //Regular blend
    //gl_FragColor = mix( vec4(StrokeColor.rgb,0), StrokeColor, smoothstep(Radius*Radius,RadiusAA*RadiusAA,dist_squared));
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), StrokeColor, smoothstep(Radius*Radius,RadiusAA*RadiusAA,dist_squared));    
}

