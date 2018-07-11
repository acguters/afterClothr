//
//  helperfunctions.m
//  clothr
//
//  Created by Andrew Guterres on 10/29/17.
//  Copyright © 2017 cmps115. All rights reserved.
//

#import "helperfunctions.h"

#pragma mark - Getting products

@interface helperfunctions()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *salePriceLabel;
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSMutableArray *brands;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSMutableArray *sizes;
@property (nonatomic, strong) NSMutableArray *retailers;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSMutableArray *buffer;
@property (nonatomic, strong) NSMutableArray *savedProducts;
@property (nonatomic, strong) PSSProduct *product;
@end

typedef void(^myCompletion)(BOOL);
//BOOL check = false;

@implementation helperfunctions

@synthesize products = _products;
@synthesize savedProducts = _savedProducts;
//@synthesize buffer = _buffer;
// Given `notes` contains an array of Note objects
//NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notes];
//[[NSUserDefaults standardUserDefaults] setObject:data forKey:@"notes"];
//NSData *notesData = [[NSUserDefaults standardUserDefaults] objectForKey:@"notes"];
//NSArray *notes = [NSKeyedUnarchiver unarchiveObjectWithData:notesData];



- (void)fillProductBuffer:(NSString *)search :(NSNumber *)pagingIndex
{
    __block NSArray *buffer;
    [self searchQuery:search :pagingIndex :^(BOOL finished)
     {
         if(finished){
             //            while(!check){}
             printf("FINISHED");
             NSData *productData = [[NSUserDefaults standardUserDefaults] objectForKey:@"name"];
             buffer = [NSKeyedUnarchiver unarchiveObjectWithData:productData];
             PSSProduct *thisProduct = buffer[(NSUInteger)0];
             printf("Unarchived name: %s\n", [thisProduct.name UTF8String]);
             //return buffer;
             //filledBuffer=buffer;
         }
     }];
    
    //NSData *productData = [[NSUserDefaults standardUserDefaults] objectForKey:@"name"];
    //NSArray *buffer = [NSKeyedUnarchiver unarchiveObjectWithData:productData];
    //    return buffer;
    
    //    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    //    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:myObject] forKey:@"MyObjectKey"];
    //    [defaults synchronize];
}

-(void) searchQuery:(NSString *)searchTerm :(NSNumber*)pagingIndex :(myCompletion) compblock{
    PSSProductQuery *productQuery = [[PSSProductQuery alloc] init];
    productQuery.searchTerm = searchTerm;
    
    NSData *filterData = [[NSUserDefaults standardUserDefaults] objectForKey:@"pickedRetailerFilters"];
    NSArray *retailers = [NSKeyedUnarchiver unarchiveObjectWithData:filterData];
    [productQuery addProductFilters:retailers];
//    printf("%lu", (unsigned long)filters.count);
    filterData = [[NSUserDefaults standardUserDefaults] objectForKey:@"pickedBrandFilters"];
    NSArray *brand = [NSKeyedUnarchiver unarchiveObjectWithData:filterData];
//    printf("%lu", (unsigned long)filters.count);
    [productQuery addProductFilters:brand];
    filterData = [[NSUserDefaults standardUserDefaults] objectForKey:@"pickedPriceFilters"];
    NSArray *sizes = [NSKeyedUnarchiver unarchiveObjectWithData:filterData];
//    printf("%lu", (unsigned long)filters.count);
    [productQuery addProductFilters:sizes];
    filterData = [[NSUserDefaults standardUserDefaults] objectForKey:@"pickedColorFilters"];
    NSArray *colors = [NSKeyedUnarchiver unarchiveObjectWithData:filterData];
//    printf("%lu", (unsigned long)filters.count);
    [productQuery addProductFilters:colors];
    printf("%lu", (unsigned long)[productQuery productFilters].count);
    
    printf("here: %s\n", [productQuery.searchTerm UTF8String]);
    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] searchProductsWithQuery:productQuery offset:pagingIndex limit:[NSNumber numberWithInt:10] success:^(NSUInteger totalCount, NSArray *availableHistogramTypes, NSArray *products) {
        printf("ARCHIVING...\n");
        weakSelf.products = products;
        PSSProduct *thisProduct = self.products[(NSUInteger)0];
        printf("Archive name: %s\n", [thisProduct.name UTF8String]);
        printf("Archive count: %lu\n", (unsigned long)totalCount);\
        if (totalCount<5)        //if there are no items returned from the api
        {
            NSArray *noItems = @[@"noItems"];
            NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
            [data setObject:[NSKeyedArchiver archivedDataWithRootObject:noItems] forKey:@"name"];
            [data synchronize];
        }  else
        {
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:products] forKey:@"name"];
        [data synchronize];
        NSData *productData = [[NSUserDefaults standardUserDefaults] objectForKey:@"name"];
        NSArray *buffer = [NSKeyedUnarchiver unarchiveObjectWithData:productData];
        PSSProduct *thisProduct2 = buffer[(NSUInteger)0];
        printf("Unarchived name2: %s\n", [thisProduct2.name UTF8String]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
    compblock(NO);
    return;
}
-(void)fillSavedProducts:(NSArray *)savedArray
{
    self.savedProducts=[[NSMutableArray alloc] init];
    void(^myBlock)(void)  = ^(void) {
        for(int i=0;i<savedArray.count;i++)
        {
            printf("i: %d ", i);
            printf("idNumber: %d\n", [savedArray[i] intValue]);
            [[PSSClient sharedClient] getProductByID:savedArray[i] success:^(PSSProduct *product) {
                [self.savedProducts addObject:product];
                printf("colors %lu", (unsigned long)self.savedProducts.count);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Request failed with error: %@", error);
            }];
        }
    };
    myBlock();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        printf("colors %lu", (unsigned long)self.savedProducts.count);
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:self.savedProducts] forKey:@"savedProducts"];
        [data synchronize];
    });
    
}
-(void)fillBrandBuffer
{
    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] getBrandsSuccess:^(NSArray *brands) {
        for(int i=0;i<200;i++)
        {
            [weakSelf.brands addObject:brands[i]];
        }
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:brands] forKey:@"brand"];
        [data synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
}

-(void)fillSizeBuffer
{
    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] getSizesSuccess:^(NSArray *sizes) {
        printf("%lu", (unsigned long)sizes.count);
        for(int i=0;i<5;i++)
        {
            [weakSelf.sizes addObject:sizes[i]];
        }
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:sizes] forKey:@"size"];
        [data synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
}

-(void)fillColorBuffer
{
//    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] getColorsSuccess:^(NSArray *colors) {
//        self.colors=colors;
//        self.colors=[[NSMutableArray alloc] init];
//        for(int i=0;i<14;i++)
//        {
//            PSSColor *thisColor = colors[i];
//            [self.colors addObject:thisColor];
//        }
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:colors] forKey:@"color"];
        [data synchronize];
//        printf("colors %lu", (unsigned long)self.colors.count);
//        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:weakSelf.colors] forKey:@"asdf"];
//        [data synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
}


-(void)fillRetailerBuffer
{
    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] getRetailersSuccess:^(NSArray *retailers) {
        for(int i=0;i<200;i++)
        {
            [weakSelf.retailers addObject:retailers[i]];
        }
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:retailers] forKey:@"retailer"];
        [data synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
}

-(void)fillCategoriesBuffer
{
    __weak typeof(self) weakSelf = self;
    [[PSSClient sharedClient] categoryTreeFromCategoryID:nil depth:nil success:^(PSSCategoryTree *categoryTree) {
        weakSelf.categories = categoryTree.rootCategory.childCategories;
        NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
        [data setObject:[NSKeyedArchiver archivedDataWithRootObject:categoryTree.rootCategory.childCategories] forKey:@"categories"];
        [data synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
}

- (void)encodeWithCoder:(nonnull NSCoder *)encoder {
    [encoder encodeObject:self.product forKey:@"name"];
    [encoder encodeObject:self.salePriceLabel forKey:@"salePriceLabel"];
}

- (id)initWithCoder:(nonnull NSCoder *)decoder {
    if((self = [self init]))
    {
        self.product = [decoder decodeObjectForKey:@"name"];
        self.salePriceLabel=[decoder decodeObjectForKey:@"salePriceLabel"];
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    typeof(self) copy = [[[self class] allocWithZone:zone] init];
    copy.name= self.name;
    copy.salePriceLabel=self.salePriceLabel;
    copy.product=self.product;
    return copy;
}

@end

