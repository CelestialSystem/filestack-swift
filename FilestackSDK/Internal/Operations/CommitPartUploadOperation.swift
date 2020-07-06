//
//  CommitPartUploadOperation.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 7/31/17.
//  Copyright © 2017 Filestack. All rights reserved.
//

import Alamofire
import Foundation

class CommitPartUploadOperation: BaseOperation<HTTPURLResponse> {
    // MARK: - Private Properties

    private let descriptor: UploadDescriptor
    private let part: Int
    private let retries: Int
    private var retrier: TaskRetrier<HTTPURLResponse>?

    // MARK: - Lifecyle

    required init(descriptor: UploadDescriptor, part: Int, retries: Int) {
        self.descriptor = descriptor
        self.part = part
        self.retries = retries

        super.init()
    }

    // MARK: - BaseOperation Overrides

    override func finish(with result: BaseOperation<HTTPURLResponse>.Result) {
        retrier = nil

        super.finish(with: result)
    }
}

// MARK: - Overrides

extension CommitPartUploadOperation {
    override func main() {
        upload()
    }

    override func cancel() {
        super.cancel()

        retrier?.cancel()
    }
}

// MARK: - Private Functions

private extension CommitPartUploadOperation {
    func upload() {
        let uploadURL = URL(string: "multipart/commit", relativeTo: Constants.uploadURL)!

        retrier = .init(attempts: retries, label: uploadURL.relativePath) { (semaphore) -> HTTPURLResponse? in
            var httpURLResponse: HTTPURLResponse?

            UploadService.shared.upload(multipartFormData: self.multipartFormData, url: uploadURL) { response in
                httpURLResponse = response.response
                semaphore.signal()
            }

            semaphore.wait()

            // Validate response.
            let isWrongStatusCode = httpURLResponse?.statusCode != 200
            let isNetworkError = httpURLResponse == nil

            // Check for any error response
            if isWrongStatusCode || isNetworkError {
                return nil
            } else {
                return httpURLResponse
            }
        }

        if let response = retrier?.run() {
            finish(with: .success(response))
        } else {
            finish(with: .failure(.custom("Unable to complete /multipart/commit operation.")))
        }
    }

    func multipartFormData(form: MultipartFormData) {
        form.append(descriptor.config.apiKey, named: "apikey")
        form.append(descriptor.uri, named: "uri")
        form.append(descriptor.region, named: "region")
        form.append(descriptor.uploadID, named: "upload_id")
        form.append(String(descriptor.filesize), named: "size")
        form.append(String(part), named: "part")
        form.append(descriptor.options.storeOptions.location.description, named: "store_location")
    }
}
