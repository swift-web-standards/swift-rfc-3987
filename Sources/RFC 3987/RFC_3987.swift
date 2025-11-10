import Foundation

/// RFC 3987: Internationalized Resource Identifiers (IRIs)
///
/// This module implements Internationalized Resource Identifiers (IRIs)
/// as specified in RFC 3987. IRIs are a complement to URIs that allow
/// the use of Unicode characters in resource identifiers.
public enum RFC_3987 {
    /// Errors that can occur when working with IRIs
    public enum IRIError: Error, Hashable, Sendable {
        case invalidIRI(String)
        case invalidURI(String)
        case conversionFailed(String)
    }
}

// MARK: - LocalizedError Conformance

extension RFC_3987.IRIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidIRI(let value):
            return "Invalid IRI: '\(value)'. IRIs must have a scheme and follow RFC 3987 syntax."
        case .invalidURI(let value):
            return "Invalid URI: '\(value)'"
        case .conversionFailed(let reason):
            return "IRI conversion failed: \(reason)"
        }
    }
}
