//
//  IBeaconsManager.m
//  iBeaconsDemo
//
//  Created by jian.zhao on 14-8-19.
//  Copyright (c) 2014年 Elong.Inc. All rights reserved.
//

#import "IBeaconsManager.h"

#define WelcomeMessage @"欢迎使用艺龙旅行预订该酒店，价格更低，还有返现哦!"

#define kSearchBeacon_Type_Ranging 10
#define kSearchBeacon_Type_Monitoring 11

static NSString * const kUUID = @"00000000-0000-0000-0000-000000000000";
static NSString * const kIdentifier = @"SomeIdentifier";

@interface IBeaconsManager(){

    int searchBeacon_Type;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;

@end

@implementation IBeaconsManager

+(IBeaconsManager *)sharedInstance{

    static IBeaconsManager *manager = nil;
    static dispatch_once_t pre;
    dispatch_once(&pre, ^{
        manager = [[IBeaconsManager alloc] init];
    });
    return manager;
}

-(BOOL)checkBeaconsAvailable{
    
    BOOL systerm = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
    
    CBCentralManager *manager = [[CBCentralManager alloc] init];
    
    BOOL BLE_Support = ([manager state] == CBCentralManagerStateUnsupported)?NO:YES;
    
    if (systerm && BLE_Support) {
        return YES;
    }
    return NO;
}

#pragma mark 
#pragma mark - Beacon Ranging

-(void)createBeaconRegion {

    if (self.beaconRegion) {
        return;
    }
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    //major minor 采用系统默认
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

-(void)createLocationManager{

    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.activityType = CLActivityTypeFitness;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
}

/*!
 *  开始搜索Beacons
 */
- (void)startRangingForBeacons
{
    searchBeacon_Type = kSearchBeacon_Type_Ranging;
    [self createLocationManager];
    [self turnOnRanging];
}

/*!
 *  停止搜索Beacons
 */
- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    self.detectedBeacons = nil;
    
    NSLog(@"Turned off ranging.");
}

#pragma  mark
#pragma mark - Beacon region monitoring

- (void)startMonitoringForBeacons
{
    searchBeacon_Type =  kSearchBeacon_Type_Monitoring;
    [self createLocationManager];
    [self turnOnMonitoring];
}

- (void)turnOnMonitoring
{
    NSLog(@"Turning on monitoring...");
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
        return;
    }
    [self createBeaconRegion];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    NSLog(@"Monitoring turned on for region: %@.", self.beaconRegion);
}

- (void)stopMonitoringForBeacons
{
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"Turned off monitoring");
}

#pragma mark
#pragma mark Location Manager Delegate Methords

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        
        if (searchBeacon_Type == kSearchBeacon_Type_Monitoring) {
            NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
            return;
        } else {
            NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
            return;
        }
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        if (searchBeacon_Type == kSearchBeacon_Type_Monitoring) {
            NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
            return;
        } else {
            NSLog(@"Couldn't turn on ranging: Location services not authorised.");
            return;
        }        return;
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if ([beacons count] == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found beacons!");
    }
    self.detectedBeacons = beacons;
    
    for (CLBeacon *beacon in self.detectedBeacons) {
        [self dealWithTheBeacon:beacon];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Entered region: %@", region);
    
    [self sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exited region: %@", region);
}

-(void)dealWithTheBeacon:(CLBeacon *)beacon{
    
    NSString *uuid = beacon.proximityUUID.UUIDString;
    NSLog(@"UUID is %@",uuid);
    
    NSString *proximityString;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximityString = @"Near";
            break;
        case CLProximityImmediate:
            proximityString = @"Immediate";
            break;
        case CLProximityFar:
            proximityString = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximityString = @"Unknown";
            break;
    }
   NSString *des= [NSString stringWithFormat:@"%@, %@ • %@ • %f • %li",
                                        beacon.major.stringValue, beacon.minor.stringValue, proximityString, beacon.accuracy, (long)beacon.rssi];
    
    NSLog(@"des is %@",des);
}




#pragma mark
#pragma mark - Local Notifications

- (void)sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region
{
    //region 暂时不用
    UILocalNotification *notification=[[UILocalNotification alloc] init];
    notification.fireDate= [NSDate date];
    notification.repeatInterval=0;//循环次数
    notification.timeZone=[NSTimeZone defaultTimeZone];
    notification.soundName= UILocalNotificationDefaultSoundName;
    notification.alertBody=NSLocalizedString(WelcomeMessage, nil);//提示信息 弹出提示框
    notification.alertAction = @"打开";  //提示框按钮
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}


/*!
 *  设备作为广播源
 */

#pragma  mark
#pragma  mark Beacons Advertising

- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != 5) {
        NSLog(@"Peripheral manager is off.");
        return;
    }
    
    time_t t;
    srand((unsigned) time(&t));
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:rand()
                                                                     minor:rand()
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
}

- (void)startAdvertisingBeacon
{
    NSLog(@"Turning on advertising...");
    
    [self createBeaconRegion];
    
    if (!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self turnOnAdvertising];
}

- (void)stopAdvertisingBeacon
{
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Turned off advertising.");
}

#pragma mark
#pragma mark Beacons Advertising Delegate Methords
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
        return;
    }
    
    if (peripheralManager.isAdvertising) {
        NSLog(@"Turned on advertising.");
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state != 5) {
        NSLog(@"Peripheral manager is off.");
        return;
    }
    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}



@end
