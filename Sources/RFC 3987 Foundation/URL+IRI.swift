public import Foundation
public import RFC_3987

extension URL {
    /// Errors that can occur during IRI to URL conversion
    public enum IRIConversionError: Error, CustomStringConvertible {
        case invalidIRI(String)

        public var description: String {
            switch self {
            case .invalidIRI(let iri):
                return
                    "Failed to convert IRI to URL. The IRI '\(iri)' is malformed and could not be converted to a valid URL even after percent-encoding."
            }
        }
    }

    /// Creates a URL from an IRI by converting it to a URI representation
    ///
    /// Per RFC 3987 Section 3.1, IRIs are converted to URIs by percent-encoding
    /// non-ASCII characters. This initializer attempts direct conversion first
    /// (for ASCII-only IRIs) and falls back to percent-encoding if needed.
    ///
    /// - Parameter iri: The IRI to convert to a URL
    /// - Throws: `IRIConversionError.invalidIRI` if the IRI cannot be converted to a valid URL
    /// - Note: This should succeed for all valid RFC 3987 IRIs. Failure indicates a malformed IRI.
    public init(iri: RFC_3987.IRI) throws {
        // Try direct conversion first (for ASCII IRIs)
        if let url = URL(string: iri.value) {
            self = url
            return
        }

        // Apply percent encoding for non-ASCII characters per RFC 3987
        // Combine allowed character sets for different URL components
        var allowedCharacters = CharacterSet.urlFragmentAllowed
        allowedCharacters.formUnion(.urlHostAllowed)
        allowedCharacters.formUnion(.urlPathAllowed)
        allowedCharacters.formUnion(.urlQueryAllowed)

        let encoded =
            iri.value.addingPercentEncoding(
                withAllowedCharacters: allowedCharacters
            ) ?? iri.value

        guard let url = URL(string: encoded) else {
            throw IRIConversionError.invalidIRI(iri.value)
        }

        self = url
    }
}

extension RFC_3987.IRI {
    /// The ASCII-compatible URI string representation of this IRI
    ///
    /// Per RFC 3987 Section 3.1, IRIs can be converted to URIs by
    /// percent-encoding characters that are not allowed in URIs.
    ///
    /// Example:
    /// ```swift
    /// let iri = try RFC_3987.IRI("https://example.com/hello world")
    /// print(iri.uriString) // "https://example.com/hello%20world"
    /// ```
    public var uriString: String {
        // Use Foundation's URL encoding which performs the necessary
        // percent-encoding for characters not allowed in URIs
        guard let url = URL(string: value) else {
            return value
        }

        // Get the absolute string which will be properly encoded
        return url.absoluteString
    }


    /// Creates an IRI from a Foundation URL
    ///
    /// - Parameter url: The URL to convert to an IRI
    public init(url: URL) {
        self.init(unchecked: url.absoluteString)
    }

    /// Returns a normalized version of this IRI using Foundation's URL parsing
    ///
    /// Per RFC 3987 Section 5.3, normalization includes:
    /// - Case normalization of scheme and host
    /// - Percent-encoding normalization
    /// - Path segment normalization (removing . and .. segments)
    ///
    /// - Returns: A normalized IRI
    ///
    /// - Note: This method requires Foundation. For Foundation-free IRI handling,
    ///   use the core RFC_3987.IRI type without this extension.
    public func normalized() -> RFC_3987.IRI {
        guard let url = URL(string: value) else {
            return self
        }

        // Foundation's URL automatically performs many normalizations
        // when created, so we can use its normalized representation
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return self
        }

        // Normalize scheme and host to lowercase
        if let scheme = components.scheme {
            components.scheme = scheme.lowercased()
        }
        if let host = components.host {
            components.host = host.lowercased()
        }

        // Remove default ports
        if let scheme = components.scheme, let port = components.port {
            let defaultPort =
                (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
                    || (scheme == "ftp" && port == 21)
            if defaultPort {
                components.port = nil
            }
        }

        // RFC 3986 Section 6.2.3: Scheme-based normalization
        // For schemes that define empty path equivalent to "/", use "/"
        // Per RFC 7230 Section 2.7.3: HTTP empty path normalized to "/"
        if let scheme = components.scheme,
            ["http", "https"].contains(scheme),
            components.path.isEmpty
        {
            components.path = "/"
        }

        // Normalize path by removing dot segments (. and ..)
        let path = components.path
        if !path.isEmpty {
            components.path = RFC_3987.removeDotSegments(from: path)
        }

        guard let normalizedURL = components.url else {
            return self
        }

        return RFC_3987.IRI(unchecked: normalizedURL.absoluteString)
    }
}


// MARK: - Foundation URL Conformance

extension URL: RFC_3987.IRI.Representable {
    /// The URL as an IRI
    ///
    /// Foundation's URL type already supports Unicode characters,
    /// making it naturally compatible with IRIs as defined in RFC 3987.
    public var iri: RFC_3987.IRI {
        RFC_3987.IRI(unchecked: absoluteString)
    }
}

// MARK: - Foundation-Enhanced Validation

extension RFC_3987 {
    /// Validates if a string is a valid IRI using Foundation's URL parser
    ///
    /// This provides enhanced validation using Foundation's URL parsing capabilities.
    /// For Foundation-free validation, use `RFC_3987.isValidIRI(_:mode:)` from the core module.
    ///
    /// - Parameters:
    ///   - string: The string to validate
    ///   - mode: Validation mode (lenient or strict). Default is lenient.
    /// - Returns: true if the string is a valid IRI according to Foundation
    ///
    /// ## Foundation-Enhanced Validation
    ///
    /// This validation leverages Foundation's robust URL parser which handles:
    /// - Complex URL component parsing
    /// - Internationalized domain names (IDN)
    /// - Various URI/IRI schemes and their specific rules
    /// - Edge cases in URL syntax
    ///
    /// ### Lenient Mode
    /// - Must be parseable by Foundation's URL
    /// - Must have a scheme
    /// - Accepts most real-world IRI formats
    ///
    /// ### Strict Mode
    /// - All lenient mode rules
    /// - Additional RFC 3987 character validation
    /// - Fragment validation
    ///
    /// - Note: For basic validation without Foundation, use the core `isValidIRI` function.
    public static func isValidIRIWithFoundation(
        _ string: String,
        mode: ValidationMode = .lenient
    ) -> Bool {
        // Empty strings are not valid IRIs
        guard !string.isEmpty else { return false }

        // Try to create a URL from the string
        guard let url = URL(string: string) else { return false }

        // IRI must have a scheme per RFC 3987
        guard let scheme = url.scheme else { return false }

        // Strict mode performs additional RFC 3987 validation
        if mode == .strict {
            return validateStrictWithFoundation(string: string, url: url, scheme: scheme)
        }

        return true
    }

    /// Performs strict RFC 3987 validation using Foundation
    private static func validateStrictWithFoundation(string: String, url: URL, scheme: String)
        -> Bool
    {
        // Validate scheme format: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
        let schemePattern = "^[a-zA-Z][a-zA-Z0-9+.-]*$"
        guard scheme.range(of: schemePattern, options: .regularExpression) != nil else {
            return false
        }

        // Check for invalid control characters (U+0000 to U+001F, U+007F to U+009F)
        let controlCharacterRange = CharacterSet.controlCharacters
        if string.rangeOfCharacter(from: controlCharacterRange) != nil {
            return false
        }

        // Check for unencoded space characters (should be percent-encoded in valid IRIs)
        if string.contains(" ") {
            return false
        }

        // Validate that fragment (if present) doesn't contain invalid characters
        if let fragment = url.fragment {
            // Fragment can contain: pchar / "/" / "?"
            // For now, just check it's not empty
            if fragment.isEmpty {
                return false
            }
        }

        return true
    }

    /// Validates if an IRI is a valid HTTP(S) IRI using Foundation's URL parser
    ///
    /// - Parameter iri: The IRI to validate
    /// - Returns: true if the IRI is an HTTP or HTTPS IRI
    ///
    /// - Note: This overload is available when importing the Foundation extensions.
    ///   For Foundation-free validation, use `isValidHTTP(_ string: String)`.
    public static func isValidHTTP(_ iri: any IRI.Representable) -> Bool {
        guard let url = URL(string: iri.iriString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}
