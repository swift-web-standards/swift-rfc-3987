//
//  File.swift
//  swift-rfc-3987
//
//  Created by Coen ten Thije Boonkkamp on 20/11/2025.
//

/// RFC 3987: Internationalized Resource Identifiers (IRIs)
///
/// This module implements Internationalized Resource Identifiers (IRIs)
/// as specified in RFC 3987. IRIs are a complement to URIs that allow
/// the use of Unicode characters in resource identifiers.
extension RFC_3987.IRI {
    /// Errors that can occur when working with IRIs
    public enum Error: Swift.Error, Hashable, Sendable {
        case invalidIRI(String)
        case invalidURI(String)
        case conversionFailed(String)
    }
}
