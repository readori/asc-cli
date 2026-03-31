import Foundation
import Network

/// A minimal HTTP server that streams PNG frames as MJPEG (multipart/x-mixed-replace).
public final class MJPEGServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "mjpeg-server")
    private var connections: [NWConnection] = []
    private let lock = NSLock()

    public let port: UInt16

    public init(port: UInt16 = 8425) throws {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw MJPEGServerError.invalidPort
        }
        self.port = port
        self.listener = try NWListener(using: .tcp, on: nwPort)
    }

    public func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                break
            case .failed(let error):
                print("MJPEG server failed: \(error)")
            default:
                break
            }
        }
        listener.start(queue: queue)
    }

    public func stop() {
        listener.cancel()
        lock.lock()
        for conn in connections {
            conn.cancel()
        }
        connections.removeAll()
        lock.unlock()
    }

    public func sendFrame(_ imageData: Data) {
        let boundary = "--frame\r\n"
        let contentType = "Content-Type: image/png\r\n"
        let contentLength = "Content-Length: \(imageData.count)\r\n\r\n"
        let footer = "\r\n"

        var payload = Data()
        payload.append(Data(boundary.utf8))
        payload.append(Data(contentType.utf8))
        payload.append(Data(contentLength.utf8))
        payload.append(imageData)
        payload.append(Data(footer.utf8))

        lock.lock()
        let activeConnections = connections
        lock.unlock()

        for conn in activeConnections {
            conn.send(content: payload, completion: .contentProcessed { [weak self] error in
                if error != nil {
                    self?.removeConnection(conn)
                }
            })
        }
    }

    public var connectionCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return connections.count
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)

        // Read HTTP request first, then send MJPEG response headers
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard error == nil, let self else {
                connection.cancel()
                return
            }

            // Check if this is a request for /stream or root
            let requestStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

            if requestStr.contains("GET /stream") || requestStr.contains("GET / ") || requestStr.contains("GET / HTTP") {
                self.sendStreamResponse(connection)
            } else if requestStr.hasPrefix("GET") {
                // Serve an HTML page that embeds the stream
                self.sendHTMLPage(connection)
            } else {
                self.sendStreamResponse(connection)
            }
        }
    }

    private func sendStreamResponse(_ connection: NWConnection) {
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=frame\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\n\r\n"

        connection.send(content: Data(headers.utf8), completion: .contentProcessed { [weak self] error in
            if error == nil {
                self?.lock.lock()
                self?.connections.append(connection)
                self?.lock.unlock()
            }
        })
    }

    private func sendHTMLPage(_ connection: NWConnection) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Simulator Stream</title>
            <style>
                body { margin: 0; background: #1a1a2e; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, system-ui; }
                .container { text-align: center; }
                h1 { color: #e0e0e0; font-size: 14px; font-weight: 500; margin-bottom: 12px; letter-spacing: 0.5px; }
                img { max-height: 90vh; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.4); }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Live Simulator Stream</h1>
                <img src="/stream" alt="Simulator Screen">
            </div>
        </body>
        </html>
        """
        let body = Data(html.utf8)
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        var payload = Data(response.utf8)
        payload.append(body)

        connection.send(content: payload, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func removeConnection(_ connection: NWConnection) {
        lock.lock()
        connections.removeAll { $0 === connection }
        lock.unlock()
        connection.cancel()
    }
}

public enum MJPEGServerError: Error, LocalizedError {
    case invalidPort

    public var errorDescription: String? {
        switch self {
        case .invalidPort:
            return "Invalid port number"
        }
    }
}
