//
//  MAPLocation.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface MAPLocation : NSObject <NSCopying>

@property CLLocation* location;
@property double magneticHeading;
@property double trueHeading;
@property double headingAccuracy;
@property NSDate* timestamp;
@property double deviceMotionX;
@property double deviceMotionY;
@property double deviceMotionZ;

- (BOOL)isEqualToLocation:(MAPLocation*)aLocation;
- (NSString*)timeString;

@end
