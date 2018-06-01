import Foundation

extension BinaryFloatingPoint {
    /// Return's this floating point's bit width.
    static var bitWidth: Int {
        return exponentBitCount + significandBitCount + 1
    }

    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 32: return .float4
        case 64: return .float8
        default: fatalError("Unsupported floating point bit width: \(Self.bitWidth)")
        }
    }


    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 32: return ._float4
        case 64: return ._float8
        default: fatalError("Unsupported floating point bit width: \(Self.bitWidth)")
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        switch data.storage {
        case .binary(let value):
            switch data.type {
            case .float4: return Self.init(value.makeFloatingPoint(Float.self))
            case .float8: return Self.init(value.makeFloatingPoint(Double.self))
            case .char: return try Self.init(value.makeFixedWidthInteger(Int8.self))
            case .int2: return try Self.init(value.makeFixedWidthInteger(Int16.self))
            case .int4: return try Self.init(value.makeFixedWidthInteger(Int32.self))
            case .int8: return try Self.init(value.makeFixedWidthInteger(Int64.self))
            case .timestamp, .date, .time:
                let date = try Date.convertFromPostgreSQLData(data)
                return Self(date.timeIntervalSinceReferenceDate)
            default:
                throw PostgreSQLError(
                    identifier: "binaryFloatingPoint",
                    reason: "Could not decode \(Self.self) from binary data type: \(data.type)."
                )
            }
        case .text(let string):
            guard let converted = Double(string) else {
                throw PostgreSQLError(identifier: "binaryFloatingPoint", reason: "Could not decode \(Self.self) from string: \(string).")
            }
            return Self(converted)
        case .null: throw PostgreSQLError(identifier: "binaryFloatingPoint", reason: "Could not decode \(Self.self) from `null` data.")
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(Self.postgreSQLDataType, binary: data)
    }
}

extension Double: PostgreSQLDataConvertible { }
extension Float: PostgreSQLDataConvertible { }

extension Data {
    /// Converts this data to a floating-point number.
    internal func makeFloatingPoint<F>(_ type: F.Type = F.self) -> F where F: FloatingPoint {
        return Data(reversed()).unsafeCast()
    }
}


extension FloatingPoint {
    /// Big-endian bytes for this floating-point number.
    internal var data: Data {
        var copy = self
        return .init(bytes: &copy, count:  MemoryLayout<Self>.size)
    }
}
