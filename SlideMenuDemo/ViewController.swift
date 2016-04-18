//
//  ViewController.swift
//  SlideMenuDemo
//
//  Created by ying on 16/4/13.
//  Copyright © 2016年 ying. All rights reserved.
//

import UIKit

// 菜单状态枚举
enum MenuState {
    case Collapsed  // 未显示(收起)
    case Expanding   // 展开中
    case Expanded   // 展开
}

class ViewController: UIViewController {
    
    //主页导航控制器
    var mainNavigationViewController: UINavigationController!
    
    //主页面控制器
    var mainViewController: MainViewController!
    
    //菜单页控制器
    var menuViewController: MenuViewController?
    
    //菜单页当前状态
    var currentState = MenuState.Collapsed {
        didSet {
            //菜单展开的时候，给主页面边缘添加阴影
            let shouldShowShadow = currentState != .Collapsed
            showShadowForMainViewController(shouldShowShadow)
        }
    }
    
    //菜单打开后主页面在屏幕右侧露出部分的宽度
    let menuViewExpandedOffset: CGFloat = 60
    
    //侧滑菜单黑色半透明遮罩层
    var blackCover: UIView?
    
    //最小缩放比例
    let minProportion: CGFloat = 0.77
    
    //侧滑开始时，菜单视图起始的偏移量
    let menuViewStartOffset: CGFloat = 70
    

    //
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //状态栏文字改成白色
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        let imageView = UIImageView(image: UIImage(named: "back"))
        imageView.frame = UIScreen.mainScreen().bounds
        self.view.addSubview(imageView)
        
        //初始化主视图
        mainNavigationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("mainNavigation") as! UINavigationController
        view.addSubview(mainNavigationViewController.view)
        
        //指定Navigation Bar 左侧按钮事件
        mainViewController = mainNavigationViewController.viewControllers.first as! MainViewController
        mainViewController.navigationItem.leftBarButtonItem?.action = Selector("showMenu")
        
        //添加拖动手势
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        mainNavigationViewController.view.addGestureRecognizer(panGestureRecognizer)
        
        //单击收起菜单手势
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture")
        mainNavigationViewController.view.addGestureRecognizer(tapGestureRecognizer)

    }
    
    //导航栏左侧按钮事件响应
    func showMenu()
    {
        //如果菜单是展开的，则会收起，否则就展开
        if currentState == .Expanded
        {
            animateMainView(false)
        }
        else
        {
            addMenuViewController()
            animateMainView(true)
        }
    }
    
    //拖动手势响应函数
    func handlePanGesture(recognizer: UIPanGestureRecognizer)
    {
        switch (recognizer.state) {
        //刚刚开始滑动
        case .Began:
            //判断拖动方向
            let dragFromLeftToRight = (recognizer.velocityInView(view).x > 0)
            //如果刚刚开始滑动的时候还处于主页面，从左向右滑动加入侧面菜单
            if (currentState == .Collapsed && dragFromLeftToRight)
            {
                currentState = .Expanding
                addMenuViewController()
            }
        //如果是正在滑动，则偏移主视图的坐标实现跟随手指位置移动
        case .Changed:
            
            let screenWidth = view.bounds.size.width
            var centerX = recognizer.view!.center.x + recognizer.translationInView(view).x
            //页面滑倒最左侧的话就不许继续向左移动
            if (centerX < screenWidth/2) { centerX = screenWidth/2 }
            //计算缩放比例
            let  percent: CGFloat = (centerX - screenWidth/2)/(view.bounds.size.width - menuViewExpandedOffset)
            var proportion = 1 - (1-minProportion) * percent
            
            //执行视差特效
            blackCover?.alpha = (proportion-minProportion)/(1-minProportion)
            
            //主页面滑到最左侧的话，就不需要继续往左移动
            recognizer.view!.center.x = centerX
            recognizer.setTranslation(CGPointZero, inView: view)
            //缩放主页面
            recognizer.view!.transform = CGAffineTransformScale(CGAffineTransformIdentity, proportion, proportion)
            
            //菜单视图移动
            menuViewController?.view.center.x = screenWidth/2 - menuViewStartOffset * (1 - percent)
            
            //菜单视图缩放
            let menuProportion = (1 + minProportion) - proportion
            menuViewController?.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, menuProportion, menuProportion)
            
        //如果滑动结束
        case .Ended:
            //根据页面滑动是否过半，判断后面是自动展开还是收缩
            let hasMovedhanHalfway = (recognizer.view!.center.x > view.bounds.size.width)
            animateMainView(hasMovedhanHalfway)
        default:
            break
        }
    }
    
    //单击手势响应
    func handleTapGesture()
    {
        //
        if currentState == .Expanded
        {
            animateMainView(false)
        }
    }
    
    //添加菜单项
    func addMenuViewController()
    {
        if (menuViewController == nil)
        {
            menuViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("menuView") as? MenuViewController

            //插入当前视图并置顶
            view.insertSubview(menuViewController!.view, belowSubview: mainNavigationViewController.view)
            
            //建立父子关系
            addChildViewController(menuViewController!)
            menuViewController!.didMoveToParentViewController(self)
            
            //侧滑菜单之上增加黑色遮罩层，目的是实现视差特效
            blackCover = UIView(frame: CGRectOffset(self.view.frame, 0, 0))
            blackCover!.backgroundColor = UIColor.blackColor()
            self.view.insertSubview(blackCover!, belowSubview: mainNavigationViewController.view)
        }
    }
    
    //主页自动展开、收起动画
    func animateMainView(shouldExpand: Bool)
    {
        //如果是用来展开
        if (shouldExpand)
        {
            //更新当前状态
            currentState = .Expanded
            //动画
            let mainPosition = view.bounds.size.width * (1+minProportion/2) - menuViewExpandedOffset
            doTheAnimate(mainPosition, mainProportion: minProportion, menuPosition: view.bounds.size.width/2, menuProportion:1, blackCoverAlpha: 0)
            
        }
        //如果是用于隐藏
        else
        {
            //动画
            doTheAnimate(view.bounds.size.width/2, mainProportion: 1, menuPosition: view.bounds.size.width/2, menuProportion:1, blackCoverAlpha: 1) {
                finished in
                //动画结束之后更新状态
                self.currentState = .Collapsed
                //移除左侧视图
                self.menuViewController?.view.removeFromSuperview()
                //释放内存
                self.menuViewController = nil
                //移除黑色遮罩层
                self.blackCover?.removeFromSuperview()
                //释放内存
                self.blackCover = nil
                
            }
        }
        
    }
    
    //主页移动动画、黑色遮罩层动画
    func doTheAnimate(mainPosition: CGFloat, mainProportion:CGFloat, menuPosition: CGFloat, menuProportion: CGFloat, blackCoverAlpha: CGFloat, completion: ((Bool) -> Void)! = nil)
    {
        //usingSpringWithDamping: 1.0  表示没有弹簧震动动画
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
     self.mainNavigationViewController.view.center.x = mainPosition
            self.blackCover?.alpha = blackCoverAlpha
            //缩放主页面
            self.mainNavigationViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, mainProportion, mainProportion)
            //菜单也移动
            self.menuViewController?.view.center.x = menuPosition
            self.menuViewController?.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, menuProportion, menuProportion)
            }, completion: completion)
    }

    //给主页边缘添加、取消阴影
    func showShadowForMainViewController(shouldShowShadow: Bool)
    {
        if shouldShowShadow {
            mainNavigationViewController.view.layer.shadowOpacity = 0.8
        } else {
            mainNavigationViewController.view.layer.shadowOpacity = 0.0
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

