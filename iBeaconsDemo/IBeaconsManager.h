//
//  IBeaconsManager.h
//  iBeaconsDemo
//
//  Created by jian.zhao on 14-8-19.
//  Copyright (c) 2014年 Elong.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@interface IBeaconsManager : NSObject<CLLocationManagerDelegate,CBPeripheralManagerDelegate>

+(IBeaconsManager *)sharedInstance;

-(BOOL)checkBeaconsAvailable;

//扫描 Beacons设备
//（Ranging方式 后台不运行 可以判断设备和 beacon 之间的距离,另外 CLBeacon 还有 accuracy 和 rssi 两个属性能提供更详细的距离数据）
- (void)startRangingForBeacons;
- (void)stopRangingForBeacons;

//（Monitoring 方式 可后台运行 但是只能同时检测 20 个 region，也不能推测设备与 beacon 的距离。）
- (void)startMonitoringForBeacons;
- (void)stopMonitoringForBeacons;

//充当 Beacons设备
- (void)startAdvertisingBeacon;
- (void)stopAdvertisingBeacon;

@end
