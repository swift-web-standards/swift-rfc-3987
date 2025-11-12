import Foundation

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
