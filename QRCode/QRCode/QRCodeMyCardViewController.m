//
//  QRCodeMyCardViewController.m
//  14-ocWeibo
//
//  Created by DianDian on 15/12/21.
//  Copyright © 2015年 DianDian. All rights reserved.
//

#import "QRCodeMyCardViewController.h"
#import <Masonry/Masonry.h>

@interface QRCodeMyCardViewController ()
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation QRCodeMyCardViewController

- (void)loadView{
    self.view = [[UIView alloc] init];
    
    // 提示，如果视图的背景颜色为 nil，会严重影响视图的`渲染`性能
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.iconView];
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(200);
        make.center.mas_equalTo(0);
    }];
    self.iconView.backgroundColor = [UIColor lightGrayColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.iconView.image = [self generateQRCodeImage];
    
    [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
}


- (UIImage *)generateQRCodeImage{
    // 1、建立二维码滤镜
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2、设置成功初始值
    [qrFilter setDefaults];
    // 3、通过KVC 设置滤镜信息
    NSString *str = @"这是二维码图像Demo";
    
    [qrFilter setValue:[str dataUsingEncoding:NSUTF8StringEncoding] forKey:@"inputMessage"];
    // 4、获取结果
    CIImage *ciImage = qrFilter.outputImage;
    
    // 5、生成图片的大小 27 * 27 / 23 * 23，不清楚
    //NSLog(@"%@",ciImage.extent);
    
    // 6、放大图片
    CGAffineTransform transform = CGAffineTransformMakeScale(15, 15);
    CIImage *transformImage = [ciImage imageByApplyingTransform:transform];
    //NSLog(@"转换的图像的大小%@",transformImage.extent);
    
    // 7、颜色滤镜
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setDefaults];
    [colorFilter setValue:transformImage forKey:@"inputImage"];
    // 前景色
    [colorFilter setValue:[[CIColor alloc] initWithColor:[UIColor blackColor]] forKey:@"inputColor0"];
    // 背景色
    
    [colorFilter setValue:[[CIColor alloc] initWithColor:[UIColor whiteColor]] forKey:@"inputColor1"];
    CIImage *resultImage = colorFilter.outputImage;
    UIImage *avatar = [UIImage imageNamed:@"avatar"];
    //return [UIImage imageWithCIImage:resultImage];
    return [self insertAvatarImage:[UIImage imageWithCIImage:resultImage] andAvatar:avatar];
}

// 在二维码图像中间增加一个头像
/**
 二维码有很强的容错性
 - 能够遮挡部分，也可以破损部分，但是，不能破坏或者遮挡定位点！
 */
- (UIImage *)insertAvatarImage:(UIImage *)image andAvatar:(UIImage *)avatar{
    // 1、开启绘图上下文，和二维码图像相同大小
    UIGraphicsBeginImageContext(image.size);
    
    // 2、绘图
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    [image drawInRect:rect];
    
    // 添加头像
    CGFloat w = rect.size.width * 0.25;
    CGFloat x = (rect.size.width - w) * 0.5;
    CGFloat y = (rect.size.height - w) * 0.5;
    [avatar drawInRect:CGRectMake(x, y, w, w)];
    
    // 3、“先”取得结果
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    // 4、"后"关闭上下文
    UIGraphicsEndImageContext();
    // 5、返回结果
    return result;
}

- (UIImageView *)iconView{
    if(_iconView == nil){
        _iconView = [[UIImageView alloc] init];
    }
    return _iconView;
}

@end
