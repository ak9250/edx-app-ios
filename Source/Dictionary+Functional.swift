//
//  Dictionary+Functional.swift
//  edX
//
//  Created by Akiva Leffert on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension Dictionary {
    
    init(elements : [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
    
    func mapValues<T>(f : Value -> T) -> [Key:T] {
        var result : [Key:T] = [:]
        for (key, value) in self {
            result[key] = f(value)
        }
        return result
    }
}

extension NSDictionary {
    func mapValues<Key, T>(f : AnyObject -> T) -> [Key:T] {
        var result : [Key:T] = [:]
        enumerateKeysAndObjectsUsingBlock { (key, value, _) -> Void in
            if let key = key as? Key {
                let value = f(value)
                result[key] = value
            }
        }
        return result
    }
}
