import Foundation

extension RFC_3987 {
    /// An Internationalized Resource Identifier (IRI) as defined in RFC 3987
    ///
    /// IRIs are a complement to URIs (RFC 3986) that allow the use of
    /// Unicode characters from the Universal Character Set (Unicode/ISO 10646).
    ///
    /// IRIs serve as a more user-friendly way to identify resources while
    /// remaining convertible to traditional ASCII-based URIs when needed
    /// for protocol operations.
    ///
    /// For protocol-oriented usage with types like `URL`, see the nested `IRI.Representable` type.
    public struct IRI: Hashable, Sendable, Codable {
        /// Protocol for types that can represent IRIs
        ///
        /// Types conforming to this protocol can be used interchangeably wherever an IRI
        /// is expected, including Foundation's `URL` type.
        ///
        /// Example:
        /// ```swift
        /// func process(iri: any RFC_3987.IRI.Representable) {
        ///     print(iri.iriString)
        /// }
        ///
        /// let url = URL(string: "https://example.com")!
        /// process(iri: url)  // Works!
        /// ```
        public protocol Representable {
            /// The IRI as a string
            var iriString: String { get }
        }
        /// The IRI string
        public let value: String

        /// Creates an IRI from a string with validation
        ///
        /// This initializer validates the IRI and throws an error if invalid.
        /// For a non-throwing alternative, use `init(uncheckedString:)` or `try?`.
        ///
        /// Example:
        /// ```swift
        /// let iri = try RFC_3987.IRI("https://example.com/寿司")
        /// ```
        ///
        /// - Parameter value: The IRI string
        /// - Throws: IRIError.invalidIRI if the string is not a valid IRI
        public init(_ value: String) throws {
            guard RFC_3987.isValidIRI(value) else {
                throw IRIError.invalidIRI(value)
            }
            self.value = value
        }

        /// Creates an IRI from a Foundation URL
        ///
        /// - Parameter url: The URL to convert to an IRI
        public init(url: URL) {
            self.value = url.absoluteString
        }

        /// Creates an IRI from a string without validation (for internal use)
        ///
        /// - Parameter value: The IRI string
        internal init(unchecked value: String) {
            self.value = value
        }

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

        /// Returns a normalized version of this IRI
        ///
        /// Per RFC 3987 Section 5.3, normalization includes:
        /// - Case normalization of scheme and host
        /// - Percent-encoding normalization
        /// - Path segment normalization (removing . and .. segments)
        ///
        /// - Returns: A normalized IRI
        public func normalized() -> IRI {
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

            // Normalize path by removing dot segments (. and ..)
            let path = components.path
            if !path.isEmpty {
                components.path = RFC_3987.removeDotSegments(from: path)
            }

            guard let normalizedURL = components.url else {
                return self
            }

            return IRI(unchecked: normalizedURL.absoluteString)
        }
    }

    // MARK: - Path Normalization

    /// Removes dot segments from a path per RFC 3986 Section 5.2.4
    ///
    /// This algorithm removes "." and ".." segments from paths to produce
    /// a normalized path. For example:
    /// - `/a/b/c/./../../g` → `/a/g`
    /// - `/./a/b/` → `/a/b/`
    ///
    /// - Parameter path: The path to normalize
    /// - Returns: The path with dot segments removed
    ///
    /// - Note: Cyclomatic complexity inherent to RFC 3986 Section 5.2.4 algorithm
    // swiftlint:disable cyclomatic_complexity
    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {
            // A: If the input buffer begins with a prefix of "../" or "./"
            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }
            // B: If the input buffer begins with a prefix of "/./" or "/."
            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }
            // C: If the input buffer begins with a prefix of "/../" or "/.."
            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)
                // Remove the last segment from output
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }
            // D: If the input buffer consists only of "." or ".."
            else if input == "." || input == ".." {
                input = ""
            }
            // E: Move the first path segment to output
            else {
                // Find the next "/" after the first character
                let startIndex = input.index(after: input.startIndex)
                if let slashIndex = input[startIndex...].firstIndex(of: "/") {
                    let segment = String(input[..<slashIndex])
                    output += segment
                    input = String(input[slashIndex...])
                } else {
                    output += input
                    input = ""
                }
            }
        }

        return output
    }
    // swiftlint:enable cyclomatic_complexity

    // MARK: - Validation Functions

    /// Validates if a string is a valid IRI
    ///
    /// This performs basic validation using Foundation's URL validation.
    /// A valid IRI should:
    /// - Be a valid URL according to Foundation
    /// - Have a scheme (e.g., http, https, urn, mailto)
    ///
    /// Note: This is a lenient validation suitable for most use cases.
    /// Full RFC 3987 compliance would require more strict validation
    /// of character ranges and syntax rules.
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string appears to be a valid IRI
    public static func isValidIRI(_ string: String) -> Bool {
        // Empty strings are not valid IRIs
        guard !string.isEmpty else { return false }

        // Try to create a URL from the string
        guard let url = URL(string: string) else { return false }

        // IRI must have a scheme per RFC 3987
        guard url.scheme != nil else { return false }

        return true
    }

    /// Validates if an IRI is a valid HTTP(S) IRI
    ///
    /// - Parameter iri: The IRI to validate
    /// - Returns: true if the IRI is an HTTP or HTTPS IRI
    public static func isValidHTTP(_ iri: any IRI.Representable) -> Bool {
        guard let url = URL(string: iri.iriString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    /// Validates if a string is a valid HTTP(S) IRI
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string is an HTTP or HTTPS IRI
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidIRI(string) else { return false }
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

// MARK: - IRI.Representable Conformance

extension RFC_3987.IRI: RFC_3987.IRI.Representable {
    public var iriString: String {
        value
    }
}

// MARK: - Foundation URL Conformance

extension URL: RFC_3987.IRI.Representable {
    /// The URL as an IRI string
    ///
    /// Foundation's URL type already supports Unicode characters,
    /// making it naturally compatible with IRIs as defined in RFC 3987.
    public var iriString: String {
        absoluteString
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_3987.IRI: ExpressibleByStringLiteral {
    /// Creates an IRI from a string literal without validation
    ///
    /// Example:
    /// ```swift
    /// let iri: RFC_3987.IRI = "https://example.com/path"
    /// ```
    ///
    /// Note: This does not perform validation. For validated creation,
    /// use `try RFC_3987.IRI("string")`.
    public init(stringLiteral value: String) {
        self.init(unchecked: value)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3987.IRI: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_3987.IRI: CustomDebugStringConvertible {
    public var debugDescription: String {
        "IRI(\"\(value)\")"
    }
}
