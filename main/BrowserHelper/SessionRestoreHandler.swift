//
//  SessionRestoreHandler.swift
//  Browser
//
//  Created by Ryu on 2021/06/12.
//
import GCDWebServer

class SessionRestoreHandler {
    static func register(_ webServer: WebServer) {
        // Register the handler that accepts /errors/restore?history=... requests.
        let sessionRestorePath = Bundle.main.path(forResource: "index", ofType: "html")
        let sessionRestoreString = try? String(contentsOfFile: sessionRestorePath!)
        webServer.registerHandlerForMethod("GET", module: "errors", resource: "restore") { request in
            print("genkainada")
            guard let sessionRestorePath = Bundle.main.path(forResource: "index", ofType: "html"), let sessionRestoreString = try? String(contentsOfFile: sessionRestorePath) else {
                print("genkai2")
                return GCDWebServerResponse(statusCode: 404)
            }
            print("genkai")
            return GCDWebServerDataResponse(html: sessionRestoreString)
        }
        // Register the handler that accepts /errors/error.html?url=... requests.
        webServer.registerHandlerForMethod("GET", module: "HTML", resource: "index.html") { request in
            guard let url = request?.url.absoluteURL else {
                return GCDWebServerResponse(statusCode: 404)
            }

            return GCDWebServerDataResponse(redirect: url, permanent: false)
        }
    }
}
