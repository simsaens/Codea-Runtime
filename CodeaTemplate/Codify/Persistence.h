//
//  Persistence.h
//  Codea
//
//  Created by Dylan Sale on 5/11/11.
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

#ifndef Codify_persistence_h
#define Codify_persistence_h

#include "lua.h"

#define PROJECT_DATA_FILE @"Data.plist"
#define PROJECT_INFO_FILE @"Info.plist"

#ifdef __cplusplus
extern "C" {
#endif 

    int saveLocalData(lua_State *L);
    int readLocalData(lua_State *L);
    int clearLocalData(lua_State *L);
    
    int saveProjectData(lua_State *L);
    int readProjectData(lua_State *L);
    int clearProjectData(lua_State *L);
    
    int saveGlobalData(lua_State *L);
    int readGlobalData(lua_State *L);
    
    int saveProjectInfo(lua_State *L);
    int readProjectInfo(lua_State *L);    
    
//    int saveDocumentsImage(lua_State *L);
//    int saveProjectImage(lua_State *L);
//    int readDocumentsImage(lua_State *L);
//    int readProjectImage(lua_State *L);
//    int readDocumentsImages(lua_State *L);    
//    int readProjectImages(lua_State *L);
    int saveImage(lua_State *L);
    int readImage(lua_State *L);
    int spriteList(lua_State *L);
    
    void removeLocalDataForPrefix(NSString* name);
    void setLocalDataPrefix(NSString* name);
    void setProjectDataPath(NSString* path);
    void setProjectInfoStore(NSMutableDictionary* info);    

    NSString* getDocumentsImagesPath();
    NSString* getProjectImagesPath();    
    void setupGlobalData();
    
    
#ifdef __cplusplus
}
#endif 



#endif
