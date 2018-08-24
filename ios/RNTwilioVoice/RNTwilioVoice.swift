import Foundation
import TwilioVoice
import AVFoundation
import PushKit
import CallKit
import UIKit
@objc(RNTwilioVoice)
class RNTwilioVoice: RCTEventEmitter ,PKPushRegistryDelegate, TVONotificationDelegate, TVOCallDelegate, CXProviderDelegate {
    //#MARK: Properties
    var callProvider:CXProvider?
    var callController:CXCallController?
    var token: String?
    var pushRegistry: PKPushRegistry?
    var call: TVOCall?
    var deviceToken: String?
    var callInvite: TVOCallInvite?
    var callCompletionCB: ((Bool) -> Void)?
    var callParams:[String:String]?
    //#MARK: React Native Event Functions
    override func supportedEvents() -> [String]! {
        return ["connectionDidConnect", "connectionDidDisconnect", "callRejected", "deviceReady", "deviceNotReady"]; //@RNSEvents
    }
    //#MARK: React Native Module Functions
    @objc func initWithAccessToken(_ token: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        self.token = token
        NotificationCenter.default.addObserver(forName: .UIApplicationWillTerminate, object: nil, queue: nil) {_ in
            self.appWillTerminate()
        }
        let p = PKPushRegistry(queue: DispatchQueue.main)
        p.delegate = self
        p.desiredPushTypes = [PKPushType.voIP]
        pushRegistry = p
        resolve(true)
    }
    @objc func configureCallKit(_ params: [String: Any], resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        let c = CXCallController(queue: DispatchQueue.main)
        callController = c
        if let s = params["appname"] as? String {
            let cpc = CXProviderConfiguration(localizedName: s)
            cpc.maximumCallGroups = 1
            cpc.maximumCallsPerCallGroup = 1
            if let s = params["imageName"] as? String, let i = UIImage(named: s) {
                cpc.iconTemplateImageData = UIImagePNGRepresentation(i)
            }
            if let s = params["ringToneSound"] as? String {
                cpc.ringtoneSound = s
            }
            let cp = CXProvider(configuration: cpc)
            cp.setDelegate(self, queue:nil)
            callProvider = cp
        }
    }
    @objc func connect(_ params: [String: String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        UIDevice.current.isProximityMonitoringEnabled = true
        if let c = call, c.state == TVOCallState.connected {
            c.disconnect()
        }
        let id = UUID()
        callParams = params
        guard let handle = params["To"] as? String else { reject("no_to", "To parameter not specified", nil); return }
        let ch = CXHandle(type: CXHandle.HandleType.generic, value: handle)
        let ca = CXStartCallAction(call: id, handle: ch)
        let ct = CXTransaction(action: ca)
        callController?.request(ct) { error in
            guard error == nil else { reject("connect_error", error!.localizedDescription, error); return }
            let cu = CXCallUpdate()
            cu.remoteHandle = ch
            cu.supportsDTMF = true
            cu.supportsHolding = true
            cu.supportsGrouping = false
            cu.supportsUngrouping = false
            cu.hasVideo = false
            self.callProvider?.reportCall(with: id, updated: cu)
            resolve(true)
        }
    }
    @objc func disconnect(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        UIDevice.current.isProximityMonitoringEnabled = false
        guard let c = call else { reject("no_call", "No call currently active", nil); return }
        let ceca = CXEndCallAction(call: c.uuid)
        let ct = CXTransaction(action: ceca)
        callController?.request(ct) { error in
            guard error == nil else { reject("connect_error", error!.localizedDescription, error); return }
            resolve(true)
        }
    }
    @objc func setMuted(_ muted: Bool, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let c = call else { reject("no_call", "No reference to call", nil); return }
        c.isMuted = muted
        resolve(true)
    }
    @objc func setSpeakerPhone(_ speakerPhone: Bool,resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            if speakerPhone {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            }
        } catch {
            reject("speakerphone_error", "Could nto change speakerphone setting", nil)
            return
        }
        resolve(true)
    }
    @objc func sendDigits(_ digits: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let c = call else { reject("no_call", "No reference to call", nil); return }
        c.sendDigits(digits)
        resolve(true)
    }
    @objc func unregister(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let t = token, let dt = deviceToken else { reject("no_token", "No token passed", nil); return }
        TwilioVoice.unregister(withAccessToken: t, deviceToken: dt) { error in
            guard error == nil else { reject("unregistration_error", error!.localizedDescription, error); return }
            self.token = nil
            self.deviceToken = nil
            resolve(true)
        }
    }
    @objc func getActiveCall(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        var params: [String: Any] = [:]
        if let ci = callInvite {
            params["sid"] = ci.callSid
            params["from"] = ci.from
            params["to"] = ci.to
            switch ci.state {
            case TVOCallInviteState.accepted: params["state"] = "ACCEPTED"
            case TVOCallInviteState.canceled: params["state"] = "CANCELLED"
            case TVOCallInviteState.pending: params["state"] = "PENSDING"
            case TVOCallInviteState.rejected: params["state"] = "REJECTED"
            }
            resolve(params)
        } else if let c = call {
            params["sid"] = c.sid
            params["to"] = c.to
            params["from"] = c.from
            switch c.state {
            case TVOCallState.connected: params["state"] = "CONNECTED"
            case TVOCallState.connecting: params["state"] = "CONNECTING"
            case TVOCallState.disconnected: params["state"] = "DISCONNECTED"
            }
            resolve(params)
        } else { reject("no_call", "No call to report on", nil)}
    }
    //#MARK: Lifecycle Functions
    func appWillTerminate() {
        if  let c = call { c.disconnect() }
    }
    deinit {
        if let cp = callProvider {
            cp.invalidate()
        }
        NotificationCenter.default.removeObserver(self)
    }
    //#MARK PKPushRegistry Delegates
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        guard type == PKPushType.voIP, let t = token, let dt = deviceToken else { return }
        TwilioVoice.unregister(withAccessToken: t, deviceToken: dt)
        deviceToken = nil
        
    }
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, forType type: PKPushType) {
        guard type == PKPushType.voIP , let t = token, let dt = deviceToken else { return }
        TwilioVoice.register(withAccessToken: t, deviceToken: dt) { error in
            if let e = error {
                self.sendEvent(withName: "deviceNotReady", body: ["err": e.localizedDescription])
            } else {
                self.sendEvent(withName: "deviceReady", body: nil)
            }
        }
    }
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        guard type == PKPushType.voIP else { return }
        TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self)
    }
    //#MARK: TVONotification delegates
    func callInviteReceived(_ newCallInvite: TVOCallInvite) {
        if newCallInvite.state == TVOCallInviteState.pending && (callInvite == nil || callInvite?.state != TVOCallInviteState.pending) && call == nil {
            callInvite = newCallInvite
            let ch = CXHandle(type: CXHandle.HandleType.generic, value: newCallInvite.from)
            let cu = CXCallUpdate()
            cu.remoteHandle = ch
            cu.supportsDTMF = true
            cu.supportsHolding = true
            cu.supportsGrouping = false
            cu.supportsUngrouping = false
            cu.hasVideo = false
            callProvider?.reportNewIncomingCall(with: newCallInvite.uuid, update:cu) {error in
                guard error == nil else { return }
                TwilioVoice.configureAudioSession()
            }
        } else if newCallInvite.state == TVOCallInviteState.canceled {
            guard let _ = call else { return }
            handleDisconnect(error: nil)
            callInvite = nil
        }
    }
    func notificationError(_ error: Error) {/* no-op */}
    //#MARK: TVOCall delegates
    func callDidConnect(_ call: TVOCall) {
        self.call = call
        if let cb = callCompletionCB {
            cb(true)
            callCompletionCB = nil
        }
        var params:[String: Any] = [:]
        params["call_sid"] = call.sid
        if call.state == TVOCallState.connecting { params["call_state"] = "CONNECTING" }
        if call.state == TVOCallState.connected { params["call_state"] = "CONNECTED" }
        if let s = call.from { params["call_from"] = s }
        if let s = call.to { params["call_to"] = s }
        sendEvent(withName: "connectionDidConnect", body: params)
    }
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        if let cb = callCompletionCB { cb(false); callCompletionCB = nil }
        handleDisconnect(error: error)
    }
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        handleDisconnect(error: error)
    }
    func handleDisconnect(error: Error?) {
        guard let c = self.call else { return }
        UIDevice.current.isProximityMonitoringEnabled = false
        let ca = CXEndCallAction(call: c.uuid)
        let t = CXTransaction(action: ca)
        callController?.request(t) { error in /* Do nothing */ }
        var params:[String: Any] = [:]
        if let e = error { params["error"] = e.localizedDescription }
        params["call_sid"] = c.sid
        if let s = c.to { params["call_to"] = s }
        if let s = c.from { params["call_from"] = s }
        if c.state == TVOCallState.disconnected { params["call-state"] = "DISCONNECTED" }
        sendEvent(withName: "connectionDidDisconnect", body: params)
    }
    //#MARK CXProvider delegates
    func providerDidBegin(_ provider: CXProvider) { /* no-op */ }
    func providerDidReset(_ provider: CXProvider) {
        TwilioVoice.isAudioEnabled = true
    }
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        TwilioVoice.isAudioEnabled = false
        if let ci = callInvite, ci.state == TVOCallInviteState.pending {
            sendEvent(withName: "callRejected", body: "callRejected")
            ci.reject()
            callInvite = nil
        } else if let c = call {
            c.disconnect()
        }
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard let t = token else { return }
        TwilioVoice.configureAudioSession()
        TwilioVoice.isAudioEnabled = false
        callProvider?.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        call = TwilioVoice.call(t, params: callParams, delegate: self)
        callCompletionCB = { success in
            if success {
                self.callProvider?.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            }
        }
    }
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        TwilioVoice.isAudioEnabled = false
        guard let ci = callInvite else { return }
        call = ci.accept(with: self)
        callInvite = nil
        callCompletionCB = { success in
            if success {
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if let c = call, c.state == TVOCallState.connected {
            c.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {/* no-op */}
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) { /* no-op */}
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) { /* no-op */}
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) { /* no-op */}
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        TwilioVoice.isAudioEnabled = true
    }
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        TwilioVoice.isAudioEnabled = false
    }
}
