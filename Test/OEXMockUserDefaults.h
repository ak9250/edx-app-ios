//
//  OEXMockUserDefaults.h
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEXRemovable;

// Simplified version of NSUserDefaults for testing that does not persist its data
@interface OEXMockUserDefaults : NSObject

// Only supports a few types for now, but we should add the wrappers from NSUserDefaults as we need them
- (id)objectForKey:(NSString*)key;
- (void)setObject:(id)object forKey:(NSString*)key;

- (BOOL)boolForKey:(NSString*)key;
- (void)setBool:(BOOL)value forKey:(NSString*)key;

- (NSInteger)integerForKey:(NSString*)key;
- (void)setInteger:(NSInteger)value forKey:(NSString*)key;

- (void)removeObjectForKey:(NSString*)key;

- (void)synchronize;

/// Globally replace [NSUserDefaults standardUserDefaults] with this mock. Make sure to remove it
/// when your test is done.
- (id <OEXRemovable>)installAsStandardUserDefaults;

@end
