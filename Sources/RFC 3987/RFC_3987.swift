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
