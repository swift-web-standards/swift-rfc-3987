
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
        
        /// The IRI string
        public let value: String
    }
}

extension RFC_3987.IRI {
    
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
        /// The IRI representation
        var iri: RFC_3987.IRI { get }
    }
}

extension RFC_3987.IRI {
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
    /// - Throws: IRI.Error.invalidIRI if the string is not a valid IRI
    public init(_ value: String) throws {
        guard RFC_3987.isValidIRI(value) else {
            throw RFC_3987.IRI.Error.invalidIRI(value)
        }
        self.value = value
    }
    
    /// Creates an IRI from a string without validation
    ///
    /// Use this initializer when you have a string that is already known to be a valid IRI,
    /// such as when converting from `IRI.Representable` types or deserializing from trusted sources.
    ///
    /// - Parameter value: The IRI string (should be valid, but not validated)
    ///
    /// Example:
    /// ```swift
    /// let url = URL(string: "https://example.com")!
    /// let iri = RFC_3987.IRI(unchecked: url.absoluteString)
    /// ```
    public init(unchecked value: String) {
        self.value = value
    }
}

extension RFC_3987 {
    
    
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
}

// MARK: - IRI.Representable Protocol Extension

extension RFC_3987.IRI.Representable {
    /// The IRI as a string (convenience)
    public var iriString: String {
        iri.value
    }
}

// MARK: - IRI.Representable Conformance

extension RFC_3987.IRI: RFC_3987.IRI.Representable {
    public var iri: RFC_3987.IRI {
        self
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
