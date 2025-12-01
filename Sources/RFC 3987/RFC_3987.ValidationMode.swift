//
//  RFC_3987.ValidationMode.swift
//  swift-rfc-3987
//

extension RFC_3987 {
    /// Validation mode for IRI checking
    public enum ValidationMode: Sendable {
        /// Lenient validation using basic syntax rules
        case lenient

        /// Strict validation following RFC 3987 character ranges
        case strict
    }
}
