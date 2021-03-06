//
//  DVCardManager.m
//  SaveIt
//
//  Created by Bharath Booshan on 5/21/12.
//  Copyright (c) 2012 Integral Development Corporation. All rights reserved.
//

#import "DVCardManager.h"
#import "DVHelper.h"
#import "DVCard.h"
#import "DVCategory.h"

NSString * DVCardsUpdateNotificationEvent = @"cards_update";




@implementation DVCardManager
@synthesize parentCategory = _parentCategory;

//-----------------Init
-(id)init
{
    self = [super init];
    if( self )
    {
        mObjects = [[NSMutableArray alloc] init];
    }
    return self;
}

//-----------------------methods
-(void)registerForUpdates:(SEL)selector target:(id)observer
{
    @try
    {
        [self unregisterFromUpdates:observer];
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:DVCardsUpdateNotificationEvent object:self];
    }
    @catch(NSException *e)
    {
        
    }
}

-(void)unregisterFromUpdates:(id)target
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:target name:DVCardsUpdateNotificationEvent object:self];
    }
    @catch (NSException *exception) {
        
    }
}

-(NSUInteger)totalCards
{
    return [mObjects count];
}


-(DVCard *)cardAtIndex:(NSUInteger)index
{
    DVCard *category = nil;
    if (index < [mObjects count] )
    {
        category = [mObjects objectAtIndex:index];
    }
    return  category;
}

-(void)loadCards:(void (^)(BOOL finished))completed
{
    FMDatabaseQueue *dbQueue = [DVHelper databaseQueue];
    [dbQueue inTransaction:^(FMDatabase *db, BOOL *reverse){
        
        FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM CARD WHERE %@ = %u",CARD_CATEGORY_ID, _parentCategory.categoryID ]];
        NSMutableArray *cardsArray = [[NSMutableArray alloc] init];
        
        while ([result next]) {
            DVCard *card = [[DVCard alloc]init];
            card.cardID = [result unsignedLongLongIntForColumn:CARD_ID];
            card.title = [result stringForColumn:CARD_TITLE];
            card.iconName = [result stringForColumn:CARD_ICON_NAME];
            NSString *fieldNames = [result stringForColumn:CARD_FIELD_NAME];
            NSString *fieldValues = [result stringForColumn:CARD_FIELD_VALUES];
            NSString *scramble = [result stringForColumn:CARD_FIELD_SCRAMBLE];
            [card setFieldNames:fieldNames scramble:scramble fieldValues:fieldValues];
            card.isFavorite = [result boolForColumn:CARD_IS_FAVORITE];
            card.lastModifiedInterval = [result doubleForColumn:CARD_LAST_MODIFIED];
            
            
             NSUInteger categoryID = [result unsignedLongLongIntForColumn:CARD_CATEGORY_ID];
             FMResultSet *categorySearchResult = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM CATEGORY WHERE %@ = %u", CATEGORY_ID , categoryID]];

             if( [categorySearchResult next] )
             {
                 DVCategory *category = [DVCategory newCategoryWithID:categoryID];
                 
                 category.categoryID = [result unsignedLongLongIntForColumn:CATEGORY_ID];
                 category.categoryName = [result stringForColumn:CATEGORY_NAME];
                 category.iconName = [result stringForColumn:CATEGORY_FIELD_ICON_NAME];
                 card.category = category;
             }
                    
            [cardsArray addObject:card];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [mObjects removeAllObjects];
            [mObjects addObjectsFromArray:cardsArray];
            [[NSNotificationCenter defaultCenter ] postNotificationName:DVCardsUpdateNotificationEvent object:self];
            completed(YES);
        });
    }];
}


@end
