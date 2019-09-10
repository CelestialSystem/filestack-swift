//
//  Client+Deprecated.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 10/09/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import Foundation

extension Client {
    /// :nodoc:
    @objc
    @available(*, deprecated, message: "Marked for removal in version 3.0. Please use upload(using:options:queue:uploadProgress:completionHandler:) instead")
    public func multiPartUpload(from localURL: URL,
                                storeOptions: StorageOptions = StorageOptions(location: .s3, access: .private),
                                useIntelligentIngestionIfAvailable: Bool = true,
                                queue: DispatchQueue = .main,
                                startUploadImmediately: Bool = true,
                                uploadProgress: ((Progress) -> Void)? = nil,
                                completionHandler: @escaping (NetworkJSONResponse) -> Void) -> MultipartUpload {
        let options = UploadOptions(preferIntelligentIngestion: useIntelligentIngestionIfAvailable,
                                    startImmediately: startUploadImmediately,
                                    storeOptions: storeOptions)

        return upload(using: localURL,
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }

    /// :nodoc:
    @objc
    @available(*, deprecated, message: "Marked for removal in version 3.0. Please use upload(using:options:queue:uploadProgress:completionHandler:) instead")
    public func multiFileUpload(from localURLs: [URL],
                                storeOptions: StorageOptions = StorageOptions(location: .s3, access: .private),
                                useIntelligentIngestionIfAvailable: Bool = true,
                                queue: DispatchQueue = .main,
                                startUploadImmediately: Bool = true,
                                uploadProgress: ((Progress) -> Void)? = nil,
                                completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> MultifileUpload {
        let options = UploadOptions(preferIntelligentIngestion: useIntelligentIngestionIfAvailable,
                                    startImmediately: startUploadImmediately,
                                    storeOptions: storeOptions)

        return upload(using: localURLs,
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }
}
