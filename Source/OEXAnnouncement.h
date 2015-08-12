//
//  OEXAnnouncement.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXAnnouncement : NSObject

- (instancetype)initWithDictionary:(nullable NSDictionary*)dictionary;

@property (copy, nonatomic, nullable) NSString* heading;
@property (copy, nonatomic, nullable) NSString* content;  //HTML text

@end

NS_ASSUME_NONNULL_END
