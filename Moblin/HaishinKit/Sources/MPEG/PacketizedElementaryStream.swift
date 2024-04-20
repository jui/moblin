import AVFoundation
import CoreMedia

/**
 - seealso: https://en.wikipedia.org/wiki/Packetized_elementary_stream
 */

enum PESPTSDTSIndicator: UInt8 {
    case none = 0
    case forbidden = 1
    case onlyPTS = 2
    case bothPresent = 3
}

struct PESOptionalHeader {
    static let fixedSectionSize: Int = 3
    static let defaultMarkerBits: UInt8 = 2

    var markerBits: UInt8 = PESOptionalHeader.defaultMarkerBits
    var scramblingControl: UInt8 = 0
    var priority = false
    var dataAlignmentIndicator = false
    var copyright = false
    var originalOrCopy = false
    var ptsDtsIndicator: UInt8 = PESPTSDTSIndicator.none.rawValue
    var esCRFlag = false
    var esRateFlag = false
    var dsmTrickModeFlag = false
    var additionalCopyInfoFlag = false
    var crcFlag = false
    var extentionFlag = false
    var pesHeaderLength: UInt8 = 0
    var optionalFields = Data()
    var stuffingBytes = Data()

    init() {}

    init(data: Data) {
        self.data = data
    }

    mutating func setTimestamp(_ timestamp: CMTime, presentationTimeStamp: CMTime, decodeTimeStamp: CMTime) {
        let base = Double(timestamp.seconds)
        if presentationTimeStamp != CMTime.invalid {
            ptsDtsIndicator |= 0x02
        }
        if decodeTimeStamp != CMTime.invalid {
            ptsDtsIndicator |= 0x01
        }
        if (ptsDtsIndicator & 0x02) == 0x02 {
            let pts = Int64((presentationTimeStamp.seconds - base) * Double(TSTimestamp.resolution))
            optionalFields += TSTimestamp.encode(pts, ptsDtsIndicator << 4)
        }
        if (ptsDtsIndicator & 0x01) == 0x01 {
            let dts = Int64((decodeTimeStamp.seconds - base) * Double(TSTimestamp.resolution))
            optionalFields += TSTimestamp.encode(dts, 0x01 << 4)
        }
        pesHeaderLength = UInt8(optionalFields.count)
    }

    func makeSampleTimingInfo(_ previousPresentationTimeStamp: CMTime) -> CMSampleTimingInfo? {
        var presentationTimeStamp: CMTime = .invalid
        var decodeTimeStamp: CMTime = .invalid
        if ptsDtsIndicator & 0x02 == 0x02 {
            let pts = TSTimestamp.decode(optionalFields, offset: 0)
            presentationTimeStamp = .init(value: pts, timescale: CMTimeScale(TSTimestamp.resolution))
        }
        if ptsDtsIndicator & 0x01 == 0x01 {
            let dts = TSTimestamp.decode(optionalFields, offset: TSTimestamp.dataSize)
            decodeTimeStamp = .init(value: dts, timescale: CMTimeScale(TSTimestamp.resolution))
        }
        return CMSampleTimingInfo(
            duration: presentationTimeStamp - previousPresentationTimeStamp,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: decodeTimeStamp
        )
    }

    var data: Data {
        get {
            var bytes = Data([0x00, 0x00])
            bytes[0] |= markerBits << 6
            bytes[0] |= scramblingControl << 4
            bytes[0] |= (priority ? 1 : 0) << 3
            bytes[0] |= (dataAlignmentIndicator ? 1 : 0) << 2
            bytes[0] |= (copyright ? 1 : 0) << 1
            bytes[0] |= (originalOrCopy ? 1 : 0)
            bytes[1] |= ptsDtsIndicator << 6
            bytes[1] |= (esCRFlag ? 1 : 0) << 5
            bytes[1] |= (esRateFlag ? 1 : 0) << 4
            bytes[1] |= (dsmTrickModeFlag ? 1 : 0) << 3
            bytes[1] |= (additionalCopyInfoFlag ? 1 : 0) << 2
            bytes[1] |= (crcFlag ? 1 : 0) << 1
            bytes[1] |= extentionFlag ? 1 : 0
            return ByteArray()
                .writeBytes(bytes)
                .writeUInt8(pesHeaderLength)
                .writeBytes(optionalFields)
                .writeBytes(stuffingBytes)
                .data
        }
        set {
            let buffer = ByteArray(data: newValue)
            do {
                let bytes: Data = try buffer.readBytes(PESOptionalHeader.fixedSectionSize)
                markerBits = (bytes[0] & 0b1100_0000) >> 6
                scramblingControl = bytes[0] & 0b0011_0000 >> 4
                priority = (bytes[0] & 0b0000_1000) == 0b0000_1000
                dataAlignmentIndicator = (bytes[0] & 0b0000_0100) == 0b0000_0100
                copyright = (bytes[0] & 0b0000_0010) == 0b0000_0010
                originalOrCopy = (bytes[0] & 0b0000_0001) == 0b0000_0001
                ptsDtsIndicator = (bytes[1] & 0b1100_0000) >> 6
                esCRFlag = (bytes[1] & 0b0010_0000) == 0b0010_0000
                esRateFlag = (bytes[1] & 0b0001_0000) == 0b0001_0000
                dsmTrickModeFlag = (bytes[1] & 0b0000_1000) == 0b0000_1000
                additionalCopyInfoFlag = (bytes[1] & 0b0000_0100) == 0b0000_0100
                crcFlag = (bytes[1] & 0b0000_0010) == 0b0000_0010
                extentionFlag = (bytes[1] & 0b0000_0001) == 0b0000_0001
                pesHeaderLength = bytes[2]
                optionalFields = try buffer.readBytes(Int(pesHeaderLength))
            } catch {
                logger.error("\(buffer)")
            }
        }
    }
}

struct PacketizedElementaryStream {
    static let untilPacketLengthSize: Int = 6
    static let startCode = Data([0x00, 0x00, 0x01])

    var startCode: Data = PacketizedElementaryStream.startCode
    var streamID: UInt8 = 0
    var packetLength: UInt16 = 0
    var optionalPESHeader: PESOptionalHeader = .init()
    var data = Data()

    var payload: Data {
        get {
            ByteArray()
                .writeBytes(startCode)
                .writeUInt8(streamID)
                .writeUInt16(packetLength)
                .writeBytes(optionalPESHeader.data)
                .writeBytes(data)
                .data
        }
        set {
            let buffer = ByteArray(data: newValue)
            do {
                startCode = try buffer.readBytes(3)
                streamID = try buffer.readUInt8()
                packetLength = try buffer.readUInt16()
                optionalPESHeader = try PESOptionalHeader(data: buffer.readBytes(buffer.bytesAvailable))
                buffer.position = PacketizedElementaryStream
                    .untilPacketLengthSize + 3 + Int(optionalPESHeader.pesHeaderLength)
                data = try buffer.readBytes(buffer.bytesAvailable)
            } catch {
                logger.error("\(buffer)")
            }
        }
    }

    init?(_ payload: Data) {
        self.payload = payload
        if startCode != PacketizedElementaryStream.startCode {
            return nil
        }
    }

    init?(
        bytes: UnsafePointer<UInt8>,
        count: UInt32,
        presentationTimeStamp: CMTime,
        decodeTimeStamp _: CMTime,
        timestamp: CMTime,
        config: AudioSpecificConfig,
        streamID: UInt8
    ) {
        data.append(contentsOf: config.makeHeader(Int(count)))
        data.append(bytes, count: Int(count))
        optionalPESHeader.dataAlignmentIndicator = true
        optionalPESHeader.setTimestamp(
            timestamp,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: CMTime.invalid
        )
        let length = data.count + optionalPESHeader.data.count
        if length < Int(UInt16.max) {
            packetLength = UInt16(length)
        } else {
            return nil
        }
        self.streamID = streamID
    }

    init(
        bytes: UnsafePointer<UInt8>,
        count: Int,
        presentationTimeStamp: CMTime,
        decodeTimeStamp: CMTime,
        timestamp: CMTime,
        config: AVCDecoderConfigurationRecord?,
        streamID: UInt8
    ) {
        if let config {
            // 3 NAL units. SEI(9), SPS(7) and PPS(8)
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x01, 0x09, 0x10])
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            data.append(contentsOf: config.sequenceParameterSets[0])
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            data.append(contentsOf: config.pictureParameterSets[0])
        } else {
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x01, 0x09, 0x30])
        }
        if let stream = AVCFormatStream(bytes: bytes, count: count) {
            data.append(stream.toByteStream())
        }
        optionalPESHeader.dataAlignmentIndicator = true
        optionalPESHeader.setTimestamp(
            timestamp,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: decodeTimeStamp
        )
        let length = data.count + optionalPESHeader.data.count
        if length < Int(UInt16.max) {
            packetLength = UInt16(length)
        }
        self.streamID = streamID
    }

    init(
        bytes: UnsafePointer<UInt8>,
        count: Int,
        presentationTimeStamp: CMTime,
        decodeTimeStamp: CMTime,
        timestamp: CMTime,
        config: HEVCDecoderConfigurationRecord?,
        streamID: UInt8
    ) {
        if let config {
            if let nal = config.array[.vps] {
                data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
                data.append(nal[0])
            }
            if let nal = config.array[.sps] {
                data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
                data.append(nal[0])
            }
            if let nal = config.array[.pps] {
                data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
                data.append(nal[0])
            }
        }
        if let stream = AVCFormatStream(bytes: bytes, count: count) {
            data.append(stream.toByteStream())
        }
        optionalPESHeader.dataAlignmentIndicator = true
        optionalPESHeader.setTimestamp(
            timestamp,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: decodeTimeStamp
        )
        let length = data.count + optionalPESHeader.data.count
        if length < Int(UInt16.max) {
            packetLength = UInt16(length)
        }
        self.streamID = streamID
    }

    func arrayOfPackets(_ PID: UInt16, PCR: UInt64?) -> [TSPacket] {
        let payload = self.payload
        var packets: [TSPacket] = []

        // start
        var packet = TSPacket(pid: PID)
        if let PCR {
            packet.adaptationField = TSAdaptationField()
            packet.adaptationField!.pcr = TSProgramClockReference.encode(PCR, 0)
            packet.adaptationField!.compute()
        }
        packet.payloadUnitStartIndicator = true
        var position = packet.fill(payload, useAdaptationField: true)
        packets.append(packet)

        // middle
        packet = TSPacket(pid: PID)
        while position <= payload.count - 184 {
            packet.payload = payload[position ..< position + 184]
            packets.append(packet)
            position += 184
        }

        let rest = (payload.count - position) % 184
        switch rest {
        case 0:
            break
        case 183:
            let remain = payload.subdata(in: payload.endIndex - rest ..< payload.endIndex - 1)
            var packet = TSPacket(pid: PID)
            packet.adaptationField = TSAdaptationField()
            packet.adaptationField!.compute()
            _ = packet.fill(remain, useAdaptationField: true)
            packets.append(packet)
            packet = TSPacket(pid: PID)
            packet.adaptationField = TSAdaptationField()
            packet.adaptationField!.compute()
            _ = packet.fill(Data([payload[payload.count - 1]]), useAdaptationField: true)
            packets.append(packet)
        default:
            let remain = payload.subdata(in: payload.count - rest ..< payload.count)
            var packet = TSPacket(pid: PID)
            packet.adaptationField = TSAdaptationField()
            packet.adaptationField!.compute()
            _ = packet.fill(remain, useAdaptationField: true)
            packets.append(packet)
        }

        return packets
    }

    mutating func append(_ data: Data) -> Int {
        self.data.append(data)
        return data.count
    }

    mutating func makeSampleBuffer(
        _ streamType: ESStreamType,
        previousPresentationTimeStamp: CMTime,
        formatDescription: CMFormatDescription?
    ) -> CMSampleBuffer? {
        var blockBuffer: CMBlockBuffer?
        var sampleSizes: [Int] = []
        switch streamType {
        case .h264:
            _ = AVCFormatStream.toNALFileFormat(&data)
            blockBuffer = data.makeBlockBuffer(advancedBy: 0)
            sampleSizes.append(blockBuffer?.dataLength ?? 0)
        case .adtsAac:
            blockBuffer = data.makeBlockBuffer(advancedBy: 0)
            let reader = ADTSReader()
            reader.read(data)
            var iterator = reader.makeIterator()
            while let next = iterator.next() {
                sampleSizes.append(next)
            }
        default:
            break
        }
        var sampleBuffer: CMSampleBuffer?
        var timing = optionalPESHeader.makeSampleTimingInfo(previousPresentationTimeStamp) ?? .invalid
        guard let blockBuffer, CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: sampleSizes.count,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: sampleSizes.count,
            sampleSizeArray: &sampleSizes,
            sampleBufferOut: &sampleBuffer
        ) == noErr else {
            return nil
        }
        return sampleBuffer
    }
}
