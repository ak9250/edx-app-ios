//
//  NetworkPaginator.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 21/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class NetworkPaginator<A> {
    
    private let paginatedFeed : PaginatedFeed<NetworkRequest<[A]>>
    private let networkManager : NetworkManager?
    private let tableView : UITableView
    
    private let activityIndicator : UIActivityIndicatorView
    
    public var hasMoreResults:Bool = true {
        didSet {
            if !hasMoreResults {
                self.tableView.tableFooterView = nil
            }
        }
    }
    
    init(networkManager : NetworkManager?, paginatedFeed : PaginatedFeed<NetworkRequest<[A]>>, tableView : UITableView) {
        self.paginatedFeed =  paginatedFeed
        self.networkManager = networkManager
        self.tableView = tableView
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        self.activityIndicator.hidesWhenStopped = true
        self.loading = false
        addActivityIndicator()
        
    }
    
    func addActivityIndicator() {
        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, self.tableView.bounds.size.width , 30.0))
        self.tableView.tableFooterView?.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(tableView.tableFooterView!)
        }
    }
    
    func loadDataIfAvailable(callback : [A]? -> Void) {
        if (!hasMoreResults) {
            loading = false
            callback(nil)
            return
        }
        loading = true
        networkManager?.taskForRequest(paginatedFeed.next()) { [weak self] results in
            self?.loading = false
            if let items = results.data, resultsPerPage = self?.paginatedFeed.current().pageSize() {
                
                self?.hasMoreResults = items.count == resultsPerPage
                callback(items)
            }
            else {
                self?.hasMoreResults = false
                callback(nil)
            }
        }
    }
    
    private var loading : Bool {
        didSet {
            if loading {
                
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
}
