//
//  WebServer.swift
//  Browser
//
//  Created by Ryu on 2021/06/12.
//

import UIKit
import GCDWebServer

class WebServer {

    static let instance = WebServer()

    let server = GCDWebServer()

    var base: String {
        return "http://localhost:\(self.server.port)"
    }

    func start() throws {
        guard !self.server.isRunning else {
            return
        }

        try self.server.start(
            options: [
                GCDWebServerOption_Port: 6571,
                GCDWebServerOption_BindToLocalhost: true,
                GCDWebServerOption_AutomaticallySuspendInBackground: true
            ]
        )
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandlerForMethod(_ method: String, module: String, resource: String, handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?) {
        // Prevent serving content if the requested host isn't a whitelisted local host.
        let wrappedHandler = {(request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            guard let request = request else {
                
                return GCDWebServerResponse(statusCode: 403)
            }

            return handler(request)
        }
        server.addHandler(forMethod: method, path: "/\(module)/\(resource)", request: GCDWebServerRequest.self, processBlock: wrappedHandler)
    }

}
