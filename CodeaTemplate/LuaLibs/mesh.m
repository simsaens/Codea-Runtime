//
//  mesh2d.m
//  Codea
//
//  Created by John Millard on 6/01/12.
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

#include <stdio.h>

#include "mesh.h"
#include "color.h"
#include "lua.h"
#include "lauxlib.h"
#include "vec2.h"
#include "vec3.h"
#include "object_reg.h"

#import "RenderCommands.h"
#import "SpriteManager.h"

#define MESH_TYPE		"mesh"
#define MESH_SIZE     sizeof(mesh_type)

static void initBuffer(float_buffer* buffer, size_t elementSize)
{
    buffer->capacity = 3000;
    buffer->elementSize = elementSize;
    buffer->buffer = malloc(buffer->capacity * buffer->elementSize * sizeof(GLfloat));
    buffer->length = 0;
}

static float* getVertex(mesh_type *mesh, int index)
{
    if( index < mesh->vertices.length && index >= 0 )
    {
        return &mesh->vertices.buffer[ index * mesh->vertices.elementSize + 0 ];
    }
    
    return NULL;
}

static float* getColor(mesh_type *mesh, int index)
{
    if( index < mesh->colors.length && index >= 0 )
    {
        return &mesh->colors.buffer[ index * mesh->colors.elementSize + 0 ];
    }
    
    return NULL;
}

static float* getTexCoord(mesh_type *mesh, int index)
{
    if( index < mesh->texCoords.length && index >= 0 )
    {
        return &mesh->texCoords.buffer[ index * mesh->texCoords.elementSize + 0 ];
    }
    
    return NULL;
}

static void clearBuffer(float_buffer* buffer)
{
    buffer->length = 0;
}

static void freeBuffer(float_buffer* buffer)
{
    if (buffer->buffer)
    {
        free(buffer->buffer);
        buffer->capacity = 0;
        buffer->length = 0;
    }
}

static void resizeBuffer(float_buffer* buffer, int newLength)
{    
    // Grow buffer if capacity is insufficient
    if (newLength > buffer->capacity)
    {
        while(buffer->capacity < newLength)
        {
            buffer->capacity *= 2;
        }
        buffer->buffer = realloc(buffer->buffer, buffer->capacity * buffer->elementSize * sizeof(GLfloat));
        
        if(buffer->buffer != NULL)
        {
            //Zero out new parts of the buffer            
            for( int i = MAX( buffer->length, 0 ); i < newLength; i++ )
            {
                buffer->buffer[ i * buffer->elementSize ] = 0;
            }
        }
        else 
        {
            NSLog(@"Mesh: buffer failed to resize");
        }
    }        
    buffer->length = newLength;
}

mesh_type *checkMesh(lua_State *L, int i)
{
    if( lua_isuserdata(L, i) )
    {
        mesh_type *meshData = luaL_checkudata(L,i,MESH_TYPE);
        
        luaL_argcheck(L, meshData != NULL, 1, "`mesh' expected");
        
        return meshData;
    }
    
    return NULL;
}

static mesh_type *Pget(lua_State *L, int i)
{
    if (luaL_checkudata(L, i, MESH_TYPE) == NULL) luaL_typerror(L, i, MESH_TYPE);
    return lua_touserdata(L, i);
}

static mesh_type *Pnew(lua_State *L)
{
    mesh_type *meshData = lua_newuserdata(L, MESH_SIZE);
    initBuffer(&meshData->vertices, 3);
    initBuffer(&meshData->colors, 4);
    initBuffer(&meshData->texCoords, 2);
//    initBuffer(&meshData->texCoordsReversed, 2);
    
    meshData->valid = YES;
    meshData->spriteName = nil;
    meshData->texture = nil;
    meshData->image = NULL;
    
    luaL_getmetatable(L, MESH_TYPE);
    lua_setmetatable(L, -2);
    return meshData;
}


mesh_type* createMesh2D(lua_State *L)
{
    mesh_type* meshData = Pnew(L);    
    return meshData;
}

static int Lnew(lua_State *L)			/** color(r, g, b, a) */
{
    Pnew(L);
    return 1;
}

static BOOL checkValid(mesh_type* meshData)
{
    if (meshData->vertices.length == 0 && meshData->texCoords.length == 0 && meshData->colors.length == 0)
    {
        return YES;
    }
    else if (meshData->vertices.length > 0)
    {   
        BOOL validColors = (meshData->colors.length == 0) || (meshData->vertices.length == meshData->colors.length);
        BOOL validTexCoords = (meshData->texCoords.length == 0) || (meshData->vertices.length == meshData->texCoords.length);
        
        if (validColors && validTexCoords)
        {
            return YES;
        }
    }
    return NO;
}

static int Lget(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if ( strcmp(c, "texture") == 0 )
    {
        if (meshData->texture)
        {
            lua_pushstring(L, [meshData->spriteName UTF8String]);
        }
        else if (meshData->image)
        {
            lua_rawgeti(L, LUA_REGISTRYINDEX, meshData->imageRef);
        }        
        else
        {
            lua_pushnil(L);
        }
    }    
    else if ( strcmp(c, "size" ) == 0 )
    {
        lua_pushinteger(L, meshData->vertices.length);
        return 1;
    }
    else if ( strcmp(c, "vertices") == 0 )
    {
        // TODO: 2D and 3D mode checks...
        lua_createtable(L, meshData->vertices.length, 0);
        for (int i = 1, j = 0; i <= meshData->vertices.length; i++)
        {          
            pushvec3(L, meshData->vertices.buffer[j++], meshData->vertices.buffer[j++], meshData->vertices.buffer[j++]);
            lua_rawseti(L, -2, i);
        }        
    } 
    else if ( strcmp(c, "colors") == 0 )
    {
        lua_createtable(L, meshData->colors.length, 0);
        for (int i = 1, j = 0; i <= meshData->colors.length; i++)
        {            
            pushcolor(L, meshData->colors.buffer[j++], meshData->colors.buffer[j++], meshData->colors.buffer[j++], meshData->colors.buffer[j++]);
            lua_rawseti(L, -2, i);
        }                
    } 
    else if ( strcmp(c, "texCoords") == 0 )
    {
        lua_createtable(L, meshData->texCoords.length, 0);
        for (int i = 1, j = 0; i <= meshData->texCoords.length; i++)
        {            
            pushvec2(L, meshData->texCoords.buffer[j++], 1-meshData->texCoords.buffer[j++]);
//            pushvec2(L, meshData->texCoordsReversed.buffer[j], 1-meshData->texCoordsReversed.buffer[j+1]);            
//            j += 2;
            lua_rawseti(L, -2, i);
        }                
    } 
    else if ( strcmp(c, "textureWidth") == 0 )
    {
        if (meshData->texture)
        {
            lua_pushinteger(L, meshData->texture.pixelsWide);
        }
        else if (meshData->image)
        {
            lua_pushinteger(L, meshData->image->scaledWidth);
        }
    }
    else if ( strcmp(c, "textureHeight") == 0 )
    {
        if (meshData->texture)
        {
            lua_pushinteger(L, meshData->texture.pixelsHigh);
        }
        else if (meshData->image)
        {
            lua_pushinteger(L, meshData->image->scaledHeight);
        }
    }
    else if ( strcmp(c, "valid") == 0 )
    {
        lua_pushboolean(L, meshData->valid);
    }
    else
    {
        //Load the metatable and value for key
        luaL_getmetatable(L, MESH_TYPE);
        lua_pushstring(L, c);
        lua_gettable(L, -2);
    }    
    
    return 1;    
}

static int Lset(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    const char* c = luaL_checkstring(L,2);
    
    if (strcmp(c, "texture") == 0 )
    {
        if (lua_isnil(L, 3))
        {
            if (meshData->texture)
            {
                [meshData->texture release];
                meshData->texture = nil;
                [meshData->spriteName release];
                meshData->spriteName = nil;
            }
            else if (meshData->image)
            {
                luaL_unref(L, LUA_REGISTRYINDEX, meshData->imageRef);
                meshData->image = NULL;
            }
            
            meshData->valid = checkValid(meshData);
            
            return 1;
        }
        else if (lua_isstring(L, 3))
        {                        
            // set texture based on sprite name
            size_t texStrLen = 0;
            const char* texStr = lua_tolstring(L, 3, &texStrLen);
            if (texStr && texStrLen > 0)
            {
                // if image is being used as texture, clear it
                if (meshData->image)
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, meshData->imageRef);    
                    meshData->image = NULL;
                }                
                else if (meshData->texture)
                {
                    [meshData->spriteName release];           
                    [meshData->texture release];
                }                
                meshData->spriteName = [[NSString alloc] initWithUTF8String:texStr];                
                meshData->texture = [[[SpriteManager sharedInstance] spriteTextureFromString:meshData->spriteName] retain];                                
                if (meshData->texture == nil)
                {
                    [meshData->spriteName release];
                    meshData->spriteName = nil;
                }
                
                meshData->valid = checkValid(meshData);                
                
                return 1;
            }            
        }
        else 
        {
            image_type* image = checkimage(L, 3);
            if (image != NULL) 
            {
                // if sprite is being used as texture, clear it
                if (meshData->texture)
                {
                    [meshData->spriteName release];
                    meshData->spriteName = nil;
                    [meshData->texture release];
                    meshData->texture = nil;
                }
                else if (meshData->image)
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, meshData->imageRef);
                }
                meshData->image = image;
                // copy value then add reference
                lua_pushvalue(L, 3);
                meshData->imageRef = luaL_ref(L, LUA_REGISTRYINDEX);        
                
                meshData->valid = checkValid(meshData);
                
                return 1;
            }
        }
    }
    else if (strcmp(c, "vertices") == 0 )
    {
        if (lua_isnil(L, 3))
        {
            // clear vertices
            clearBuffer(&meshData->vertices);
        }
        else
        {
            luaL_checktype(L, 3, LUA_TTABLE);
            
            int n = luaL_getn(L, 3);  /* get size of table */                    
            resizeBuffer(&meshData->vertices, n);
            
            const int elSize = meshData->vertices.elementSize;
            
            if(n >= 1)
            {  
                lua_rawgeti(L, 3, 1);
                if (isudatatype(L, -1, "vec3"))
                {
                    for (int i = 1; i <= n; i++)
                    {                        
                        lua_rawgeti(L, 3, i);                                                                                 
                        lua_Number* v = luaL_checkudata(L, -1, "vec3");                        
                        meshData->vertices.buffer[(i-1)*elSize+0] = v[0];
                        meshData->vertices.buffer[(i-1)*elSize+1] = v[1]; 
                        meshData->vertices.buffer[(i-1)*elSize+2] = v[2];                         
                        lua_pop(L, 1);                    
                    }        
                }
                else
                {
                    for (int i = 1; i <= n; i++)
                    {                        
                        lua_rawgeti(L, 3, i);                                                                                 
                        lua_Number* v = checkvec2(L, -1);
                        meshData->vertices.buffer[(i-1)*elSize+0] = v[0];
                        meshData->vertices.buffer[(i-1)*elSize+1] = v[1]; 
                        meshData->vertices.buffer[(i-1)*elSize+2] = 0;
                        lua_pop(L, 1);                    
                    }                            
                }                
            }            
        }
        
        meshData->valid = checkValid(meshData);

        return 1;        
    }
    else if (strcmp(c, "colors") == 0 )
    {
        if (lua_isnil(L, 3))
        {
            // clear colors
            clearBuffer(&meshData->colors);
        }
        else
        {
            luaL_checktype(L, 3, LUA_TTABLE);
            
            int n = luaL_getn(L, 3);  /* get size of table */
            
            if(n >= 1)
            {
                resizeBuffer(&meshData->colors, n);
                for (int i = 1; i <= n; i++)
                {
                    lua_rawgeti(L, 3, i);
                    color_type* c = checkcolor(L, -1);
                    meshData->colors.buffer[(i-1)*4] = c->r / 255.0f;
                    meshData->colors.buffer[(i-1)*4+1] = c->g / 255.0f;
                    meshData->colors.buffer[(i-1)*4+2] = c->b / 255.0f;
                    meshData->colors.buffer[(i-1)*4+3] = c->a / 255.0f;
                    lua_pop(L, 1);
                }                
            } 
        
        }
        
        meshData->valid = checkValid(meshData);
        
        return 1;        
    }
    else if (strcmp(c, "texCoords") == 0 )
    {
        if (lua_isnil(L, 3))
        {
            // clear colors
            clearBuffer(&meshData->texCoords);
        }
        else
        {
            luaL_checktype(L, 3, LUA_TTABLE);
            
            int n = luaL_getn(L, 3);  /* get size of table */
            resizeBuffer(&meshData->texCoords, n);
            
            if(n >= 1)
            {
                for (int i = 1; i <= n; i++)
                {
                    lua_rawgeti(L, 3, i);
                    lua_Number* v = checkvec2(L, -1);
                    meshData->texCoords.buffer[(i-1)*2] = v[0];
                    meshData->texCoords.buffer[(i-1)*2+1] = v[1];
                    lua_pop(L, 1);                    
                }        
            }            
        }
        
        meshData->valid = checkValid(meshData);
        
        return 1;        
    }

    
    return 0;
}

static int LsetColors(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    
    if (meshData)
    {
        int n = lua_gettop(L);
        
        GLfloat color[4] = {1,1,1,1};
        
        if (n == 2)
        {
            color_type* c = checkcolor(L, 2);                        
            if (c == NULL)
            {
                return 0;
            }
            color[0] = c->r / 255.0f;
            color[1] = c->g / 255.0f;
            color[2] = c->b / 255.0f;
            color[3] = c->a / 255.0f;        
        }
        else if (n >= 4)
        {
            color[0] = luaL_checknumber(L, 2) / 255.0f;
            color[1] = luaL_checknumber(L, 3) / 255.0f;
            color[2] = luaL_checknumber(L, 4) / 255.0f;
            if (n == 5)
            {
                color[3] = luaL_checknumber(L, 5) / 255.0f;            
            }        
        }
        else
        {
            return 0;
        }
        
        resizeBuffer(&meshData->colors, meshData->vertices.length);
        
        for (int i = 0; i < meshData->colors.length; i++)
        {
            meshData->colors.buffer[i*4] = color[0];
            meshData->colors.buffer[i*4+1] = color[1];
            meshData->colors.buffer[i*4+2] = color[2];
            meshData->colors.buffer[i*4+3] = color[3];        
        }
        
        meshData->valid = checkValid(meshData);        
    }
    
    return 0;
}

static int LaddQuad(lua_State *L)
{
    // IDEA: have an array which maps a quad_id to its location in the vertex array. this would allow arbitrary 
    // reordering, deletion, etc, without having to reassign id's. quad_id's would also be automatically reused
    
    mesh_type *meshData = checkMesh(L, 1);
        
    int n = lua_gettop(L);
    if (meshData && meshData->valid && n >= 5)
    {
        lua_Number x = luaL_checknumber(L, 2);
        lua_Number y = luaL_checknumber(L, 3);
        lua_Number w = luaL_checknumber(L, 4);
        lua_Number h = luaL_checknumber(L, 5);        
        
        lua_Number r = 0;
        if (n == 6)
        {
            r = luaL_checknumber(L, 6);
        }
        
        // original vertex count
        int nVerts = meshData->vertices.length;

        resizeBuffer(&meshData->colors, nVerts + 6);        
        
        if (meshData->texture || meshData->image)
        {            
            resizeBuffer(&meshData->texCoords, nVerts + 6);                
            meshData->texCoords.buffer[(nVerts)*2] = 0;
            meshData->texCoords.buffer[(nVerts)*2+1] = 1;
            
            meshData->texCoords.buffer[(nVerts+1)*2] = 0;
            meshData->texCoords.buffer[(nVerts+1)*2+1] = 0; 
            
            meshData->texCoords.buffer[(nVerts+2)*2] = 1;
            meshData->texCoords.buffer[(nVerts+2)*2+1] = 0; 
            
            meshData->texCoords.buffer[(nVerts+3)*2] = 0;
            meshData->texCoords.buffer[(nVerts+3)*2+1] = 1;
            
            meshData->texCoords.buffer[(nVerts+4)*2] = 1;
            meshData->texCoords.buffer[(nVerts+4)*2+1] = 0;
            
            meshData->texCoords.buffer[(nVerts+5)*2+0] = 1;
            meshData->texCoords.buffer[(nVerts+5)*2+1] = 1;                          
        }
        

        resizeBuffer(&meshData->vertices, nVerts + 6);

        const int elSize = meshData->vertices.elementSize;
        
        // Triangle 1
        // TL        
        meshData->vertices.buffer[(nVerts)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts)*elSize+1] = h/2;        
        meshData->vertices.buffer[(nVerts)*elSize+2] = 0;
        // BL
        meshData->vertices.buffer[(nVerts+1)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts+1)*elSize+1] = -h/2;        
        meshData->vertices.buffer[(nVerts+1)*elSize+2] = 0;                
        // BR
        meshData->vertices.buffer[(nVerts+2)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+2)*elSize+1] = -h/2;
        meshData->vertices.buffer[(nVerts+2)*elSize+2] = 0;        
        // Triangle 2
        // TL
        meshData->vertices.buffer[(nVerts+3)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts+3)*elSize+1] = h/2;        
        meshData->vertices.buffer[(nVerts+3)*elSize+2] = 0;
        // BR
        meshData->vertices.buffer[(nVerts+4)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+4)*elSize+1] = -h/2;        
        meshData->vertices.buffer[(nVerts+4)*elSize+2] = 0;
        // TR
        meshData->vertices.buffer[(nVerts+5)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+5)*elSize+1] = h/2;                            
        meshData->vertices.buffer[(nVerts+5)*elSize+2] = 0;        
        
        if (r != 0)
        {
            float cr = cosf(r);
            float sr = sinf(r);
        
            for (int i = nVerts; i < meshData->vertices.length; i++)    
            {
                float vx = meshData->vertices.buffer[i*elSize+0];
                float vy = meshData->vertices.buffer[i*elSize+1];
                meshData->vertices.buffer[i*elSize+0] = x + (vx * cr - vy * sr);
                meshData->vertices.buffer[i*elSize+1] = y + (vy * cr + vx * sr);
            }
        }
        else
        {
            for (int i = nVerts; i < meshData->vertices.length; i++)    
            {
                meshData->vertices.buffer[i*elSize+0] += x;
                meshData->vertices.buffer[i*elSize+1] += y;
            }            
        }
        
        for (int i = nVerts; i < meshData->colors.length; i++)
        {
            meshData->colors.buffer[i*4] = 1.0f;
            meshData->colors.buffer[i*4+1] = 1.0f;
            meshData->colors.buffer[i*4+2] = 1.0f;
            meshData->colors.buffer[i*4+3] = 1.0f;            
        }     
        
        // return quad index
        lua_pushinteger(L, (nVerts/6)+1);
        return 1;
    }
    
    return 0;
}

static int Lresize(lua_State *L)
{
    int n = lua_gettop(L);
    
    mesh_type *meshData = checkMesh(L, 1);    
    lua_Integer newSize = luaL_checkinteger(L, 2);
    
    if( n == 2 && meshData && newSize > 0 )
    {
        resizeBuffer(&meshData->vertices, newSize);
        resizeBuffer(&meshData->colors, newSize);        
        resizeBuffer(&meshData->texCoords, newSize);
    }
    
    return 0;
}

static int Lvertex(lua_State *L)
{
    int n = lua_gettop(L);    
    
    mesh_type *meshData = checkMesh(L, 1);    
    
    lua_Number x = 0;
    lua_Number y = 0;
    lua_Number z = 0;
    lua_Integer index = -1;
    
    if( meshData )
    {
        switch (n) 
        {
            case 5: /* vertex( i, x, y, z ) */
            {
                z = luaL_checknumber(L, 5);
            } //Flow onto next case
            case 4: /* vertex( i, x, y ) */
            {
                y = luaL_checknumber(L, 4);
                x = luaL_checknumber(L, 3);                
                
                index = luaL_checkinteger(L, 2) - 1;
            }   break;
                
            case 3: /* vertex( i, vec ) */
            {
                lua_Number *v = getvec3(L, 3);
                if( v != NULL )
                {
                    x = v[0];
                    y = v[1];
                    z = v[2];
                }
                else
                {
                    v = getvec2(L, 3);
                    if( v != NULL )
                    {
                        x = v[0];
                        y = v[1];
                        z = 0;                    
                    }
                }
                index = luaL_checkinteger(L, 2) - 1;                
            }   break;
                
            case 2: /* vertex( i ) */
            {
                index = luaL_checkinteger(L, 2) - 1;                
                
                float *vertex = getVertex(meshData, index);
                
                if( vertex )
                {
                    pushvec3(L, vertex[0], vertex[1], vertex[2]);
                    return 1;
                }
                else
                {
                    luaL_error(L, "index of mesh vertex out of bounds");                    
                }
                
                return 0;
            }   break;
            default:
                break;
        }
    }
    
    float *vertex = getVertex(meshData, index);
    
    if( vertex )
    {
        vertex[0] = x;
        vertex[1] = y;
        vertex[2] = z;
    }
    else 
    {
        luaL_error(L, "index of mesh vertex out of bounds");                    
    }
    
    return 0;
}

static int LtexCoord(lua_State *L)
{
    int n = lua_gettop(L);    
    
    mesh_type *meshData = checkMesh(L, 1);    
    
    lua_Number x = 0;
    lua_Number y = 0;
    lua_Integer index = -1;
    
    if( meshData )
    {
        switch (n) 
        {
            case 4: /* texCoord( i, x, y ) */
            {
                y = luaL_checknumber(L, 4);
                x = luaL_checknumber(L, 3);                
                
                index = luaL_checkinteger(L, 2) - 1;
            }   break;
                
            case 3: /* texCoord( i, vec ) */
            {
                lua_Number *v = checkvec2(L, 3);
                if( v != NULL )
                {
                    x = v[0];
                    y = v[1];
                }
                index = luaL_checkinteger(L, 2) - 1;                
            }   break;
                
            case 2: /* texCoord( i ) */
            {
                index = luaL_checkinteger(L, 2) - 1;                
                
                float *tex = getTexCoord(meshData, index);
                
                if( tex )
                {
                    pushvec2(L, tex[0], tex[1] );
                    return 1;
                }
                else
                {
                    luaL_error(L, "index of mesh texCoord out of bounds");                    
                }                
                
                return 0;
            }   break;
            default:
                break;
        }
    }
    
    float *tex = getTexCoord(meshData, index);
    
    if( tex )
    {
        tex[0] = x;
        tex[1] = y;
    }
    else
    {
        luaL_error(L, "index of mesh texCoord out of bounds");                    
    }    
    
    return 0;
}

static int Lcolor(lua_State *L)
{
    int n = lua_gettop(L);    
    
    mesh_type *meshData = checkMesh(L, 1);    
    
    lua_Number r = 0;
    lua_Number g = 0;
    lua_Number b = 0;
    lua_Number a = 255;    
    lua_Integer index = -1;
    
    if( meshData )
    {
        switch (n) 
        {
            case 6: /* color( i, r, g, b, a ) */
            {
                a = luaL_checknumber(L, 6);
            } //Flow onto next case
            case 5: /* color( i, r, g, b ) */
            {
                b = luaL_checknumber(L, 5);
            } //Flow onto next case
            case 4: /* color( i, r, g ) */
            {
                g = luaL_checknumber(L, 4);
                r = luaL_checknumber(L, 3);                
                
                index = luaL_checkinteger(L, 2) - 1;
            }   break;
                
            case 3: /* color( i, color ) */
            {
                color_type *c = checkcolor(L, 3);
                if( c != NULL )
                {
                    r = c->r;
                    g = c->g;
                    b = c->b;
                    a = c->a;
                }
                index = luaL_checkinteger(L, 2) - 1;                
            }   break;
                
            case 2: /* color( i ) */
            {
                index = luaL_checkinteger(L, 2) - 1;                
                
                float *color = getColor(meshData, index);
                
                if( color )
                {
                    pushcolor(L, color[0] * 255, color[1] * 255, color[2] * 255, color[3] * 255);
                    return 1;
                }
                else
                {
                    luaL_error(L, "index of mesh color out of bounds");                    
                }                
                
                return 0;
            }   break;
            default:
                break;
        }
    }
    
    float *color = getColor(meshData, index);
    
    if( color )
    {
        color[0] = r/255.0f;
        color[1] = g/255.0f;
        color[2] = b/255.0f;
        color[3] = a/255.0f;        
    }
    else
    {
        luaL_error(L, "index of mesh color out of bounds");                    
    }    
    
    return 0;
}

static int Lclear(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    if (meshData)
    {
        clearBuffer(&meshData->vertices);    
        clearBuffer(&meshData->colors);
        clearBuffer(&meshData->texCoords);
        meshData->valid = checkValid(meshData);
    }
    return 0;
}

static int Ldraw(lua_State *L)
{
    return drawMesh(L);
}

static int LsetQuadTex(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    
    int n = lua_gettop(L);
    if (meshData && meshData->valid && (meshData->vertices.length % 6 == 0) && n >= 6)
    {
        lua_Integer index = luaL_checkinteger(L, 2)-1;
        lua_Number s = luaL_checknumber(L, 3);
        lua_Number t = luaL_checknumber(L, 4); //Don't invert t 
        lua_Number w = luaL_checknumber(L, 5);
        lua_Number h = luaL_checknumber(L, 6);        
        
        // original vertex count
        int nVerts = index * 6;
        
        // Check if index is in bounds
        if (nVerts > meshData->vertices.length-1 || nVerts < 0)
        {
            return 0;
        }
                
        if (meshData->texture || meshData->image)
        {            
            // TL
            meshData->texCoords.buffer[(nVerts)*2] = s;
            meshData->texCoords.buffer[(nVerts)*2+1] = t+h; 
            
            // BL
            meshData->texCoords.buffer[(nVerts+1)*2] = s; 
            meshData->texCoords.buffer[(nVerts+1)*2+1] = t;  
            
            // BR
            meshData->texCoords.buffer[(nVerts+2)*2] = s+w;
            meshData->texCoords.buffer[(nVerts+2)*2+1] = t; 
            
            // TL
            meshData->texCoords.buffer[(nVerts+3)*2] = s;
            meshData->texCoords.buffer[(nVerts+3)*2+1] = t+h;
            
            // BR
            meshData->texCoords.buffer[(nVerts+4)*2] = s+w;
            meshData->texCoords.buffer[(nVerts+4)*2+1] = t;
            
            // TR
            meshData->texCoords.buffer[(nVerts+5)*2+0] = s+w;
            meshData->texCoords.buffer[(nVerts+5)*2+1] = t+h;                          
        }

    }    
    
    return 0;
}

static int LsetQuadColor(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    
    int n = lua_gettop(L);
    if (meshData && meshData->valid && (meshData->vertices.length % 6 == 0) && n >= 3)
    {
        lua_Integer index = luaL_checkinteger(L, 2)-1;        
        
        GLfloat color[4] = {1,1,1,1};
        
        if (n == 3)
        {
            color_type* c = checkcolor(L, 3);                        
            if (c == NULL)
            {
                return 0;
            }
            color[0] = c->r / 255.0f;
            color[1] = c->g / 255.0f;
            color[2] = c->b / 255.0f;
            color[3] = c->a / 255.0f;        
        }
        else if (n >= 5)
        {
            color[0] = luaL_checknumber(L, 3) / 255.0f;
            color[1] = luaL_checknumber(L, 4) / 255.0f;
            color[2] = luaL_checknumber(L, 5) / 255.0f;
            if (n == 6)
            {
                color[3] = luaL_checknumber(L, 6) / 255.0f;            
            }        
        }        
        
        // original vertex count
        int nVerts = index * 6;
        
        // Check if index is in bounds
        if (nVerts > meshData->vertices.length-1 || nVerts < 0)
        {
            return 0;
        }        
        
        for (int i = nVerts, j = nVerts*4; i < nVerts+6; i++)
        {
            meshData->colors.buffer[j++] = color[0];
            meshData->colors.buffer[j++] = color[1];
            meshData->colors.buffer[j++] = color[2];
            meshData->colors.buffer[j++] = color[3];       
        }             
    }
    
    return 0;
}

static int LsetQuad(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    
    int n = lua_gettop(L);
    if (meshData && meshData->valid && (meshData->vertices.length % 6 == 0) && n >= 6)
    {
        lua_Integer index = luaL_checkinteger(L, 2)-1;
        lua_Number x = luaL_checknumber(L, 3);
        lua_Number y = luaL_checknumber(L, 4);
        lua_Number w = luaL_checknumber(L, 5);
        lua_Number h = luaL_checknumber(L, 6);        
        
        lua_Number r = 0;
        if (n == 7)
        {
            r = luaL_checknumber(L, 7);
        }
        
        // original vertex count
        int nVerts = index * 6;
        
        // Check if index is in bounds
        if (nVerts > meshData->vertices.length-1 || nVerts < 0)
        {
            return 0;
        }
        
        const int elSize = meshData->vertices.elementSize;
                        
        // Triangle 1
        // TL        
        meshData->vertices.buffer[(nVerts)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts)*elSize+1] = h/2;  
        meshData->vertices.buffer[(nVerts)*elSize+2] = 0;          
        // BL
        meshData->vertices.buffer[(nVerts+1)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts+1)*elSize+1] = -h/2;        
        meshData->vertices.buffer[(nVerts+1)*elSize+2] = 0;        
        // BR
        meshData->vertices.buffer[(nVerts+2)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+2)*elSize+1] = -h/2;        
        meshData->vertices.buffer[(nVerts+2)*elSize+2] = 0;        
        // Triangle 2
        // TL
        meshData->vertices.buffer[(nVerts+3)*elSize+0] = -w/2;
        meshData->vertices.buffer[(nVerts+3)*elSize+1] = h/2;      
        meshData->vertices.buffer[(nVerts+3)*elSize+2] = 0;        
        // BR
        meshData->vertices.buffer[(nVerts+4)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+4)*elSize+1] = -h/2;        
        meshData->vertices.buffer[(nVerts+4)*elSize+2] = 0;
        // TR
        meshData->vertices.buffer[(nVerts+5)*elSize+0] = w/2;
        meshData->vertices.buffer[(nVerts+5)*elSize+1] = h/2;                            
        meshData->vertices.buffer[(nVerts+5)*elSize+2] = 0;        
        
        if (r != 0)
        {
            float cr = cosf(r);
            float sr = sinf(r);
            
            for (int i = nVerts; i < nVerts+6/*meshData->vertices.length*/; i++)    
            {
                float vx = meshData->vertices.buffer[i*elSize+0];
                float vy = meshData->vertices.buffer[i*elSize+1];
                meshData->vertices.buffer[i*elSize+0] = x + (vx * cr - vy * sr);
                meshData->vertices.buffer[i*elSize+1] = y + (vy * cr + vx * sr);
            }
        }
        else
        {
            for (int i = nVerts; i < nVerts+6/*meshData->vertices.length*/; i++)    
            {
                meshData->vertices.buffer[i*elSize+0] += x;
                meshData->vertices.buffer[i*elSize+1] += y;
            }            
        }        
    }
    
    return 0;
}


static int Lgc(lua_State *L)
{
    mesh_type *meshData = checkMesh(L, 1);
    freeBuffer(&meshData->vertices);
    freeBuffer(&meshData->colors);
    freeBuffer(&meshData->texCoords);    
    
    if (meshData->spriteName)
    {
        [meshData->spriteName release];
    }
    
    // unref image if it has a reference
    if (meshData->image)
    {
        luaL_unref(L, LUA_REGISTRYINDEX, meshData->imageRef);
    }
    
    return 1;
}

static int Ltostring(lua_State *L)
{
    mesh_type *meshData = Pget(L,1);
    char s[128];
    sprintf(s,"mesh: %p", meshData);
    lua_pushstring(L,s);
    return 1;
}

static const luaL_reg R[] =
{
	{ "__index",	  Lget		    },
	{ "__newindex",	  Lset		    },
    { "__gc",         Lgc           },
	{ "__tostring",	  Ltostring	    },
    { "setColors",    LsetColors    },
    { "addRect",      LaddQuad      },
    { "setRect",      LsetQuad      },    
    { "setRectColor", LsetQuadColor },        
    { "setRectTex",   LsetQuadTex   },            
    { "clear",        Lclear        },          
    { "draw",         Ldraw         },              
    { "vertex",       Lvertex       },              
    { "color",        Lcolor        },              
    { "texCoord",     LtexCoord     },                  
    { "resize",       Lresize       },                      
	{ NULL,		      NULL          }
};

LUALIB_API int luaopen_mesh(lua_State *L)
{
    luaL_newmetatable(L, MESH_TYPE);
    luaL_openlib(L,NULL,R,0);
    lua_register(L,"mesh",Lnew);
    return 1;
}
