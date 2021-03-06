//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var largeTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralDark())
}

private var mediaTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XSmall, color : OEXStyles.sharedStyles().neutralDark())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXXSmall, color : OEXStyles.sharedStyles().neutralDark())
}

class DiscussionCommentCell: UITableViewCell {
    
    private static let marginX: CGFloat = 8.0

    private let bodyTextLabel = UILabel()
    private let authorLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let commentCountOrReportIconButton = DiscussionCellButton()
    private let divider = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None
        
        applyStandardSeparatorInsets()
        
        bodyTextLabel.numberOfLines = 0
        contentView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(DiscussionCommentCell.marginX)
            make.trailing.equalTo(contentView).offset(-DiscussionCommentCell.marginX)
            make.top.equalTo(contentView).offset(5)
        }
        
        contentView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bodyTextLabel)
            make.width.equalTo(80)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
        
        contentView.addSubview(dateTimeLabel)
        dateTimeLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
            make.width.equalTo(100)
            make.leading.equalTo(authorLabel.snp_trailing).offset(2)
        }
    
        contentView.addSubview(commentCountOrReportIconButton)
        commentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-5)
            make.width.equalTo(120)
            make.top.equalTo(bodyTextLabel.snp_bottom)
        }
        
        self.divider.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        
        self.contentView.addSubview(divider)
        
        self.divider.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
            make.height.equalTo(OEXStyles.dividerSize())
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    class Environment {
        private var courseDataManager : CourseDataManager?
        private weak var router: OEXRouter?
        
        init(courseDataManager : CourseDataManager, router: OEXRouter?) {
            self.courseDataManager = courseDataManager
            self.router = router
        }
    }
    
    private enum TableSection : Int {
        case Response = 0
        case Comments = 1
    }
    
    private let identifierCommentCell = "CommentCell"
    private let minBodyTextHeight: CGFloat = 70.0
    private let nonBodyTextHeight: CGFloat = 40.0
    private let defaultResponseCellHeight: CGFloat = 100.0
    private let defaultCommentCellHeight: CGFloat = 90.0
    
    private let environment: Environment
    private let courseID: String
    private let discussionManager : DiscussionDataManager?
    
    private let addCommentButton = UIButton.buttonWithType(.System) as! UIButton
    private var tableView: UITableView!
    private var comments : [DiscussionComment]  = []
    private let responseItem: DiscussionResponseItem
    
    init(environment: Environment, courseID : String, responseItem: DiscussionResponseItem) {
        self.courseID = courseID
        self.environment = environment
        self.responseItem = responseItem
        self.discussionManager = self.environment.courseDataManager?.discussionManagerForCourseWithID(self.courseID)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = OEXLocalizedString("COMMENTS", nil)
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        addCommentButton.backgroundColor = OEXStyles.sharedStyles().primaryXDarkColor()
        
        let style = OEXTextStyle(weight : .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)), style.attributedStringWithText(OEXLocalizedString("ADD_A_COMMENT", nil))])
        addCommentButton.setAttributedTitle(buttonTitle, forState: .Normal)
        addCommentButton.contentVerticalAlignment = .Center
        
        addCommentButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self {
                owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, item: DiscussionItem.Response(owner.responseItem))
            }
        }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(addCommentButton)
        addCommentButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.sharedStyles().standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
        }
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.applyStandardSeparatorInsets()
        
        if let theTableView = tableView {
            theTableView.registerClass(DiscussionCommentCell.classForCoder(), forCellReuseIdentifier: identifierCommentCell)
            theTableView.dataSource = self
            theTableView.delegate = self
            view.addSubview(theTableView)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view)
            make.top.equalTo(view).offset(10)
            make.trailing.equalTo(view)
            make.bottom.equalTo(addCommentButton.snp_top)
        }
        
        tableView.reloadData()
        
        discussionManager?.commentAddedStream.listen(self) {[weak self] result in
            result.ifSuccess {
                self?.addedItem($0.threadID, item: $0.comment)
            }
        }

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    func addedItem(threadID: String, item: DiscussionComment) {
        self.comments.append(item)
        tableView.reloadData()
    }
    
    // MARK - tableview delegate methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch TableSection(rawValue : indexPath.section) {
        case .Some(.Response):
            return defaultResponseCellHeight
        case .Some(.Comments):
            let fixedWidth = tableView.frame.size.width - 2.0 * DiscussionCommentCell.marginX
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = largeTextStyle.attributedStringWithText(comments[indexPath.row].rawBody)
            let newSize = label.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
            
            if newSize.height > minBodyTextHeight {
                return nonBodyTextHeight + newSize.height
            }
            
            return defaultCommentCellHeight
        case .None:
            assert(true, "Unexepcted table section")
            return 0
        }
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue:section) {
        case .Some(.Response): return 1
        case .Some(.Comments): return comments.count
        case .None:
            assert(true, "Unexepcted table section")
            return 0
        }
    }
    
    var commentInfoStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .Small, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell
        
        // TODO factor these into the cell classes
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Response):
            cell.bodyTextLabel.attributedText = largeTextStyle.attributedStringWithText(responseItem.body)
            cell.authorLabel.attributedText = smallTextStyle.attributedStringWithText(responseItem.author)
            cell.dateTimeLabel.attributedText = smallTextStyle.attributedStringWithText(responseItem.createdAt.timeAgoSinceNow())
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([
                Icon.Comment.attributedTextWithStyle(commentInfoStyle.withSize(.XSmall)),
                commentInfoStyle.attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("COMMENT", Float(comments.count), nil), parameters: ["count": Float(comments.count)]))])
            cell.commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal)
            return cell
        case .Some(.Comments):
            let comment = comments[indexPath.row]
            cell.bodyTextLabel.attributedText = largeTextStyle.attributedStringWithText(comment.rawBody)
            cell.authorLabel.attributedText = smallTextStyle.attributedStringWithText(comment.author)
            if let createdAt = comment.createdAt {
                cell.dateTimeLabel.attributedText = smallTextStyle.attributedStringWithText(createdAt.timeAgoSinceNow())
            }
            cell.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([
                Icon.ReportFlag.attributedTextWithStyle(commentInfoStyle.withSize(.XSmall)),
                commentInfoStyle.attributedStringWithText(OEXLocalizedString("DISCUSSION_REPORT", nil))])
            cell.commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal)
            cell.commentCountOrReportIconButton.row = indexPath.row
            cell.commentCountOrReportIconButton.oex_removeAllActions()
            cell.commentCountOrReportIconButton.oex_addAction({[weak self] (sender : AnyObject!) -> Void in
                if let owner = self, button = sender as? DiscussionCellButton, row = button.row {
                    let apiRequest = DiscussionAPI.flagComment(comment.flagged, commentID: comment.commentID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        if let comment: DiscussionComment = result.data {
                            // TODO: update UI
                        }
                    }
                }
                }, forEvents: UIControlEvents.TouchUpInside)
            
            cell.commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal)
            
            return cell
        case .None:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }
}
