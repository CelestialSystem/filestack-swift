//
//  MultipartUpload.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 7/18/17.
//  Copyright © 2017 Filestack. All rights reserved.
//

import Foundation

/// :nodoc:
enum MultipartUploadError: Error {
    case invalidFile
    case aborted
    case error(description: String)
}

extension MultipartUploadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The file provided is invalid or could not be found"
        case .aborted:
            return "The upload operation was aborted"
        case let .error(description):
            return description
        }
    }
}

/// :nodoc:
@objc(FSMultipartUpload) public class MultipartUpload: NSObject {
    typealias UploadProgress = (Int64) -> Void

    // MARK: - Public Properties

    /// The overall upload progress.
    public var progress: Progress

    // MARK: - Internal Properties

    public var uploadProgress: ((Progress) -> Void)?
    public var completionHandler: ((NetworkJSONResponse) -> Void)?

    // MARK: - Private Properties

    private var uploadable: Uploadable
    private var shouldAbort: Bool
    private var totalUploadedBytes: Int64 = 0

    private let queue: DispatchQueue
    private let apiKey: String
    private let options: UploadOptions
    private let security: Security?
    private let uploadQueue: DispatchQueue = DispatchQueue(label: "com.filestack.upload-queue")
    private let maxRetries = 5
    private let uploadOperationUnderlyingQueue = DispatchQueue(label: "com.filestack.upload-operation-queue",
                                                               qos: .utility,
                                                               attributes: .concurrent)
    private let uploadOperationQueue = OperationQueue()

    // MARK: - Lifecyle Functions

    init(using uploadable: Uploadable,
         options: UploadOptions,
         queue: DispatchQueue = .main,
         apiKey: String,
         security: Security? = nil) {
        self.uploadable = uploadable
        self.queue = queue
        self.apiKey = apiKey
        self.options = options
        self.security = security
        self.shouldAbort = false
        self.progress = Progress(totalUnitCount: 0)

        uploadOperationQueue.underlyingQueue = uploadOperationUnderlyingQueue
        uploadOperationQueue.maxConcurrentOperationCount = options.partUploadConcurrency
    }

    // MARK: - Public Functions

    /// Cancels upload.
    @objc public func cancel() {
        uploadQueue.sync {
            shouldAbort = true
            uploadOperationQueue.cancelAllOperations()
        }
        fail(with: MultipartUploadError.aborted)
    }

    /// Starts upload.
    @objc public func start() {
        uploadQueue.async {
            self.doUploadFile()
        }
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in version 3.0. Use start() instead.")
    @objc public func uploadFile() {
        start()
    }
}

private extension MultipartUpload {
    func fail(with error: Error) {
        queue.async {
            self.completionHandler?(NetworkJSONResponse(with: error))
        }
    }

    func updateProgress(uploadedBytes: Int64) {
        progress.completedUnitCount = uploadedBytes

        queue.async {
            self.uploadProgress?(self.progress)
        }
    }

    func doUploadFile() {
        let fileName = options.storeOptions.filename ?? UUID().uuidString
        let mimeType = options.storeOptions.mimeType ?? uploadable.mimeType ?? "text/plain"

        guard let fileSize = uploadable.size, !fileName.isEmpty else {
            fail(with: MultipartUploadError.invalidFile)
            return
        }

        var preferIntelligentIngestion = false

        progress = Progress(totalUnitCount: Int64(fileSize))

        let startOperation = MultipartUploadStartOperation(apiKey: apiKey,
                                                           fileName: fileName,
                                                           fileSize: fileSize,
                                                           mimeType: mimeType,
                                                           storeOptions: options.storeOptions,
                                                           security: security,
                                                           useIntelligentIngestionIfAvailable: options.preferIntelligentIngestion)

        if shouldAbort {
            fail(with: MultipartUploadError.aborted)
            return
        } else {
            uploadOperationQueue.addOperation(startOperation)
        }

        uploadOperationQueue.waitUntilAllOperationsAreFinished()

        // Ensure that there's a response and JSON payload or fail.
        guard let response = startOperation.response, let json = response.json else {
            fail(with: MultipartUploadError.aborted)
            return
        }

        // Did the REST API return an error? Fail and send the error downstream.
        if let apiErrorDescription = json["error"] as? String {
            fail(with: MultipartUploadError.error(description: apiErrorDescription))
            return
        }

        // Ensure that there's an uri, region, and upload_id in the JSON payload or fail.
        guard let uri = json["uri"] as? String,
            let region = json["region"] as? String,
            let uploadID = json["upload_id"] as? String else {
            fail(with: MultipartUploadError.aborted)
            return
        }

        // Detect whether intelligent ingestion is available.
        // The JSON payload should contain an "upload_type" field with value "intelligent_ingestion".
        if let uploadType = json["upload_type"] as? String, uploadType == "intelligent_ingestion" {
            preferIntelligentIngestion = true
        }

        let chunkSize: Int = options.chunkSize

        var part: Int = 0
        var seekPoint: UInt64 = 0
        var partsAndEtags: [Int: String] = [:]

        let beforeCompleteCheckPointOperation = BlockOperation()

        beforeCompleteCheckPointOperation.completionBlock = {
            if self.shouldAbort {
                self.fail(with: MultipartUploadError.aborted)
                return
            } else {
                self.addCompleteOperation(fileName: fileName,
                                          fileSize: fileSize,
                                          mimeType: mimeType,
                                          uri: uri,
                                          region: region,
                                          uploadID: uploadID,
                                          partsAndEtags: partsAndEtags,
                                          preferIntelligentIngestion: preferIntelligentIngestion,
                                          retriesLeft: self.maxRetries)
            }
        }

        // Submit all parts
        while !shouldAbort, seekPoint < fileSize {
            part += 1

            guard let reader = uploadable.reader else {
                self.shouldAbort = true
                continue
            }

            let partOperation = uploadSubmitPartOperation(intelligentIngestion: preferIntelligentIngestion,
                                                          seek: seekPoint,
                                                          reader: reader,
                                                          fileName: fileName,
                                                          fileSize: fileSize,
                                                          part: part,
                                                          uri: uri,
                                                          region: region,
                                                          uploadId: uploadID,
                                                          chunkSize: chunkSize)

            weak var weakPartOperation = partOperation

            let checkpointOperation = BlockOperation {
                guard let partOperation = weakPartOperation else { return }

                if partOperation.didFail {
                    self.shouldAbort = true
                }

                if !preferIntelligentIngestion {
                    if let responseEtag = partOperation.responseEtag {
                        partsAndEtags[partOperation.part] = responseEtag
                    } else {
                        self.shouldAbort = true
                    }
                }

                if self.shouldAbort {
                    self.uploadOperationQueue.cancelAllOperations()
                }
            }

            checkpointOperation.addDependency(partOperation)
            uploadOperationQueue.addOperation(partOperation)
            uploadOperationQueue.addOperation(checkpointOperation)

            beforeCompleteCheckPointOperation.addDependency(partOperation)
            beforeCompleteCheckPointOperation.addDependency(checkpointOperation)

            seekPoint += UInt64(chunkSize)
        }

        uploadOperationQueue.addOperation(beforeCompleteCheckPointOperation)
    }

    func uploadSubmitPartOperation(intelligentIngestion: Bool,
                                   seek: UInt64,
                                   reader: UploadableReader,
                                   fileName: String,
                                   fileSize: UInt64,
                                   part: Int,
                                   uri: String,
                                   region: String,
                                   uploadId: String,
                                   chunkSize: Int) -> MultipartUploadSubmitPartOperation {
        if intelligentIngestion {
            return MultipartIntelligentUploadSubmitPartOperation(seek: seek,
                                                                 reader: reader,
                                                                 fileName: fileName,
                                                                 fileSize: fileSize,
                                                                 apiKey: apiKey,
                                                                 part: part,
                                                                 uri: uri,
                                                                 region: region,
                                                                 uploadID: uploadId,
                                                                 storeOptions: options.storeOptions,
                                                                 chunkSize: chunkSize,
                                                                 chunkUploadConcurrency: options.chunkUploadConcurrency,
                                                                 uploadProgress: uploadProgress)
        } else {
            return MultipartRegularUploadSubmitPartOperation(seek: seek,
                                                             reader: reader,
                                                             fileName: fileName,
                                                             fileSize: fileSize,
                                                             apiKey: apiKey,
                                                             part: part,
                                                             uri: uri,
                                                             region: region,
                                                             uploadID: uploadId,
                                                             chunkSize: chunkSize,
                                                             uploadProgress: uploadProgress)
        }
    }

    func uploadProgress(progress: Int64) {
        totalUploadedBytes += progress
        updateProgress(uploadedBytes: totalUploadedBytes)
    }

    func addCompleteOperation(fileName: String,
                              fileSize: UInt64,
                              mimeType: String,
                              uri: String,
                              region: String,
                              uploadID: String,
                              partsAndEtags: [Int: String],
                              preferIntelligentIngestion: Bool,
                              retriesLeft: Int) {
        let completeOperation = MultipartUploadCompleteOperation(apiKey: apiKey,
                                                                 fileName: fileName,
                                                                 fileSize: fileSize,
                                                                 mimeType: mimeType,
                                                                 uri: uri,
                                                                 region: region,
                                                                 uploadID: uploadID,
                                                                 storeOptions: options.storeOptions,
                                                                 partsAndEtags: partsAndEtags,
                                                                 security: security,
                                                                 preferIntelligentIngestion: preferIntelligentIngestion)

        weak var weakCompleteOperation = completeOperation

        let checkpointOperation = BlockOperation {
            guard let completeOperation = weakCompleteOperation else { return }
            let jsonResponse = completeOperation.response
            let isNetworkError = jsonResponse.response == nil && jsonResponse.error != nil

            // Check for any error response
            if jsonResponse.response?.statusCode != 200 || isNetworkError {
                if retriesLeft > 0 {
                    let delay = isNetworkError ? 0 : pow(2, Double(self.maxRetries - retriesLeft))

                    // Retry in `delay` seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.addCompleteOperation(fileName: fileName,
                                                  fileSize: fileSize,
                                                  mimeType: mimeType,
                                                  uri: uri,
                                                  region: region,
                                                  uploadID: uploadID,
                                                  partsAndEtags: partsAndEtags,
                                                  preferIntelligentIngestion: preferIntelligentIngestion,
                                                  retriesLeft: retriesLeft - 1)
                    }
                } else {
                    self.fail(with: MultipartUploadError.aborted)
                    return
                }
            } else {
                // Return response to the user.
                self.queue.async {
                    self.completionHandler?(jsonResponse)
                }
            }
        }

        checkpointOperation.addDependency(completeOperation)
        uploadOperationQueue.addOperation(completeOperation)
        uploadOperationQueue.addOperation(checkpointOperation)
    }
}
