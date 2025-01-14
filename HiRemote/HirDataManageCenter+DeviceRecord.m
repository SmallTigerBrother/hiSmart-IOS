//
//  HirDataManageCenter+DeviceRecord.m
//  HiRemote
//
//  Created by minfengliu on 15/7/13.
//  Copyright (c) 2015年 hiremote. All rights reserved.
//

#import "HirDataManageCenter+DeviceRecord.h"

@implementation HirDataManageCenter (DeviceRecord)
//+(DBPeripheralRecord *)findDeviceRecordByPeripheralUUID:(NSString *)peripheralUUID{
//    if (!peripheralUUID) {
//        return nil;
//    }
//    NSString *userId = [HirUserInfo shareUserInfo].userId;
//    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peripheralUUID == %@ AND userId == %@",peripheralUUID,userId];
//    DBPeripheralRecord *deviceRecord = [DBPeripheralRecord MR_findFirstWithPredicate:predicate];
//    return deviceRecord;
//}

+(NSMutableArray *)findAllRecordByPeripheralUUID:(NSString *)peripheralUUID{
    NSString *userId = [HirUserInfo shareUserInfo].userId;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peripheralUUID == %@ AND userId == %@",peripheralUUID,userId];
    
    NSArray *list = [DBPeripheralRecord MR_findAllSortedBy:@"timestamp" ascending:NO withPredicate:predicate];
    
    for (DBPeripheralRecord *peripheralRecord in list) {
        NSLog(@"userId = %@,peripheralRecord = %@",peripheralRecord.userId,peripheralRecord.peripheralUUID);
    }
    
    if ([list count] == 0) {
        return [NSMutableArray arrayWithCapacity:3];
    }
    return  [NSMutableArray arrayWithArray:list];
}

//插入一条记录
+(void)insertVoicePath:(NSString *)voicePath peripheraUUID:(NSString *)peripheraUUID recoderTimestamp:(NSNumber *)recoderTimestamp title:(NSString *)title voiceTime:(NSNumber *)voiceTime;
{
//    DBPeripheralRecord *deviceRecord = [HirDataManageCenter findDeviceRecordByPeripheralUUID:peripheraUUID];
//    if (deviceRecord) {
//        if (voicePath) {
//            deviceRecord.fileName = voicePath;
//        }
//        if (peripheraUUID) {
//            deviceRecord.peripheralUUID = peripheraUUID;
//        }
//        if (recoderTimestamp) {
//            deviceRecord.timestamp = recoderTimestamp;
//        }
//        if (title) {
//            deviceRecord.title = title;
//        }
//        if (voiceTime) {
//            deviceRecord.duration = voiceTime;
//        }
//    }
//    else{
    //    }

    DBPeripheralRecord *deviceRecord = [DBPeripheralRecord MR_createEntity];
    deviceRecord.fileName = voicePath;
    deviceRecord.timestamp = recoderTimestamp;
    deviceRecord.title = title;
    deviceRecord.duration = voiceTime;
    deviceRecord.peripheralUUID = peripheraUUID;
    NSString *userId = [HirUserInfo shareUserInfo].userId;
    deviceRecord.userId = userId;
    deviceRecord.sync = @0;
    
    [[NSManagedObjectContext MR_context]MR_saveOnlySelfAndWait];
    dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.7 * NSEC_PER_SEC));
    dispatch_after(dispatchTime,dispatch_get_main_queue(), ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_RECORD_UPDATA_NOTIFICATION object:nil];
    });
}

//删除一条记录
+(void)delDeviceRecordByModel:(DBPeripheralRecord *)deviceRecord{
    //删除文件
//
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:deviceRecord.fileName];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    BOOL bRet = [fileMgr fileExistsAtPath:soundFilePath];
    if (bRet) {
        //
        NSError *err;
        [fileMgr removeItemAtPath:soundFilePath error:&err];
    }
    
    [deviceRecord MR_deleteEntity];
    [[NSManagedObjectContext MR_context]MR_saveOnlySelfAndWait];
}

//保存修改后的记录
+(void)saveDeviceRecordByModel:(DBPeripheralRecord *)deviceRecord{
    [[NSManagedObjectContext MR_context]MR_saveOnlySelfAndWait];
}
@end
