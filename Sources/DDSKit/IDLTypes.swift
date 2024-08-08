import CxxStdlib

public protocol IDLType: Hashable {}

extension Int8: IDLType {}
extension UInt8: IDLType {}
extension Int16: IDLType {}
extension UInt16: IDLType {}
extension Int32: IDLType {}
extension UInt32: IDLType {}
extension Int64: IDLType {}
extension UInt64: IDLType {}
extension Float: IDLType {}
extension Double: IDLType {}
extension Float80: IDLType {}
extension Bool: IDLType {}
extension std.string: IDLType {}
