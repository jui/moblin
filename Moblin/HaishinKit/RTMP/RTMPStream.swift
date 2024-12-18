import AVFoundation

/// An object that provides the interface to control a one-way channel over a RtmpConnection.
open class RTMPStream: NetStream {
    /// NetStatusEvent#info.code for NetStream
    /// - seealso: https://help.adobe.com/en_US/air/reference/html/flash/events/NetStatusEvent.html#NET_STATUS
    public enum Code: String {
        case bufferEmpty = "NetStream.Buffer.Empty"
        case bufferFlush = "NetStream.Buffer.Flush"
        case bufferFull = "NetStream.Buffer.Full"
        case connectClosed = "NetStream.Connect.Closed"
        case connectFailed = "NetStream.Connect.Failed"
        case connectRejected = "NetStream.Connect.Rejected"
        case connectSuccess = "NetStream.Connect.Success"
        case drmUpdateNeeded = "NetStream.DRM.UpdateNeeded"
        case failed = "NetStream.Failed"
        case multicastStreamReset = "NetStream.MulticastStream.Reset"
        case pauseNotify = "NetStream.Pause.Notify"
        case playFailed = "NetStream.Play.Failed"
        case playFileStructureInvalid = "NetStream.Play.FileStructureInvalid"
        case playInsufficientBW = "NetStream.Play.InsufficientBW"
        case playNoSupportedTrackFound = "NetStream.Play.NoSupportedTrackFound"
        case playReset = "NetStream.Play.Reset"
        case playStart = "NetStream.Play.Start"
        case playStop = "NetStream.Play.Stop"
        case playStreamNotFound = "NetStream.Play.StreamNotFound"
        case playTransition = "NetStream.Play.Transition"
        case playUnpublishNotify = "NetStream.Play.UnpublishNotify"
        case publishBadName = "NetStream.Publish.BadName"
        case publishIdle = "NetStream.Publish.Idle"
        case publishStart = "NetStream.Publish.Start"
        case recordAlreadyExists = "NetStream.Record.AlreadyExists"
        case recordFailed = "NetStream.Record.Failed"
        case recordNoAccess = "NetStream.Record.NoAccess"
        case recordStart = "NetStream.Record.Start"
        case recordStop = "NetStream.Record.Stop"
        case recordDiskQuotaExceeded = "NetStream.Record.DiskQuotaExceeded"
        case secondScreenStart = "NetStream.SecondScreen.Start"
        case secondScreenStop = "NetStream.SecondScreen.Stop"
        case seekFailed = "NetStream.Seek.Failed"
        case seekInvalidTime = "NetStream.Seek.InvalidTime"
        case seekNotify = "NetStream.Seek.Notify"
        case stepNotify = "NetStream.Step.Notify"
        case unpauseNotify = "NetStream.Unpause.Notify"
        case unpublishSuccess = "NetStream.Unpublish.Success"
        case videoDimensionChange = "NetStream.Video.DimensionChange"

        public var level: String {
            switch self {
            case .bufferEmpty:
                return "status"
            case .bufferFlush:
                return "status"
            case .bufferFull:
                return "status"
            case .connectClosed:
                return "status"
            case .connectFailed:
                return "error"
            case .connectRejected:
                return "error"
            case .connectSuccess:
                return "status"
            case .drmUpdateNeeded:
                return "status"
            case .failed:
                return "error"
            case .multicastStreamReset:
                return "status"
            case .pauseNotify:
                return "status"
            case .playFailed:
                return "error"
            case .playFileStructureInvalid:
                return "error"
            case .playInsufficientBW:
                return "warning"
            case .playNoSupportedTrackFound:
                return "status"
            case .playReset:
                return "status"
            case .playStart:
                return "status"
            case .playStop:
                return "status"
            case .playStreamNotFound:
                return "error"
            case .playTransition:
                return "status"
            case .playUnpublishNotify:
                return "status"
            case .publishBadName:
                return "error"
            case .publishIdle:
                return "status"
            case .publishStart:
                return "status"
            case .recordAlreadyExists:
                return "status"
            case .recordFailed:
                return "error"
            case .recordNoAccess:
                return "error"
            case .recordStart:
                return "status"
            case .recordStop:
                return "status"
            case .recordDiskQuotaExceeded:
                return "error"
            case .secondScreenStart:
                return "status"
            case .secondScreenStop:
                return "status"
            case .seekFailed:
                return "error"
            case .seekInvalidTime:
                return "error"
            case .seekNotify:
                return "status"
            case .stepNotify:
                return "status"
            case .unpauseNotify:
                return "status"
            case .unpublishSuccess:
                return "status"
            case .videoDimensionChange:
                return "status"
            }
        }

        func data(_ description: String) -> ASObject {
            [
                "code": rawValue,
                "level": level,
                "description": description,
            ]
        }
    }

    enum ReadyState: UInt8 {
        case initialized
        case open
        case play
        case playing
        case publish
        case publishing
    }

    static let defaultID: UInt32 = 0
    var info = RTMPStreamInfo()
    private(set) var objectEncoding = RTMPConnection.defaultObjectEncoding

    var id: UInt32 = RTMPStream.defaultID
    var readyState: ReadyState = .initialized {
        didSet {
            guard oldValue != readyState else {
                return
            }
            didChangeReadyState(readyState, oldValue: oldValue)
        }
    }

    var audioTimestamp = 0.0
    var audioTimestampZero = -1.0
    var videoTimestamp = 0.0
    var videoTimestampZero = -1.0
    private let muxer = RTMPMuxer()
    private var messages: [RTMPCommandMessage] = []
    private var startedAt = Date()
    private var dispatcher: (any EventDispatcherConvertible)!
    private var audioWasSent = false
    private var videoWasSent = false
    private var dataTimeStamps: [String: Date] = .init()
    private weak var rtmpConnection: RTMPConnection?

    public init(connection: RTMPConnection) {
        rtmpConnection = connection
        super.init()
        dispatcher = EventDispatcher(target: self)
        connection.streams.append(self)
        addEventListener(.rtmpStatus, selector: #selector(on(status:)), observer: self)
        rtmpConnection?.addEventListener(.rtmpStatus, selector: #selector(on(status:)), observer: self)
        if rtmpConnection?.connected == true {
            rtmpConnection?.createStream(self)
        }
    }

    deinit {
        mixer.stopRunning()
        removeEventListener(.rtmpStatus, selector: #selector(on(status:)), observer: self)
        rtmpConnection?.removeEventListener(.rtmpStatus, selector: #selector(on(status:)), observer: self)
    }

    func publish(_ name: String?) {
        // swiftlint:disable:next closure_body_length
        netStreamLockQueue.async {
            guard let name else {
                switch self.readyState {
                case .publish, .publishing:
                    self.close(withLockQueue: false)
                default:
                    break
                }
                return
            }
            if self.info.resourceName == name && self.readyState == .publishing {
                return
            }
            self.info.resourceName = name
            let message = RTMPCommandMessage(
                streamId: self.id,
                transactionId: 0,
                objectEncoding: self.objectEncoding,
                commandName: "publish",
                commandObject: nil,
                arguments: [name, "live"]
            )
            switch self.readyState {
            case .initialized:
                self.messages.append(message)
            default:
                self.readyState = .publish
                self.rtmpConnection?.socket.doOutput(chunk: RTMPChunk(message: message))
            }
        }
    }

    func close() {
        close(withLockQueue: true)
    }

    func send(handlerName: String, arguments: Any?...) {
        netStreamLockQueue.async {
            guard let rtmpConnection = self.rtmpConnection, self.readyState == .publishing else {
                return
            }
            let dataWasSent = self.dataTimeStamps[handlerName] == nil ? false : true
            let timestmap: UInt32 = dataWasSent ?
                UInt32((self.dataTimeStamps[handlerName]?.timeIntervalSinceNow ?? 0) * -1000) :
                UInt32(self.startedAt.timeIntervalSinceNow * -1000)
            let chunk = RTMPChunk(
                type: dataWasSent ? RTMPChunkType.one : RTMPChunkType.zero,
                streamId: RTMPChunk.StreamID.data.rawValue,
                message: RTMPDataMessage(
                    streamId: self.id,
                    objectEncoding: self.objectEncoding,
                    timestamp: timestmap,
                    handlerName: handlerName,
                    arguments: arguments
                )
            )
            let length = rtmpConnection.socket.doOutput(chunk: chunk)
            self.dataTimeStamps[handlerName] = .init()
            self.info.byteCount.mutate { $0 += Int64(length) }
        }
    }

    func createMetaData() -> ASObject {
        var metadata: [String: Any] = [:]
        if mixer.video.device != nil {
            let settings = mixer.video.encoder.settings.value
            metadata["width"] = settings.videoSize.width
            metadata["height"] = settings.videoSize.height
            metadata["framerate"] = mixer.video.frameRate
            switch settings.format {
            case .h264:
                metadata["videocodecid"] = FLVVideoCodec.avc.rawValue
            case .hevc:
                metadata["videocodecid"] = FLVVideoFourCC.hevc.rawValue
            }
            metadata["videodatarate"] = settings.bitRate / 1000
        }
        if mixer.audio.device != nil {
            metadata["audiocodecid"] = FLVAudioCodec.aac.rawValue
            metadata["audiodatarate"] = mixer.audio.codec.outputSettings.bitRate / 1000
            if let sampleRate = mixer.audio.codec.inSourceFormat?.mSampleRate {
                metadata["audiosamplerate"] = sampleRate
            }
        }
        return metadata
    }

    func close(withLockQueue: Bool) {
        if withLockQueue {
            netStreamLockQueue.async {
                self.close(withLockQueue: false)
            }
            return
        }
        guard let rtmpConnection, ReadyState.open.rawValue < readyState.rawValue else {
            return
        }
        readyState = .open
        rtmpConnection.socket?.doOutput(chunk: RTMPChunk(
            type: .zero,
            streamId: RTMPChunk.StreamID.command.rawValue,
            message: RTMPCommandMessage(
                streamId: 0,
                transactionId: 0,
                objectEncoding: objectEncoding,
                commandName: "closeStream",
                commandObject: nil,
                arguments: [id]
            )
        ))
    }

    func onTimeout() {
        info.onTimeout()
    }

    private func didChangeReadyState(_ readyState: ReadyState, oldValue: ReadyState) {
        guard let rtmpConnection else {
            return
        }
        switch oldValue {
        case .playing:
            logger.info("Playing not implemented")
        case .publishing:
            FCUnpublish()
            mixer.stopEncoding()
        default:
            break
        }
        switch readyState {
        case .open:
            info.clear()
            delegate?.streamDidOpen(self)
            for message in messages {
                rtmpConnection.currentTransactionId += 1
                message.streamId = id
                message.transactionId = rtmpConnection.currentTransactionId
                switch message.commandName {
                case "play":
                    self.readyState = .play
                case "publish":
                    self.readyState = .publish
                default:
                    break
                }
                rtmpConnection.socket.doOutput(chunk: RTMPChunk(message: message))
            }
            messages.removeAll()
        case .play:
            logger.info("Play not implemented")
        case .publish:
            startedAt = .init()
            muxer.dispose()
            muxer.delegate = self
            mixer.startRunning()
            videoWasSent = false
            audioWasSent = false
            dataTimeStamps.removeAll()
            FCPublish()
        case .publishing:
            send(handlerName: "@setDataFrame", arguments: "onMetaData", createMetaData())
            mixer.startEncoding(muxer)
        default:
            break
        }
    }

    @objc
    private func on(status: Notification) {
        guard let rtmpConnection else {
            return
        }
        let e = Event.from(status)
        guard let data = e.data as? ASObject, let code = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            readyState = .initialized
            rtmpConnection.createStream(self)
        case RTMPStream.Code.playReset.rawValue:
            readyState = .play
        case RTMPStream.Code.playStart.rawValue:
            readyState = .playing
        case RTMPStream.Code.publishStart.rawValue:
            readyState = .publishing
        default:
            break
        }
    }
}

extension RTMPStream {
    func FCPublish() {
        guard let rtmpConnection, let name = info.resourceName,
              rtmpConnection.flashVer.contains("FMLE/")
        else {
            return
        }
        rtmpConnection.call("FCPublish", responder: nil, arguments: name)
    }

    func FCUnpublish() {
        guard let rtmpConnection, let name = info.resourceName,
              rtmpConnection.flashVer.contains("FMLE/")
        else {
            return
        }
        rtmpConnection.call("FCUnpublish", responder: nil, arguments: name)
    }
}

extension RTMPStream: EventDispatcherConvertible {
    func addEventListener(
        _ type: Event.Name,
        selector: Selector,
        observer: AnyObject? = nil,
        useCapture: Bool = false
    ) {
        dispatcher.addEventListener(type, selector: selector, observer: observer, useCapture: useCapture)
    }

    func removeEventListener(
        _ type: Event.Name,
        selector: Selector,
        observer: AnyObject? = nil,
        useCapture: Bool = false
    ) {
        dispatcher.removeEventListener(type, selector: selector, observer: observer, useCapture: useCapture)
    }

    func dispatch(event: Event) {
        dispatcher.dispatch(event: event)
    }

    func dispatch(_ type: Event.Name, data: Any?) {
        dispatcher.dispatch(type, data: data)
    }
}

extension RTMPStream: RTMPMuxerDelegate {
    func muxer(_: RTMPMuxer, didOutputAudio buffer: Data, withTimestamp: Double) {
        guard let rtmpConnection, readyState == .publishing else {
            return
        }
        let type: FLVTagType = .audio
        let length = rtmpConnection.socket.doOutput(chunk: RTMPChunk(
            type: audioWasSent ? .one : .zero,
            streamId: type.streamId,
            message: RTMPAudioMessage(streamId: id, timestamp: UInt32(audioTimestamp), payload: buffer)
        ))
        audioWasSent = true
        info.byteCount.mutate { $0 += Int64(length) }
        audioTimestamp = withTimestamp + (audioTimestamp - floor(audioTimestamp))
    }

    func muxer(_: RTMPMuxer, didOutputVideo buffer: Data, withTimestamp: Double) {
        guard let rtmpConnection, readyState == .publishing else {
            return
        }
        let type: FLVTagType = .video
        let length = rtmpConnection.socket.doOutput(chunk: RTMPChunk(
            type: videoWasSent ? .one : .zero,
            streamId: type.streamId,
            message: RTMPVideoMessage(streamId: id, timestamp: UInt32(videoTimestamp), payload: buffer)
        ))
        if !videoWasSent {
            logger.debug("first video frame was sent")
        }
        videoWasSent = true
        info.byteCount.mutate { $0 += Int64(length) }
        videoTimestamp = withTimestamp + (videoTimestamp - floor(videoTimestamp))
    }
}
