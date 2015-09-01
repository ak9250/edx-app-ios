//
//  CLButton.h
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 Jotiram Bhagat. All rights reserved.
// testing

#import <UIKit/UIKit.h>

@protocol CLButtonDelegate <NSObject>

@optional
- (void)buttonTouchedDown:(UIButton*)button;
- (void)buttonTouchedUpOutside:(UIButton*)button;
- (void)buttonTouchCancelled:(UIButton*)button;
@end

@interface CLButton : UIButton
@property(nonatomic, weak) id <CLButtonDelegate>delegate;
@end
