import enum CxxStdlib.std

public protocol IDLPrimitive {}

extension Int8: IDLPrimitive {}
extension UInt8: IDLPrimitive {}
extension Int16: IDLPrimitive {}
extension UInt16: IDLPrimitive {}
extension Int32: IDLPrimitive {}
extension UInt32: IDLPrimitive {}
extension Int64: IDLPrimitive {}
extension UInt64: IDLPrimitive {}
extension Float: IDLPrimitive {}
extension Double: IDLPrimitive {}
extension Float80: IDLPrimitive {}
extension Bool: IDLPrimitive {}
extension std.string: IDLPrimitive {}
