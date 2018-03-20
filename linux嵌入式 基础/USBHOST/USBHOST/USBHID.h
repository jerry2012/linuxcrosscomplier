//
//  USBHID.h
//  USBHOST
//
//  Created by admindyn on 2018/3/20.
//  Copyright © 2018年 admindyn. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>

@protocol UsbHIDDelegate <NSObject>
@optional
- (void)usbhidDidRecvData:(uint8_t*)recvData length:(CFIndex)reportLength;
- (void)usbhidDidMatch;
- (void)usbhidDidRemove;
@end

@interface USBHID : NSObject {
    IOHIDManagerRef managerRef;
    IOHIDDeviceRef deviceRef;
}

@property(nonatomic,strong)id<UsbHIDDelegate> delegate;

+ (USBHID *)sharedManager;
- (void)connectHID;
- (void)senddata:(char*)outbuffer;
- (IOHIDManagerRef)getManageRef;
- (void)setManageRef:(IOHIDManagerRef)ref;
- (IOHIDDeviceRef)getDeviceRef;
- (void)setDeviceRef:(IOHIDDeviceRef)ref;
@end
