//
//  DiscussionTopicsManager.swift
//  edX
//
//  Created by Akiva Leffert on 7/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class DiscussionTopicsManager {
    private let topicStream = BackedStream<[DiscussionTopic]>()
    private let courseID : String
    private let networkManager : NetworkManager?
    
    init(courseID : String, networkManager : NetworkManager?) {
        self.courseID = courseID
        self.networkManager = networkManager
    }
    
    init(courseID : String, topics : [DiscussionTopic]) {
        self.courseID = courseID
        self.networkManager = nil
        self.topicStream.backWithStream(Stream(value: topics))
    }
    
    public var topics : Stream<[DiscussionTopic]> {
        if topicStream.value == nil && !topicStream.active {
            let request = DiscussionAPI.getCourseTopics(courseID)
            if let stream = networkManager?.streamForRequest(request, persistResponse: true, autoCancel: false) {
                topicStream.backWithStream(stream)
            }
        }
        return topicStream
    }
}