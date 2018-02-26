//
//  MAPGpxParser.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPGpxParser.h"
#import "MAPLocation.h"
#import "MAPInternalUtils.h"

@interface MAPGpxParser()

@property NSXMLParser* xmlParser;
@property NSMutableArray* locations;
@property NSMutableDictionary* currentTrackPoint;
@property NSMutableString* currentElementValue;
@property NSDateFormatter* dateFormatter;
@property NSString* localTimeZone;
@property NSString* project;
@property NSString* sequenceKey;
@property NSNumber* timeOffset;
@property NSNumber* directionOffset;
@property NSString* deviceMake;
@property NSString* deviceModel;
@property NSString* deviceUUID;
@property NSDate* sequenceDate;
@property BOOL parsingMeta;
@property BOOL quickParse;

@property (nonatomic, copy) void (^doneCallback)(NSDictionary* dict);

@end

@implementation MAPGpxParser


- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self)
    {
        self.dateFormatter = [MAPInternalUtils defaultDateFormatter];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        NSData* data = [NSData dataWithContentsOfFile:path];
        self.xmlParser = [[NSXMLParser alloc] initWithData:data];
        self.xmlParser.delegate = self;
        
        self.locations = [NSMutableArray array];
        self.parsingMeta = NO;
        self.quickParse = NO;
        
        // Default values
        self.localTimeZone = [[NSTimeZone localTimeZone] description];
        self.project = @"Public";
        self.sequenceKey = [[NSUUID UUID] UUIDString];
        self.timeOffset = @0;
        self.directionOffset = @-1;
        self.sequenceDate = [NSDate date];
        
        MAPDevice* defaultDevice = [MAPDevice currentDevice];
        self.deviceMake = defaultDevice.make;
        self.deviceModel = defaultDevice.model;
        self.deviceUUID = defaultDevice.UUID;
    }
    return self;
}

- (void)parse:(void(^)(NSDictionary* dict))done
{
    self.doneCallback = done;
    [self.xmlParser parse];
}

- (void)quickParse:(void(^)(NSDictionary* dict))done
{
    self.quickParse = YES;
    self.doneCallback = done;
    [self.xmlParser parse];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self parserDidEndDocument:parser];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentElementValue = [[NSMutableString alloc] init];
    
    if ([elementName isEqualToString:@"metadata"])
    {
        self.parsingMeta = YES;
    }
    
    // Skip GPS track if we are doing a quick parse
    if (!self.quickParse && [elementName isEqualToString:@"trkpt"])
    {
        self.currentTrackPoint = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.currentElementValue appendString:string];
    //NSLog(@"%@", string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSString* strippedValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    
    // Meta
    
    if (self.parsingMeta && [elementName isEqualToString:@"time"])
    {
        self.parsingMeta = NO;
        self.sequenceDate = [self.dateFormatter dateFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:@"mapillary:localTimeZone"])
    {
        self.localTimeZone = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:project"])
    {
        self.project = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:sequenceKey"])
    {
        self.sequenceKey = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:timeOffset"])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.timeOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:@"mapillary:directionOffset"])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.directionOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceUUID"])
    {
        self.deviceUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceMake"])
    {
        self.deviceMake = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceModel"])
    {
        self.deviceModel = strippedValue;
    }
    
    // GPS track points
    else if (self.currentTrackPoint)
    {
        if ([elementName isEqualToString:@"trkpt"])
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.currentTrackPoint[@"lat"] doubleValue], [self.currentTrackPoint[@"lon"] doubleValue]);
            CLLocationDistance altitude = 0;
            CLLocationAccuracy horizontalAccuracy = [self.currentTrackPoint[@"gpsAccuracyMeters"] doubleValue];
            CLLocationAccuracy verticalAccuracy = 0;
            CLLocationDirection course = [self.currentTrackPoint[@"gpsAccuracyMeters"] doubleValue];
            CLLocationSpeed speed = 0;
            NSDate* timestamp = [self.dateFormatter dateFromString:self.currentTrackPoint[@"time"]];
            
            MAPLocation* location = [[MAPLocation alloc] init];
            location.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                              altitude:altitude
                                                    horizontalAccuracy:horizontalAccuracy
                                                      verticalAccuracy:verticalAccuracy
                                                                course:course
                                                                 speed:speed
                                                             timestamp:timestamp];
            
            
            location.timestamp = timestamp;
            
            [self.locations addObject:location];
        }
        else if (![elementName isEqualToString:@"extensions"] && ![elementName isEqualToString:@"fix"])
        {
            if ([elementName containsString:@"mapillary:"])
            {
                elementName = [elementName stringByReplacingOccurrencesOfString:@"mapillary:" withString:@""];
            }
            
            NSString* trimmedValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [self.currentTrackPoint setObject:trimmedValue forKey:elementName];
        }
    }
    
    // Check if quick parse is done
    if (self.quickParse && self.localTimeZone && self.project && self.sequenceKey && self.timeOffset && self.directionOffset && self.deviceMake && self.deviceModel && self.deviceUUID && self.sequenceDate)
    {
        [self.xmlParser abortParsing];
    }
}

- (void)parserDidEndDocument:(NSXMLParser*)parser
{
    if (self.doneCallback)
    {
        NSMutableDictionary* dict = dict = [NSMutableDictionary dictionary];
        
        [dict setObject:self.localTimeZone forKey:@"localTimeZone"];
        [dict setObject:self.project forKey:@"project"];
        [dict setObject:self.sequenceKey forKey:@"sequenceKey"];
        [dict setObject:self.timeOffset forKey:@"timeOffset"];
        [dict setObject:self.directionOffset forKey:@"directionOffset"];
        [dict setObject:self.deviceMake forKey:@"deviceMake"];
        [dict setObject:self.deviceModel forKey:@"deviceModel"];
        [dict setObject:self.deviceUUID forKey:@"deviceUUID"];
        [dict setObject:self.sequenceDate forKey:@"sequenceDate"];
        
        if (!self.quickParse)
        {
            [dict setObject:self.locations forKey:@"locations"];
        }
        
        self.doneCallback(dict);
        
        self.doneCallback = nil;
    }
}

@end
