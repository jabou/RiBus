//
//  DBManager.m
//  Pharmacy
//
//  Created by Jasmin Abou Aldan on 02/10/15.
//  Copyright © 2015 Jasmin Abou Aldan. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>

@interface DBManager ()

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSMutableArray *arrResults;

-(void)copyDatabaseIntoDocumentsDirectory;
-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable;

@end

@implementation DBManager

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename{
    
    self = [super init];
    
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        
        self.databaseFilename = dbFilename;
        
        [self copyDatabaseIntoDocumentsDirectory];
    }
    
    return self;
}

-(void)copyDatabaseIntoDocumentsDirectory{
    
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent: self.databaseFilename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath: sourcePath toPath: destinationPath error: &error];
        
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable{
    
    sqlite3 *sqlite3Database;
    
    NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent: self.databaseFilename];
    
    //Initialize the results and column names array
    if (self.arrResults != nil) {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];
    
    if (self.arrColumnNames != nil) {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    
    //Open the database
    BOOL openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
    
    if (openDatabaseResult == SQLITE_OK) {
        
        // Declare a sqlite3_stmt object in which will be stored the query
        sqlite3_stmt *compiledStatement;
        
        BOOL prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
        
        if (prepareStatementResult == SQLITE_OK) {
            
            if (!queryExecutable) {
                
                //Load data from database
                
                NSMutableArray *arrDataRow;
                
                //Loop throught the results and add them to the results array row by row
                while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
                    
                    arrDataRow = [[NSMutableArray alloc] init];
                    
                    int totalColums = sqlite3_column_count(compiledStatement);
                    
                    // Go through all columns and fetch each column data
                    for (int i = 0; i<totalColums; i++) {
                        
                        char *dbDataAsChar = (char *)sqlite3_column_text(compiledStatement, i);
                        
                        // If there are contents in the currenct column then add them to the current row array
                        if (dbDataAsChar != NULL) {
                            [arrDataRow addObject:[NSString stringWithUTF8String: dbDataAsChar]];
                        }
                        
                        // Keep the current column name
                        if (self.arrColumnNames.count != totalColums) {
                            dbDataAsChar = (char *)sqlite3_column_text(compiledStatement, i);
                            [self.arrColumnNames addObject:[NSString stringWithUTF8String: dbDataAsChar]];
                        }
                    }
                    //Store each fetched data row in the result array, but first check if there is actually data
                    if (arrDataRow.count > 0) {
                        [self.arrResults addObject: arrDataRow];
                    }
                }
                
            } else {
                
                //executable query (insert, update, delete).
                
                if (sqlite3_step(compiledStatement)) {
                    
                    //Keep the affected row
                    self.affectedRows = sqlite3_changes(sqlite3Database);
                    
                    //Keep last inserted row ID
                    self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
                    
                } else {
                    NSLog(@"DB Error: %s", sqlite3_errmsg(sqlite3Database));
                }
            }
            
        } else {
            NSLog(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        
        // Release the compiled statement from memory
        sqlite3_finalize(compiledStatement);
    }
    
    //Close the database
    sqlite3_close(sqlite3Database);
}

-(NSArray *)loadDataFromDB:(NSString *)query{
    
    [self runQuery:[query UTF8String] isQueryExecutable:NO];
    
    return (NSArray *)self.arrResults;
}

-(void)executeQuery:(NSString *)query{
    [self runQuery:[query UTF8String] isQueryExecutable:YES];
}

@end