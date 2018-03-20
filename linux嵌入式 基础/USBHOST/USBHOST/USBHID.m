//
//  USBHID.m
//  USBHOST
//
//  Created by admindyn on 2018/3/20.
//  Copyright © 2018年 admindyn. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOTypes.h>
#include <IOKit/IOReturn.h>
#include <IOKit/hid/IOHIDLib.h>

#import "USBHID.h"
@implementation USBHID

static USBHID *_sharedManager = nil;

@synthesize delegate;

static void MyInputCallback(void* context, IOReturn result, void* sender, IOHIDReportType type, uint32_t reportID, uint8_t *report,CFIndex reportLength) {
    
#pragma mark 打印USB发来的消息
    /*
     打印USB发来的消息
     */
    
//RobotPenUSBLog(@"%s",report);
    
    [[[USBHID sharedManager] delegate] usbhidDidRecvData:report length:reportLength];
}

static void Handle_DeviceMatchingCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {

#pragma mark 这里才是获取到对应的刚插入的USB设备
    
    //插入设备获取到IOHIDDeviceRef inIOHIDDeviceRef后，打开IOHIDDeviceRef。
    
    [[USBHID sharedManager] setDeviceRef:inIOHIDDeviceRef];
    char *inputbuffer = malloc(64);
   
    
   /*
    前面设置回调代理 是给USB管理器设置插拔监听回调
    
    下面 是给当前的设备 文件描述符
    添加读写数据的监听
    */
    
#pragma mark 注册的接收数据callback
    IOHIDDeviceRegisterInputReportCallback([[USBHID sharedManager]getDeviceRef], (uint8_t*)inputbuffer, 64, MyInputCallback, NULL);
    NSLog(@"%p设备插入,现在usb设备数量:%ld",(void *)inIOHIDDeviceRef,USBDeviceCount(inSender));
    [[[USBHID sharedManager] delegate] usbhidDidMatch];
}

static void Handle_DeviceRemovalCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {
    [[USBHID sharedManager] setDeviceRef:nil];
    NSLog(@"%p设备拔出,现在usb设备数量:%ld",(void *)inIOHIDDeviceRef,USBDeviceCount(inSender));
    [[[USBHID sharedManager] delegate] usbhidDidRemove];
}

static long USBDeviceCount(IOHIDManagerRef HIDManager){
    CFSetRef devSet = IOHIDManagerCopyDevices(HIDManager);
    if(devSet)
        return CFSetGetCount(devSet);
    return 0;
}

+(USBHID *)sharedManager {
    @synchronized( [USBHID class] ){
        if(!_sharedManager)
            _sharedManager = [[self alloc] init];
        return _sharedManager;
    }
    return nil;
}

+(id)alloc {
    @synchronized ([USBHID class]){
        NSAssert(_sharedManager == nil,
                 @"Attempted to allocated a second instance");
        _sharedManager = [super alloc];
        return _sharedManager;
    }
    return nil;
}

- (id)init {
    self = [super init];
    if (self) {
        //初始化IOHIDManager
        managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

#pragma mark peiduishebei
        /*
         3、进行配对设置，可以过滤其他USB设备。
         
         //单类设备配对
         const long vendorID = 0x1391;
         const long productID = 0x2111;
         NSMutableDictionary* dict= [NSMutableDictionary dictionary];
         [dict setValue:[NSNumber numberWithLong:productID] forKey:[NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding]];
         [dict setValue:[NSNumber numberWithLong:vendorID] forKey:[NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding]];
         IOHIDManagerSetDeviceMatching(managerRef, (__bridge CFMutableDictionaryRef)dict);
        
         */
        
        //无配对设备
    IOHIDManagerSetDeviceMatching(managerRef, NULL);
        
        
        
       //注册插拔设备的callback
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, &Handle_DeviceMatchingCallback, NULL);
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, &Handle_DeviceRemovalCallback, NULL);
        
        
#pragma mark addrunloop
        //加入RunLoop
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        //打开IOHIDManager
        
        IOReturn ret = IOHIDManagerOpen(managerRef, 0L);
        if (ret != kIOReturnSuccess) {
            NSLog(@"打开设备失败!");
            return self;
        }
         CFRunLoopRun();
        
        NSSet* allDevices = (__bridge NSSet*)(IOHIDManagerCopyDevices(managerRef));
        NSArray* deviceRefs = [allDevices allObjects];
        if (deviceRefs.count==0) {
            NSLog(@"没有获取到设备？？");
        }
    }
    return self;
}

- (void)dealloc {
    
#pragma mark 断开与当前USB设备的连接通讯
//断开与当前USB设备的连接通讯
    
    IOReturn ret = IOHIDDeviceClose(deviceRef, 0L);
  
    if (ret == kIOReturnSuccess) {
         NSLog(@"断开成功");
        deviceRef = nil;
    }
    ret = IOHIDManagerClose(managerRef, 0L);
    if (ret == kIOReturnSuccess) {
        managerRef = nil;
    }
}

- (void)connectHID {
    NSSet* allDevices = (__bridge NSSet*)(IOHIDManagerCopyDevices(managerRef));
    NSArray* deviceRefs = [allDevices allObjects];

#pragma mark 连接设备 默认获取设备列表中的第一个设备
    
    deviceRef = (deviceRefs.count)?(__bridge IOHIDDeviceRef)[deviceRefs objectAtIndex:0]:nil;
}

- (void)senddata:(char*)outbuffer {
    if (!deviceRef) {
        return ;
    }
    
#pragma mark 向USB设备发送指令
    
    //向USB设备发送指令

    IOReturn ret = IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, (uint8_t*)outbuffer, sizeof(outbuffer));
    if (ret != kIOReturnSuccess) {
        NSLog(@"发送数据失败!");
    }
}

- (IOHIDManagerRef)getManageRef {
    return managerRef;
}

- (void)setManageRef:(IOHIDManagerRef)ref {
    managerRef = ref;
}

- (IOHIDDeviceRef)getDeviceRef {
    return deviceRef;
}

- (void)setDeviceRef:(IOHIDDeviceRef)ref {
    deviceRef = ref;
}

@end
