//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let notificationLabelLeadingOffset = 20.0
private let notificationLabelTrailingOffset = -10.0
private let notificationBarHeight = 50.0


class CourseAnnouncementsViewControllerEnvironment : NSObject {
    private let config : OEXConfig?
    private let dataInterface : OEXInterface?
    private let networkManager : NetworkManager
    private let pushSettingsManager : OEXPushSettingsManager
    private weak var router : OEXRouter?
    private let styles : OEXStyles
    
    init(config : OEXConfig?, dataInterface : OEXInterface?, networkManager : NetworkManager, pushSettingsManager : OEXPushSettingsManager, router : OEXRouter, styles : OEXStyles) {
        self.config = config
        self.dataInterface = dataInterface
        self.networkManager = networkManager
        self.router = router
        self.pushSettingsManager = pushSettingsManager
        self.styles = styles
    }
}


class CourseAnnouncementsViewController: UIViewController, UIWebViewDelegate {
    
    private let environment: CourseAnnouncementsViewControllerEnvironment
    private let courseID : String
    private let announcements = BackedStream<[OEXAnnouncement]>()
    
    private var container : UIView!
    private var webView: UIWebView!
    private var notificationBar: UIView!
    private var notificationLabel: UILabel!
    private var notificationSwitch: UISwitch!
    
    private let loadController : LoadStateViewController
    
    private let fontStyle = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlack())
    private let switchStyle = OEXStyles.sharedStyles().standardSwitchStyle()
    
    init(environment: CourseAnnouncementsViewControllerEnvironment, courseID : String) {
        self.courseID = courseID
        self.environment = environment
        loadController = LoadStateViewController(styles: environment.styles)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.environment.styles.standardBackgroundColor()
        
        self.container = UIView(frame : CGRectZero)
        
        self.webView = UIWebView()
        self.notificationBar = UIView(frame: CGRectZero)
        self.notificationLabel = UILabel(frame: CGRectZero)
        self.notificationSwitch = UISwitch(frame: CGRectZero)
        
        addSubviews()
        setConstraints()
        setStyles()
        
        loadController.setupInController(self, contentView: container)
        
        notificationSwitch.oex_addAction({[weak self] (sender : AnyObject!) -> Void in
            if let owner = self {
                owner.environment.pushSettingsManager.setPushDisabled(!owner.notificationSwitch.on, forCourseID: owner.courseID)
            }}, forEvents: UIControlEvents.ValueChanged)
        
        self.webView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAnnouncements()
    }
    
    var notificationsEnabled : Bool {
        return environment.config?.pushNotificationsEnabled() ?? false
    }
    
    //MARK: - Setup UI
    func addSubviews() {
        self.view.addSubview(container)
        self.container.addSubview(webView)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        if notificationsEnabled {
            self.container.addSubview(notificationBar)
            notificationBar.addSubview(notificationLabel)
            notificationBar.addSubview(notificationSwitch)
        }
    }
    
    func setConstraints() {
        container.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        if notificationsEnabled {
            notificationLabel.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(notificationBar.snp_leading).offset(notificationLabelLeadingOffset)
                make.centerY.equalTo(notificationBar)
                make.trailing.equalTo(notificationSwitch)
            }
            
            notificationSwitch.snp_makeConstraints { (make) -> Void in
                make.centerY.equalTo(notificationBar)
                make.trailing.equalTo(notificationBar).offset(notificationLabelTrailingOffset)
            }
            
            notificationBar.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.container)
                make.leading.equalTo(self.container)
                make.trailing.equalTo(self.container)
                make.height.equalTo(notificationBarHeight)
            }
        }
        
        webView.snp_makeConstraints { (make) -> Void in
            if notificationsEnabled {
                make.top.equalTo(notificationBar.snp_bottom)
            }
            else {
                make.top.equalTo(self.container)
            }
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func setStyles() {
        self.navigationItem.title = OEXLocalizedString("COURSE_ANNOUNCEMENTS", nil)
        notificationBar.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        switchStyle.applyToSwitch(notificationSwitch)
        notificationLabel.attributedText = fontStyle.attributedStringWithText(OEXLocalizedString("NOTIFICATIONS_ENABLED", nil))
        notificationSwitch.on = !self.environment.pushSettingsManager.isPushDisabledForCourseWithID(self.courseID)
    }
    
    //MARK: - Datasource
    
    private func streamForCourse(course : OEXCourse) -> Stream<[OEXAnnouncement]>? {
        if let access = course.courseware_access where !access.has_access {
            return Stream<[OEXAnnouncement]>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
        }
        else {
            let request = CourseInfoAPI.getAnnouncementsForCourseWithID(courseID, overrideURL: course.course_updates)
            let loader = self.environment.networkManager.streamForRequest(request, persistResponse: true)
            return loader
        }
    }
    
    private func loadAnnouncements() {
        if let courseStream = self.environment.dataInterface?.courseStreamWithID(courseID) {
            let handoutStream = courseStream.transform {[weak self] course in
                return self?.streamForCourse(course) ?? Stream<[OEXAnnouncement]>(error : NSError.oex_courseContentLoadError())
            }
            
            self.announcements.backWithStream(handoutStream)
        }
        
        addListener()
        
    }
    
    private func addListener() {
        announcements.listen(self, success: { [weak self] announcements in
            self?.useAnnouncements(announcements)
            self?.loadController.state = .Loaded
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            } )
    }
    
    //MARK: - Presenter
    
    func useAnnouncements(announcements:[OEXAnnouncement])
    {
        if (announcements.count < 1)
        {
            return
        }
        
        //TODO: Hide the loader
        var html:String = String()
        
        for (index,announcement) in enumerate(announcements)
        {
            let heading = announcement.heading ?? ""
                html += "<div class=\"announcement-header\">\(heading)</div>"
                html += "<hr class=\"announcement\"/>"
                html += announcement.content ?? ""
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
        }
        var displayHTML = self.environment.styles.styleHTMLContent(html)
        let baseURL = self.environment.networkManager.baseURL
        self.webView?.loadHTMLString(displayHTML, baseURL: baseURL)
    }
    
    //MARK: - UIWebViewDeleagte
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.Other) {
            if let URL = request.URL {
                UIApplication.sharedApplication().openURL(URL)
                return false
            }
        }
        return true
    }
}
