//
//  HirEnum.h
//  HiRemote
//
//  Created by minfengliu on 15/7/3.
//  Copyright (c) 2015年 hiremote. All rights reserved.
//

#ifndef HiRemote_HirEnum_h
#define HiRemote_HirEnum_h

typedef NS_ENUM(NSInteger, HirAddLineType){
    HirAddLineTypeUp     = 1,    //0001上
    HirAddLineTypeLeft   = 1<<1, //0010左
    HirAddLineTypeDown   = 1<<2, //0100下
    HirAddLineTypeRight  = 1<<3, //1000右
};

#endif
