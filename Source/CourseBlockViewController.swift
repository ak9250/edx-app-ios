//
//  CourseBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


public protocol CourseBlockViewController {
    var blockID : CourseBlockID? {get}
    var courseID : CourseBlockID {get}
    ///Method that is responsible for early loading of the data. Do all of the view independant *HEAVY LIFTING* in this
    func loadData()
}