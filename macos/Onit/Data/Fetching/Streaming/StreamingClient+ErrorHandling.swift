//
//  StreamingClient+ErrorHandling.swift
//  Onit
//
//  Created by Kévin Naudin on 04/02/2025.
//

import EventSource

extension StreamingClient {
    
    func convertError(endpoint: any StreamingEndpoint, error: Error) -> Error {
        guard let error = error as? EventSourceError else {
            return error
        }
        
        switch error {
        case .connectionError(let statusCode, let responseData):
            let message = endpoint.getStreamingErrorMessage(data: responseData)
            
            switch statusCode {
            case 400...499:
                let message = message ?? "Client error occurred."
                if statusCode == 401 {
                    return FetchingError.unauthorized(message: message)
                } else if statusCode == 403 {
                    return FetchingError.forbidden(message: message)
                } else if statusCode == 404 {
                    return FetchingError.notFound(message: message)
                } else {
                    return FetchingError.failedRequest(message: message)
                }
            case 500...599:
                let message = message ?? "Server error occurred."
                return FetchingError.serverError(statusCode: statusCode, message: message)
            default:
                let message = message ?? "An unexpected error occurred."
                return FetchingError.failedRequest(message: message)
            }
        default:
            return FetchingError.failedRequest(message: "An unexpected error occurred.")
        }
    }
}
