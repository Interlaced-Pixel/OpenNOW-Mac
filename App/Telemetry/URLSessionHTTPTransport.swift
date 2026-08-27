import Foundation

public enum URLSessionHTTPTransport {
    public static func send(_ request: URLRequest, operation: String, invalidHTTPResponseError: any Error) async throws -> (Data, HTTPURLResponse) {
        var tracedRequest = request
        let networkStart = NetworkLog.start(&tracedRequest, operation: operation)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: tracedRequest)
        } catch {
            NetworkLog.finish(tracedRequest, operation: operation, startedAt: networkStart, data: nil, response: nil, error: error)
            throw error
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            NetworkLog.finish(tracedRequest, operation: operation, startedAt: networkStart, data: data, response: response, error: invalidHTTPResponseError)
            throw invalidHTTPResponseError
        }
        NetworkLog.finish(tracedRequest, operation: operation, startedAt: networkStart, data: data, response: response, error: nil)
        return (data, httpResponse)
    }
}
