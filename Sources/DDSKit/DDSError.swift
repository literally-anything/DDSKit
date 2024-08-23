public enum DDSError: Int32, Error {
    case ERROR = 1
    case UNSUPPORTED = 2
    case BAD_PARAMETER = 3
    case PRECONDITION_NOT_MET = 4
    case OUT_OF_RESOURCES = 5
    case NOT_ENABLED = 6
    case IMMUTABLE_POLICY = 7
    case INCONSISTENT_POLICY = 8
    case ALREADY_DELETED = 9
    case TIMEOUT = 10
    case NO_DATA = 11
    case ILLEGAL_OPERATION = 12

    public static let OK = 0

    public static func check(code ret: Int32) throws {
        if (ret != OK) {
            let e = DDSError(rawValue: ret)
            if (e != nil) {
                throw e!
            }
        }
    }
}

public enum DDSKitError: Error {
    case SynchronizationError
}
