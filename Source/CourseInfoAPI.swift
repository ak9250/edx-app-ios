//
//  CourseInfoAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 23/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public struct CourseInfoAPI {
    
    static func handoutsDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<String> {
        return json["handouts_html"].string.toResult(NSError.oex_courseContentLoadError())
    }
    
    public static func getHandoutsForCourseWithID(courseID : String, overrideURL: String? = nil) -> NetworkRequest<String> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : overrideURL ?? "api/mobile/v0.5/course_info/\(courseID)/handouts",
            requiresAuth : true,
            deserializer: .JSONResponse(handoutsDeserializer)
        )
    }
    
    static func announcementsDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[OEXAnnouncement]> {
        let announcements = json.array?.map {
            return OEXAnnouncement(dictionary: $0.dictionaryObject)
        }
        return announcements.toResult(NSError.oex_courseContentLoadError())
    }
    
    public static func getAnnouncementsForCourseWithID(courseID : String, overrideURL: String? = nil) -> NetworkRequest<[OEXAnnouncement]> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : overrideURL ?? "api/mobile/v0.5/course_info/\(courseID)/updates",
            requiresAuth : true,
            deserializer: .JSONResponse(announcementsDeserializer)
        )
    }
}
