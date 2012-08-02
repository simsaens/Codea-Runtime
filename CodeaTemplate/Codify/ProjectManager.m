//
//  ProjectManager.m
//  Codea
//
//  Created by Simeon Nasilowski on 17/09/11.
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

#import "ProjectManager.h"

#import "Persistence.h"

@implementation ProjectManager

SYNTHESIZE_SINGLETON_FOR_CLASS(ProjectManager);

- (NSArray*) loadProjectsInList:(NSArray*)list inPath:(NSString*)path userProjects:(BOOL)user
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray *projects = [NSMutableArray arrayWithCapacity:[contents count]];
    
    for( NSString *projectStr in list )
    {
        NSString *projFile = [projectStr stringByAppendingPathExtension:@"codea"];
        
        if( [contents containsObject:projFile] )
        {
            //Add the project
            NSString *projectPath = [path stringByAppendingPathComponent:projFile];
            Project *project = [Project bundleWithPath:projectPath validFileTypes:[NSArray arrayWithObjects:@"lua", @"plist", nil]];
            project.userProject = user;
            [projects addObject:project];    
        }
    }
    
    /*
    for( NSString *folder in contents )
    {
        //Validate that folder is in list
        BOOL isInList = NO;
        for( NSString *validFile in list )
        {
            if( [[folder stringByDeletingPathExtension] isEqualToString:validFile] )
            {
                isInList = YES;
            }
        }
        
        if( isInList )
        {
            //DBLog(@"Processing %@ in path: %@", folder, path);
            
            if( [[folder pathExtension] isEqualToString:@"codea"] || [[folder pathExtension] isEqualToString:@"codify"] )
            {        
                NSString *projectPath = [path stringByAppendingPathComponent:folder];
                Project *project = [Project bundleWithPath:projectPath validFileTypes:[NSArray arrayWithObjects:@"lua", @"plist", nil]];
                project.userProject = user;
                [projects addObject:project];
            }
        }
    }
    */
    
    return projects;    
}

- (NSArray*) loadProjectsInPath:(NSString*)path userProjects:(BOOL)user
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray *projects = [NSMutableArray arrayWithCapacity:[contents count]];
    
    for( NSString *folder in contents )
    {
        //DBLog(@"Processing %@ in path: %@", folder, path);
        
        if( [[folder pathExtension] isEqualToString:@"codea"] || [[folder pathExtension] isEqualToString:@"codify"] )
        {        
            NSString *projectPath = [path stringByAppendingPathComponent:folder];
            Project *project = [Project bundleWithPath:projectPath validFileTypes:[NSArray arrayWithObjects:@"lua", @"plist", nil]];
            project.userProject = user;
            [projects addObject:project];
        }
    }
    
    return projects;
}

- (NSString*) documentsFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];        
}

- (id)init
{
    self = [super init];
    if (self) 
    {
        //Load template and example projects
        NSString *templatesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Templates"];
                
        //Templates
        templateProjectsCache = [[self loadProjectsInPath:templatesPath userProjects:NO] retain];
        
        //Examples
#ifdef CODEA_PLAY
        NSString *examplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Play"];        
        
        NSArray *validExamples = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PlayProjects" ofType:@"plist"]] objectForKey:@"Examples"];
        exampleProjectsCache = [[self loadProjectsInList:validExamples inPath:examplesPath userProjects:NO] retain];        
#else
        NSString *examplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Examples"];        
        
        NSArray *validExamples = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ExampleProjects" ofType:@"plist"]] objectForKey:@"Examples"];
        exampleProjectsCache = [[self loadProjectsInList:validExamples inPath:examplesPath userProjects:NO] retain];
#endif        
    }
    
    return self;
}

- (void) dealloc
{
    [templateProjectsCache release];
    [exampleProjectsCache release];
    [userProjectsCache release];
    
    [super dealloc];
}

#pragma mark - Properties

- (NSArray*) templateProjects
{
    return templateProjectsCache;
}

- (NSArray*) exampleProjects
{
    return exampleProjectsCache;
}

- (NSArray*) userProjects
{
    if( userProjectsCache == nil )
    {
        userProjectsCache = [[self loadProjectsInPath:[self documentsFolder] userProjects:YES] retain];
    }
    return userProjectsCache;
}

#pragma mark - User project methods

- (void) reloadUserProjects
{
    [userProjectsCache release];
    userProjectsCache = nil;
}

- (NSString*) projectBundleForName:(NSString*)projectName
{
    return [[self documentsFolder] stringByAppendingPathComponent:[projectName stringByAppendingPathExtension:@"codea"]];    
}

- (NSString*) oldProjectBundleForName:(NSString*)projectName
{
    return [[self documentsFolder] stringByAppendingPathComponent:[projectName stringByAppendingPathExtension:@"codify"]];    
}

- (BOOL) createBundleForProject:(NSString*)projectName
{
    NSString *projectBundle = [self projectBundleForName:projectName];
    
    //Ensure there is a bundle for the project
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:projectBundle isDirectory:&isDir];
    
    if( exists && !isDir )
    {
        DBLog(@"ERROR: File exists at project bundle location, %@", projectBundle);
        return NO;
    }
    else if( !exists )
    {
        //Create the directory for the project
        BOOL didCreateBundle = [[NSFileManager defaultManager] createDirectoryAtPath:projectBundle withIntermediateDirectories:NO attributes:nil error:NULL];
        
        if( !didCreateBundle )
        {
            DBLog(@"ERROR: Unable to create project bundle at path: %@", projectBundle);
            return NO;
        }        
    }    
    
    return YES;
}

- (BOOL) doesUserProjectExist:(NSString*)projectName
{
    NSArray *projects = self.userProjects;
    
    for( Project *p in projects )
    {
        if( [[p.name lowercaseString] isEqualToString:[projectName lowercaseString]] )
        {
            return YES;
        }
    }
    
    return NO;
}

- (Project*) userProjectNamed:(NSString *)projectName
{
    NSArray *projects = self.userProjects;
    
    for( Project *p in projects )
    {
        if( [p.name isEqualToString:projectName] )
        {
            return p;
        }
    }
    
    return nil;
}

- (Project*) createProject:(NSString*)name withTemplate:(Project*)template
{
    NSString *projectBundle = [self projectBundleForName:name];    
    
    if( ![self createBundleForProject:name] )
    {
        return nil;
    }
    
    for( NSString *file in template.files )
    {
        //Copy each template file to the project bundle
        NSString *projectFilePath = [projectBundle stringByAppendingPathComponent:[file lastPathComponent]];        
        if( ![[NSFileManager defaultManager] copyItemAtPath:file toPath:projectFilePath error:NULL] )
        {
            DBLog(@"ERROR Create project with template failed to copy template file %@ to project file %@", file, projectFilePath);
            return nil;
        }
        else
        {
            //Apply replacements to each Lua file
            if( [[[projectFilePath pathExtension] lowercaseString] isEqualToString:@"lua"] )
            {
                NSString *contents = [NSString stringWithContentsOfFile:projectFilePath usedEncoding:NULL error:NULL];
                
                contents = [contents stringByReplacingOccurrencesOfString:@"__ProjectName__" withString:name];
                
                [contents writeToFile:projectFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
            }
        }
    }
    
    Project *project = [Project bundleWithPath:projectBundle validFileTypes:[NSArray arrayWithObjects:@"lua", @"plist", nil]];
    project.userProject = YES;
    return project;
}

- (BOOL) saveUserProject:(Project*)project
{
    if( project.userProject )
    {
        //Project path
        NSString *projectBundle = [self projectBundleForName:project.name];
            
        //Ensure there is a bundle for the project
        [self createBundleForProject:project.name];
        
        //Write the project out, overwriting any existing files
        return [project writeToBundlePath:projectBundle];    
    }
    
    return NO;
}

- (BOOL) deleteUserProject:(Project*)project
{
    if( project.userProject )
    {
        NSString *projectBundle = [self projectBundleForName:project.name];
        
        BOOL didDelete = [[NSFileManager defaultManager] removeItemAtPath:projectBundle error:NULL];

        if (didDelete)
        {
            removeLocalDataForPrefix(project.name);
        }

        [self reloadUserProjects];
        
        
        return didDelete;
    }
    return NO;
}

- (void) convertUsersCodifyProjectsToCodea
{
    NSArray *projects = self.userProjects;
    
    for( Project *p in projects )
    {
        NSString *oldProjectBundle = [self oldProjectBundleForName:p.name];
        NSString *newProjectBundle = [self projectBundleForName:p.name];
        
        BOOL isDir = NO;
        
        if( [[NSFileManager defaultManager] fileExistsAtPath:oldProjectBundle isDirectory:&isDir] )
        {
            if( isDir )
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:oldProjectBundle toPath:newProjectBundle error:&error];            
                
                if( error )
                {
                    NSLog(@"Error moving old project to new location: %@", error);
                }
            }
        }
    }
    
    //Makes sure all project icons point to the right ones!
    [self reloadUserProjects];
}

@end
