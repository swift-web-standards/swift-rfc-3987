//
//  RFC_3987.IRI.Error.swift
//  swift-rfc-3987
//

extension RFC_3987.IRI {
    /// Errors that can occur when parsing or validating IRIs
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The input was empty
        case empty
        /// The string is not a valid IRI
        case invalidIRI(String)
        /// The string is not a valid URI
        case invalidURI(String)
        /// Conversion between IRI and URI failed
        case conversionFailed(String)
    }
}

extension RFC_3987.IRI.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "IRI cannot be empty"
        case .invalidIRI(let value):
            return "Invalid IRI: '\(value)'"
        case .invalidURI(let value):
            return "Invalid URI: '\(value)'"
        case .conversionFailed(let value):
            return "Failed to convert IRI: '\(value)'"
        }
    }
}
