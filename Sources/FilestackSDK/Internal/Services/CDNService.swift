//
//  CDNService.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 03/07/2017.
//  Copyright © 2017 Filestack. All rights reserved.
//

import Alamofire
import Foundation

private let Shared = CDNService()

final class CDNService: NetworkingServiceWithBaseURL {
    // MARK: - Internal Properties

    let sessionManager = SessionManager.filestack()
    let baseURL = Constants.cdnURL

    static let shared = Shared
}

// MARK: - Internal Functions

extension CDNService {
    func getDataRequest(handle: String,
                               path: String?,
                               parameters: [String: Any]?,
                               security: Security?) -> DataRequest? {
        guard let url = buildURL(handle: handle, path: path, security: security) else { return nil }

        return sessionManager.request(url, method: .get, parameters: parameters)
    }

    func getImageTaggingRequest(type: String, handle: String, security: Security?) -> DataRequest? {
        var url = baseURL.appendingPathComponent(type)

        if let security = security {
            url.appendPathComponent("security=policy:\(security.encodedPolicy),signature:\(security.signature)")
        }

        url.appendPathComponent(handle)

        return sessionManager.request(url, method: .get, parameters: nil)
    }

    func downloadRequest(handle: String,
                                path: String?,
                                parameters: [String: Any]?,
                                security: Security?,
                                downloadDestination: DownloadRequest.DownloadFileDestination?) -> DownloadRequest? {
        guard let url = buildURL(handle: handle, path: path, security: security) else { return nil }

        return sessionManager.download(url, method: .get, parameters: parameters, to: downloadDestination)
    }
}
