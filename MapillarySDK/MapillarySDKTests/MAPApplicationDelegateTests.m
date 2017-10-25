//
//  MAPApplicationDelegateTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

@interface MAPApplicationDelegateTests : XCTestCase

@end

@implementation MAPApplicationDelegateTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDidFinishLaunchingWithOptions
{
    BOOL ok = [MAPApplicationDelegate application:nil didFinishLaunchingWithOptions:nil];
    XCTAssertTrue(ok);
    
    // TODO add better tests
}

- (void)testopenURL
{
    BOOL ok = [MAPApplicationDelegate application:nil openURL:nil sourceApplication:nil annotation:nil];
    XCTAssertTrue(ok);
    
    // TODO add better tests
}


@end