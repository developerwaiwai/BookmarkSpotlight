//
//  main.m
//  BookmarkWriter
//
//  Created by Kiyohiko Iwai on 2013/11/11.
//  Copyright (c) 2013年 Kiyohiko Iwai. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* const cBookmarkFileFormat = @"%@/Library/Application Support/Google/Chrome/Default/Bookmarks";
NSString* const cDestinationFolderFormat = @"%@/Webloc/";
NSString* const cDestinationFileFormat = @"%@/Webloc/%@-%lu.webloc";
NSString* const cTemplateFileFormat = @"%@/template.webloc";

NSString* const cDictionaryRootKey = @"roots";
NSString* const cBookmarkRootKey = @"bookmark_bar";

NSString* const cChildrenKey = @"children";
NSString* const cURLKey = @"url";
NSString* const cNameKey = @"name";

unsigned long counter = 0;

void convertBookmarkToWebloc(NSDictionary* dic);

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        //first counter reset
        //This counter is part of filename because bookmark name(filename) avoid duplication.
        counter = 0;
        
        //Read Bookmark file(This file may be formated json. )
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* bookmarkFile = [NSString stringWithFormat:cBookmarkFileFormat, NSHomeDirectory()];
        NSData *data = [NSData dataWithContentsOfFile:bookmarkFile];
        
        //Convert JSON to NSDictonary
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        //Make Target folder path(~/Documents/Webloc/)
        NSString *dir = [NSString stringWithFormat:cDestinationFolderFormat,[paths objectAtIndex:0]];
        NSFileManager* fm = [NSFileManager defaultManager];
        
        //Delete folder, if Webloc folder is exist
        BOOL exist = [fm fileExistsAtPath:dir isDirectory:nil];
        if (exist == YES) {
            [fm removeItemAtPath:dir error:nil];
        }
        
        //Make Target folder(~/Documents/Webloc/)
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
        
        //Get bookmark Dictonary
        id bookmark = [[json objectForKey:cDictionaryRootKey] objectForKey:cBookmarkRootKey];
        
        //Convert bookmark dictionary to webloc file
        convertBookmarkToWebloc(bookmark);
        
    }
    return 0;
}

void convertBookmarkToWebloc(NSDictionary* dic) {
    
    //Get Child Array
    NSArray* children = [dic objectForKey:cChildrenKey];
    
    //Child Enumration(Recursive Call)
    for (NSDictionary* child in children) {
        convertBookmarkToWebloc(child);
    }
    
    //Write to file this item.
    if ([dic objectForKey:cURLKey] != nil && [dic objectForKey:cNameKey] != nil) {
        
        //counter increment
        counter++;
        
        //Create output file name(path).
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        //Illegal caracter replace.
        //"/" to " "(space) and ":" to " "(space)
        NSString* bookmarkName_replaced = [[dic objectForKey:cNameKey] stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        bookmarkName_replaced = [bookmarkName_replaced stringByReplacingOccurrencesOfString:@":" withString:@" "];
        
        NSString* fileName =[NSString stringWithFormat:cDestinationFileFormat, [paths objectAtIndex:0], bookmarkName_replaced, counter];
        
        //Webloc template file read.
        NSString* fileContentsTemplate = [NSString stringWithContentsOfFile:[NSString stringWithFormat:cTemplateFileFormat, [paths objectAtIndex:0]]];
        
        //Make file content from template.
        NSString* fileContents = [NSString stringWithFormat:fileContentsTemplate, [dic objectForKey:cURLKey]];
        
        //Write to file.
        [fileContents writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}
