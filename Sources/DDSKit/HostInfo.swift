/**
 * HostInfo.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/27/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import FoundationEssentials
internal import _CFastDDS

/// An error while getting the host identifier.
internal struct HostIdentifierError: Error {
    /// The reason message.
    internal let message: String
}

/// Gets the host identifier for the current machine. This only works on Linux.
/// - Returns: A hash including the contents of /etc/machine-id (a unique identifier generated at install) and, if available, PCR0 from a TPM.
internal func getHostIdentifer() throws(HostIdentifierError) -> UInt16 {
#if os(Linux)

    var hasher = eprosima.fastdds.MD5()

    // Get the machine id from /etc/machine-id
    let machineIdPath = "/etc/machine-id"
    guard FileManager.default.isReadableFile(atPath: machineIdPath) else {
        throw .init(message: "/etc/machine-id is not readable")
    }
    do {
        let machineId = try String(contentsOfFile: machineIdPath, encoding: .utf8)
        machineId.withCString { cString in
            hasher.update(cString, UInt32(machineId.count))
        }
    } catch {
        throw .init(message: "Failed to read /etc/machine-id")
    }

    // Try to get the TPM PCR0 value
    let tpmPath = "/sys/class/tpm/tpm0/device/pcrs/0"
    if FileManager.default.isReadableFile(atPath: tpmPath) {
        let tpmPcr = try? String(contentsOfFile: tpmPath, encoding: .utf8)
        if let tpmPcr {
            tpmPcr.withCString { cString in
                hasher.update(cString, UInt32(tpmPcr.count))
            }
        }
    }

    hasher.finalize()
    return withUnsafePointer(to: hasher.digest.0) { digestPtr in
        let digestBuffer = UnsafeBufferPointer(start: digestPtr, count: 16)

        var ret_val: UInt16 = 0
        for i in stride(from: 0, to: MemoryLayout.size(ofValue: hasher.digest), by: 2) {
            // Treat the next two bytes as a big-endian uint16_t and
            // hash them into ret_val.
            ret_val ^= UInt16(digestBuffer[i]) << 8 | UInt16(digestBuffer[i + 1])
        }
        return ret_val
    }

#else
    preconditionFailure("getHostIdentifer() is only supported on Linux.")
#endif
}
