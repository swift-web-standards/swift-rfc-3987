//
//  File.swift
//  swift-rfc-3987
//
//  Created by Coen ten Thije Boonkkamp on 20/11/2025.
//

extension RFC_3987 {
    /// Validation mode for IRI checking
    public enum ValidationMode {
        /// Lenient validation using basic syntax rules
        case lenient

        /// Strict validation following RFC 3987 character ranges
        case strict
    }
}
