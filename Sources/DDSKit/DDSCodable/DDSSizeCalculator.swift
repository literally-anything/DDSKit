/**
 * CDRSizeCalculator.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/27/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A calculator for determining the size of a DDS encoded type.
/// This is used to determine the size of the serialized data before it is encoded.
public struct DDSSizeCalculator: ~Copyable {
    /// The internal calculator used to determine the size.
    internal var calc: FastDDS.CDR.CdrSizeCalculator
    /// The size of the serialized data. This is updated as members are added.
    public var size: Int = 0
    /// The current alignment of the data. This is updated as members are added.
    public var alignment: Int = 0

    /// When a sequence member is serialized, this is set to the size of the serialized member.
    @usableFromInline
    internal var serializedSequenceMemberSize: FastDDS.CDR.SerializedMemberSizeForNextInt {
        get {
            .init(rawValue: calc.serialized_member_size_.rawValue).unsafelyUnwrapped
        }
        set {
            calc.serialized_member_size_ = .init(rawValue: newValue.rawValue)
        }
    }

    /// Create a new size calculator copying the internal calculator, but with a new alignment and size.
    /// - Parameters:
    ///   - calc: The calculator to copy.
    ///   - alignment: The new alignment to use.
    @usableFromInline
    internal init(copying calc: borrowing DDSSizeCalculator, alignment: Int = 0) {
        self.calc = calc.calc
        self.alignment = alignment
    }
}

extension DDSSizeCalculator {
    /// The alignment for types equal or greater than 64bits.
    @inline(__always)
    internal var align64: Int { 4 }

    @inline(__always)
    internal static func getAlignment(currentAlignment: Int, dataSize: Int) -> Int {
        (dataSize - (currentAlignment % dataSize)) & (dataSize - 1)
    }
}

extension DDSSizeCalculator {
    /// Indicates that a new type will be calculated.
    /// - Returns: The previous encoding algorithm. Should be passed to `endStruct` when the struct is finished.
    private mutating func beginStruct() -> eprosima.fastcdr.EncodingAlgorithmFlag {
        let previousEncoding = calc.get_encoding()

        size += calc.begin_calculate_type_serialized_size(
            calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 ? eprosima.fastcdr.DELIMIT_CDR2 : eprosima.fastcdr.PLAIN_CDR,
            &alignment
        )

        return previousEncoding
    }
    /// Indicates that the current type has finished being calculated.
    /// - Parameter previousEncoding: The previous encoding algorithm before the struct was started.
    private mutating func endStruct(previousEncoding: consuming eprosima.fastcdr.EncodingAlgorithmFlag) {
        size += calc.end_calculate_type_serialized_size(previousEncoding, &alignment)
    }

    /// Calculate the size of a new structure.
    /// All members added within the body will be included in the size calculation for this struct.
    /// - Parameter body: The function to call to calculate the size of the struct.
    public mutating func withStruct(_ body: (inout DDSSizeCalculator) -> Void) {
        let previousEncoding = beginStruct()
        body(&self)
        endStruct(previousEncoding: previousEncoding)
    }
}

extension DDSSizeCalculator {
    /// Start calculating the size of a member.
    /// This should be called before adding a member to the size calculator.
    /// - Warning: This is only intended to be used internally.
    @usableFromInline
    internal mutating func setupMemberAdd() -> Int {
        let initialAlignment = alignment

        if calc.get_encoding() == eprosima.fastcdr.PL_CDR || calc.get_encoding() == eprosima.fastcdr.PL_CDR2 {
            // Align to 4 for the XCDR header before calculating the data serialized size.
            alignment += Self.getAlignment(currentAlignment: alignment, dataSize: 4)
        }

        let prevSize = alignment - initialAlignment

        if calc.get_encoding() == eprosima.fastcdr.PL_CDR {
            alignment = 0
        }

        return prevSize
    }
    /// Add extra size to the member based on the calculated size.
    /// This should be called after adding a member to the size calculator.
    /// - Warning: This is only intended to be used internally.
    /// - Parameters:
    ///   - memberId: The id of the member being added.
    ///   - prevSize: The size of the member before the data was added.
    ///   - calculatedSize: The size of the member after the data was added.
    @usableFromInline
    internal mutating func addMemberExtraSize(memberId: UInt32, prevSize: Int, calculatedSize: inout Int) {
        var extraSize = 0
        if calculatedSize > 0 {
            if calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 && calc.get_encoding() == eprosima.fastcdr.PL_CDR2 {
                if calculatedSize > 8 || (calculatedSize != 1 && calculatedSize != 2 && calculatedSize != 4 && calculatedSize != 8) {
                    extraSize = 8 // Long EMHEADER.
                    if serializedSequenceMemberSize != .NO_SERIALIZED_MEMBER_SIZE {
                        // If no data has been calculated
                        calculatedSize -= 4; // Join NEXTINT and DHEADER.
                    }
                } else {
                    extraSize = 4 // EMHEADER;
                }
            } else if calc.get_cdr_version() == eprosima.fastcdr.XCDRv1 && calc.get_encoding() == eprosima.fastcdr.PL_CDR {
                extraSize = 4 // ShortMemberHeader

                if memberId > 0x3F00 || calculatedSize > UInt16.max {
                    extraSize += 8 // LongMemberHeader
                }
            }
        }

        calculatedSize += prevSize + extraSize
        if calc.get_encoding() != eprosima.fastcdr.PL_CDR {
            alignment += extraSize
        }
    }

    /// Add a member to the size calculator.
    /// This is a generic method that will work for any `DDSCodable` type.
    /// - Parameters:
    ///   - memberId: The id of the member being added.
    ///   - value: The value of the member being added.
    @inlinable
    public mutating func add<T: DDSCodable>(member memberId: UInt32, _ value: borrowing T) {
        let prevSize = setupMemberAdd()

        var sizeCalculator = DDSSizeCalculator(copying: self, alignment: alignment)
        value.calculateDDSSize(calculator: &sizeCalculator)

        alignment = sizeCalculator.alignment

        addMemberExtraSize(memberId: memberId, prevSize: prevSize, calculatedSize: &sizeCalculator.size)

        size += sizeCalculator.size

        serializedSequenceMemberSize = .NO_SERIALIZED_MEMBER_SIZE
    }
}

extension DDSSizeCalculator {
    /// Setup the size calculator for an optional member.
    /// This should be called before adding an optional member to the size calculator.
    /// - Warning: This is only intended to be used internally.
    /// - Parameters:
    ///   - hasData: Indicates if the optional member has data.
    @usableFromInline
    internal mutating func setupOptionalMemberAdd(hasData: Bool) -> Int {
        let initialAlignment = alignment

        if calc.get_cdr_version() != eprosima.fastcdr.XCDRv2 || calc.get_encoding() == eprosima.fastcdr.PL_CDR2 {
            if hasData || calc.get_encoding() == eprosima.fastcdr.PLAIN_CDR {
                // Align to 4 for the XCDR header before calculating the data serialized size.
                alignment += Self.getAlignment(currentAlignment: alignment, dataSize: 4)
            }
        }

        let prevSize = alignment - initialAlignment

        if calc.get_cdr_version() == eprosima.fastcdr.XCDRv1 && (hasData || calc.get_encoding() == eprosima.fastcdr.PLAIN_CDR) {
            alignment = 0
        }

        return prevSize
    }
    /// Add extra size to the optional member based on the calculated size.
    /// This should be called after adding an optional member to the size calculator.
    /// - Warning: This is only intended to be used internally.
    /// - Parameters:
    ///   - memberId: The id of the member being added.
    ///   - prevSize: The size of the member before the data was added.
    ///   - calculatedSize: The size of the member after the data was added.
    @usableFromInline
    internal mutating func addOptionalMemberExtraSize(memberId: UInt32, prevSize: Int, calculatedSize: inout Int) {
        var extraSize = 0

        if calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 && calc.get_encoding() == eprosima.fastcdr.PL_CDR2 && calculatedSize > 0 {
            if calculatedSize > 8 {
                extraSize = 8 // Long EMHEADER.
                    if serializedSequenceMemberSize != .NO_SERIALIZED_MEMBER_SIZE {
                        // If no data has been calculated
                        calculatedSize -= 4; // Join NEXTINT and DHEADER.
                    }
            } else {
                extraSize = 4 // EMHEADER;
            }
        } else if calc.get_cdr_version() == eprosima.fastcdr.XCDRv1 && (calculatedSize > 0 || calc.get_encoding() == eprosima.fastcdr.PLAIN_CDR) {
            extraSize = 4 // ShortMemberHeader

            if memberId > 0x3F00 || calculatedSize > UInt16.max {
                extraSize += 8 // LongMemberHeader
            }
        }

        calculatedSize += prevSize + extraSize
        if calc.get_cdr_version() != eprosima.fastcdr.XCDRv1 {
            alignment += extraSize
        }
    }
    /// Add an is_present boolean for the optional member if necessary.
    /// This should be called after adding an optional member to the size calculator.
    /// - Warning: This is only intended to be used internally.
    /// - Returns: The added size for the is_present boolean.
    @usableFromInline
    internal mutating func addOptionalIsPresent() -> Int {
        if calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 && calc.get_encoding() != eprosima.fastcdr.PL_CDR2 {
            // Take into account the boolean is_present;
            alignment += 1
            return 1
        }

        return 0
    }

    /// Add an optional member to the size calculator.
    /// This is a generic method that will work for any optional `DDSCodable` type.
    /// - Parameters:
    ///   - memberId: The id of the member being added.
    ///   - value: The value of the member being added.
    @inlinable
    public mutating func add<T: DDSCodable>(member memberId: UInt32, _ value: borrowing T?) {
        let hasData = value != nil
        let prevSize = setupOptionalMemberAdd(hasData: hasData)

        let isPresentSize = addOptionalIsPresent()

        var sizeCalculator = DDSSizeCalculator(copying: self, alignment: alignment)
        if hasData {
            value.unsafelyUnwrapped.calculateDDSSize(calculator: &sizeCalculator)
        }

        alignment = sizeCalculator.alignment

        addOptionalMemberExtraSize(memberId: memberId, prevSize: prevSize, calculatedSize: &sizeCalculator.size)

        size += sizeCalculator.size + isPresentSize
    }
}

extension DDSSizeCalculator {
    /// Initialize a new size calculator.
    /// - Parameter useXCDR2: Indicates if the calculator should use XCDR2 over XCDR1.
    public init(useXCDR2: Bool = true) {
        calc = FastDDS.CDR.CdrSizeCalculator(useXCDR2 ? eprosima.fastcdr.XCDRv2 : eprosima.fastcdr.XCDRv1)
    }

    /// Calculate the size of a primitive type.
    /// - Parameters:
    ///   - value: The value to calculate the size of.
    ///   - useXCDR2: Indicates if the calculator should use XCDR2 over XCDR1.
    /// - Returns: The size of the primitive type.
    internal static func calculateSize<T: DDSCodable>(primitive value: borrowing T, useXCDR2: Bool = true) -> UInt32 {
        var calculator = DDSSizeCalculator(useXCDR2: useXCDR2)

        value.calculateDDSSize(calculator: &calculator)

        return UInt32(calculator.size)
    }

    /// Calculate the size of a `DDSCodable` type.
    /// - Parameters:
    ///   - value: The value to calculate the size of.
    ///   - useXCDR2: Indicates if the calculator should use XCDR2 over XCDR1.
    /// - Returns: The calculated size of the `DDSCodable` type.
    @inlinable
    public static func calculateSize<T: DDSCodable>(_ value: borrowing T, useXCDR2: Bool = true) -> UInt32 {
        var calculator = DDSSizeCalculator(useXCDR2: useXCDR2)

        value.calculateDDSSize(calculator: &calculator)

        calculator.size += 4 // Encapsulation
        return UInt32(calculator.size)
    }
}
