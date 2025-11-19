import INCITS_4_1986

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

    /// Validation mode for IRI checking
    public enum ValidationMode {
        /// Lenient validation using basic syntax rules
        case lenient

        /// Strict validation following RFC 3987 character ranges
        case strict
    }
}

// MARK: - Validation

extension RFC_3987 {
    /// Validates if a string is a valid IRI using Foundation-free validation
    ///
    /// - Parameters:
    ///   - string: The string to validate
    ///   - mode: Validation mode (lenient or strict). Default is lenient.
    /// - Returns: true if the string appears to be a valid IRI
    ///
    /// ## Validation Rules
    ///
    /// ### Lenient Mode (Default)
    /// - Must not be empty
    /// - Must contain a scheme (e.g., http:, https:, urn:)
    /// - Basic structural validation
    ///
    /// ### Strict Mode
    /// - All lenient mode rules
    /// - Validates scheme format: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// - Rejects control characters (U+0000 to U+001F, U+007F-U+009F)
    /// - Rejects unencoded space characters
    ///
    /// - Note: For more comprehensive validation using Foundation's URL parser,
    ///   use the Foundation extensions which provide additional validation capabilities.
    public static func isValidIRI(_ string: String, mode: ValidationMode = .lenient) -> Bool {
        // Empty strings are not valid IRIs
        guard !string.isEmpty else { return false }

        // IRIs must have a scheme (e.g., "http:", "https:", "urn:")
        // Scheme is everything before the first ":"
        guard let colonIndex = string.firstIndex(of: ":") else { return false }

        let scheme = String(string[..<colonIndex])

        // Scheme must not be empty
        guard !scheme.isEmpty else { return false }

        // Lenient mode: just check basic structure
        guard mode == .strict else { return true }

        // Strict mode: validate scheme format
        // Per RFC 3987: scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
        // Schemes must be ASCII per RFC 3987 Section 2.2
        guard let firstChar = scheme.first,
              firstChar.isASCIILetter else { return false }

        for char in scheme {
            guard char.isASCIILetter || char.isASCIIDigit || "+-.".contains(char) else {
                return false
            }
        }

        // Check for control characters (U+0000 to U+001F, U+007F-U+009F)
        for scalar in string.unicodeScalars {
            if (scalar.value >= 0x00 && scalar.value <= 0x1F) ||
               (scalar.value >= 0x7F && scalar.value <= 0x9F) {
                return false
            }
        }

        // Check for unencoded spaces
        if string.contains(" ") {
            return false
        }

        return true
    }

    /// Validates if an IRI string represents an HTTP or HTTPS IRI
    ///
    /// - Parameter string: The IRI string to validate
    /// - Returns: true if the IRI has an http or https scheme
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidIRI(string) else { return false }

        return string.hasPrefix("http:") || string.hasPrefix("https:")
    }
}
