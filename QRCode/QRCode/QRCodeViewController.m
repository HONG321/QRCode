//
//  QRCodeViewController.m
//  14-ocWeibo
//
//  Created by DianDian on 15/12/21.
//  Copyright © 2015年 DianDian. All rights reserved.
//

#import "QRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QRCodeMyCardViewController.h"

@interface QRCodeViewController ()<UITabBarDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightCons;

// 顶部约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCons;
// 冲击波图片
@property (weak, nonatomic) IBOutlet UIImageView *scanImage;
// 结果标签
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
// 输出数据
@property (nonatomic, strong) AVCaptureMetadataOutput *outputData;

// session桥梁
@property (nonatomic, strong) AVCaptureSession *session;
// 预览视图 - 依赖于session的
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) CALayer *drawLayer;
@end

@implementation QRCodeViewController

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)showMyCard:(id)sender {
    [self.navigationController pushViewController:[QRCodeMyCardViewController new] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBar.selectedItem = self.tabBar.items[0];
    self.tabBar.delegate = self;
    
    // 设置二维码扫描环境
    [self setupSession];
    [self setupLayer];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // 开启动画
    [self startAnimation];
    
    // 开始扫描
    [self starScan];
}



- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    // 调整高度
    self.heightCons.constant = self.widthCons.constant * (item.tag == 1 ? 0.5 : 1);
    
    // 停止动画 - 核心动画将动画添加到图层
    [self.scanImage.layer removeAllAnimations];
    
    // 重新开始动画
    [self startAnimation];
}


// 开启扫描动画
- (void)startAnimation{
    self.topCons.constant = - self.heightCons.constant;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:2.0 animations:^{
       // 重复次数需要放在内部
        [UIView setAnimationRepeatCount:MAXFLOAT];
        
        // 添加了修改的标记
        self.topCons.constant = self.heightCons.constant;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - 二维码扫描
/// 开始扫描
- (void)starScan{
    [self.session startRunning];
}

/// 设置图层
- (void)setupLayer{
    // 1、设置绘图图层
    self.drawLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.drawLayer atIndex:0];
    
    // 2、预览图层-设定图层的大小
    self.previewLayer.frame = self.view.bounds;
    // 设置图层填充模式
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // 将图层添加到当前图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

/// 设置会话
- (void)setupSession{
    // 1、判断能否添加输入设备
    if(![self.session canAddInput:self.inputDevice]){
        NSLog(@"无法添加输入设备");
        return;
    }
    
    // 2、判断能否添加输出数据
    if(![self.session canAddOutput:self.outputData]){
        NSLog(@"无法添加输出数据");
        return;
    }
    
    // 3、添加设备
    [self.session addInput:self.inputDevice];
    NSLog(@"前%@",self.outputData.availableMetadataObjectTypes);
    [self.session addOutput:self.outputData];
    NSLog(@"后%@",self.outputData.availableMetadataObjectTypes);
    
    // 4、设置检测数据类型，检测所有支持的数据格式
    self.outputData.metadataObjectTypes = self.outputData.availableMetadataObjectTypes;
    
    // 5、设置数据的代理
    [self.outputData setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
}

#pragma mark -AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    [self clearDrawLayer];
    
    for (id object in metadataObjects) {
        // 判断识别对象类型
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            // 转换数据类型
            id codeObject = [self.previewLayer transformedMetadataObjectForMetadataObject:object];
            [self drawCorners:codeObject];
            self.resultLabel.text = [codeObject stringValue];
        }
    }
}

/// 清空图层
- (void)clearDrawLayer{
    // 如果没有子图层，直接返回
    if (self.drawLayer.sublayers == nil || self.drawLayer.sublayers.count == 0){
        return;
    }

    for (int i=0; i<self.drawLayer.sublayers.count; i++) {
        [self.drawLayer.sublayers[i] removeFromSuperlayer];
    }
    
}

/// 绘制变形形状
- (void)drawCorners:(AVMetadataMachineReadableCodeObject *)codeObject{
    NSLog(@"%@",codeObject);
    // 可以做动画绘图，专门在图层中画图
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineWidth = 4;
    layer.strokeColor = [UIColor greenColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 是一个 包含 CFDictionaries 的 NSArray
    layer.path = [self createPath:codeObject.corners].CGPath;
    [self.drawLayer addSublayer:layer];
}

- (UIBezierPath *)createPath:(NSArray *)corners{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    CGPoint point = CGPointZero;
    int index = 0;
    // 拿到第 0 个点
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[index++], &point);
    // 移动到第 0 个点
    [path moveToPoint:point];
    
    // 遍历剩余的点
    while (index < corners.count) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[index++], &point);
        // 添加路线
        [path addLineToPoint:point];
    }
    
    // 关闭路径
    [path closePath];
    return path;
}


// 懒加载
// 输入设备
- (AVCaptureDeviceInput *)inputDevice{
    // 取摄像头准备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *inputDevice = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
        return nil;
    }else{
        return inputDevice;
    }
}

// 输出数据
- (AVCaptureMetadataOutput *)outputData{
    if(_outputData == nil){
        _outputData = [AVCaptureMetadataOutput new];
    }
    return _outputData;
}

// session桥梁
- (AVCaptureSession *)session{
    if(_session == nil){
        _session = [AVCaptureSession new];
    }
    return _session;
}

// 预览视图 - 依赖于session的
- (AVCaptureVideoPreviewLayer *)previewLayer{
    if(_previewLayer == nil){
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    }
    return _previewLayer;
}

- (CALayer *)drawLayer{
    if(_drawLayer == nil){
        _drawLayer = [CALayer new];
    }
    return _drawLayer;
}

@end
