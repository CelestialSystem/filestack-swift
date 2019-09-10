//
//  Client+ObjC.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 10/09/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import Foundation

extension Client {
    /// Uploads a single local URL directly to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Important:
    /// This function is made available especially for Objective-C SDK users, if you are using Swift, you may prefer
    /// using `upload(using:options:queue:uploadProgress:completionHandler:)` instead.
    ///
    /// - Parameter localURL: The URL of the local file to be uploaded.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle
    /// of the upload process as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `MultipartUpload` object that allows monitoring progress, cancelling the upload request, etc.
    @objc public func uploadURL(using localURL: NSURL,
                                options: UploadOptions = .defaults,
                                queue: DispatchQueue = .main,
                                uploadProgress: ((Progress) -> Void)? = nil,
                                completionHandler: @escaping (NetworkJSONResponse) -> Void) -> MultipartUpload {
        return upload(using: localURL as URL,
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }

    /// Uploads an array of local URLs directly to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Important:
    /// This function is made available especially for Objective-C SDK users, if you are using Swift, you may prefer
    /// using `upload(using:options:queue:uploadProgress:completionHandler:)` instead.
    ///
    /// - Parameter localURLs: The URL of the local file to be uploaded.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle
    /// of the upload process as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `MultifileUpload` object that allows monitoring progress, cancelling the upload request, etc.
    @objc public func uploadMultipleURLs(using localURLs: [NSURL],
                                         options: UploadOptions = .defaults,
                                         queue: DispatchQueue = .main,
                                         uploadProgress: ((Progress) -> Void)? = nil,
                                         completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> MultifileUpload {
        return upload(using: localURLs.map { $0 as URL },
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }

    /// Uploads data directly to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Important:
    /// This function is made available especially for Objective-C SDK users, if you are using Swift, you may prefer
    /// using `upload(using:options:queue:uploadProgress:completionHandler:)` instead.
    ///
    /// - Parameter data: The data to be uploaded.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle
    /// of the upload process as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `MultipartUpload` object that allows monitoring progress, cancelling the upload request, etc.
    @objc public func uploadData(using data: NSData,
                                 options: UploadOptions = .defaults,
                                 queue: DispatchQueue = .main,
                                 uploadProgress: ((Progress) -> Void)? = nil,
                                 completionHandler: @escaping (NetworkJSONResponse) -> Void) -> MultipartUpload {
        return upload(using: data as Data,
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }

    /// Uploads multiple data directly to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Important:
    /// This function is made available especially for Objective-C SDK users, if you are using Swift, you may prefer
    /// using `upload(using:options:queue:uploadProgress:completionHandler:)` instead.
    ///
    /// - Parameter multipleData: The array of data objects to be uploaded.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle
    /// of the upload process as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `MultifileUpload` object that allows monitoring progress, cancelling the upload request, etc.
    @objc public func uploadMultipleData(using multipleData: [NSData],
                                         options: UploadOptions = .defaults,
                                         queue: DispatchQueue = .main,
                                         uploadProgress: ((Progress) -> Void)? = nil,
                                         completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> MultifileUpload {
        return upload(using: multipleData.map { $0 as Data },
                      options: options,
                      queue: queue,
                      uploadProgress: uploadProgress,
                      completionHandler: completionHandler)
    }
}
