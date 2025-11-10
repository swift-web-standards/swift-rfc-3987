import Foundation
import Testing

@testable import RFC_3987

@Suite("IRI Validation")
struct IRIValidationTests {

    @Test("Valid HTTP IRI")
    func validHTTP() {
        #expect(RFC_3987.isValidIRI("https://example.com"))
        #expect(RFC_3987.isValidIRI("http://example.com/path"))
        #expect(RFC_3987.isValidIRI("https://example.com:8080/path?query=value"))
    }

    @Test("Valid HTTPS IRI")
    func validHTTPS() {
        #expect(RFC_3987.isValidHTTP("https://example.com"))
        #expect(RFC_3987.isValidHTTP("http://example.com"))
        #expect(!RFC_3987.isValidHTTP("ftp://example.com"))
    }

    @Test("Valid URN IRI")
    func validURN() {
        #expect(RFC_3987.isValidIRI("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"))
        #expect(RFC_3987.isValidIRI("urn:isbn:0451450523"))
    }

    @Test("Valid mailto IRI")
    func validMailto() {
        #expect(RFC_3987.isValidIRI("mailto:user@example.com"))
    }

    @Test("Invalid IRI - no scheme")
    func invalidNoScheme() {
        #expect(!RFC_3987.isValidIRI("example.com"))
        #expect(!RFC_3987.isValidIRI("/path/to/resource"))
    }

    @Test("Invalid IRI - empty string")
    func invalidEmpty() {
        #expect(!RFC_3987.isValidIRI(""))
    }

    @Test("Unicode characters in IRI")
    func unicodeCharacters() {
        #expect(RFC_3987.isValidIRI("https://example.com/寿司"))
        #expect(RFC_3987.isValidIRI("https://例え.jp"))
    }
}

@Suite("IRI Creation")
struct IRICreationTests {

    @Test("Create IRI from string literal")
    func createFromLiteral() {
        let iri: RFC_3987.IRI = "https://example.com"
        #expect(iri.value == "https://example.com")
    }
}

@Suite("IRI Normalization")
struct IRINormalizationTests {

    @Test("Normalize scheme to lowercase")
    func normalizeScheme() throws {
        let iri = try RFC_3987.IRI("HTTPS://example.com")
        let normalized = iri.normalized()
        #expect(normalized.value.hasPrefix("https://"))
    }

    @Test("Normalize host to lowercase")
    func normalizeHost() throws {
        let iri = try RFC_3987.IRI("https://EXAMPLE.COM")
        let normalized = iri.normalized()
        #expect(normalized.value.contains("example.com"))
    }

    @Test("Remove default HTTP port")
    func removeDefaultHTTPPort() throws {
        let iri = try RFC_3987.IRI("http://example.com:80/path")
        let normalized = iri.normalized()
        #expect(!normalized.value.contains(":80"))
    }

    @Test("Remove default HTTPS port")
    func removeDefaultHTTPSPort() throws {
        let iri = try RFC_3987.IRI("https://example.com:443/path")
        let normalized = iri.normalized()
        #expect(!normalized.value.contains(":443"))
    }

    @Test("Keep non-default port")
    func keepNonDefaultPort() throws {
        let iri = try RFC_3987.IRI("https://example.com:8080/path")
        let normalized = iri.normalized()
        #expect(normalized.value.contains(":8080"))
    }

    @Test("Remove dot segments from path")
    func removeDotSegments() throws {
        let iri = try RFC_3987.IRI("https://example.com/a/b/c/./../../g")
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/a/g"))
    }

    @Test("Remove leading dot segment")
    func removeLeadingDot() throws {
        let iri = try RFC_3987.IRI("https://example.com/./a/b")
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/a/b"))
    }

    @Test("Remove double dot segments")
    func removeDoubleDots() throws {
        let iri = try RFC_3987.IRI("https://example.com/a/../b")
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/b"))
        #expect(!normalized.value.contains("/a/"))
    }
}

@Suite("IRI to URI Conversion")
struct IRIToURITests {

    @Test("Convert simple IRI to URI")
    func convertSimple() throws {
        let iri = try RFC_3987.IRI("https://example.com/path")
        let uri = iri.toURI()
        #expect(uri == "https://example.com/path")
    }

    @Test("Convert IRI with spaces")
    func convertWithSpaces() throws {
        let iri = try RFC_3987.IRI("https://example.com/hello%20world")
        let uri = iri.toURI()
        #expect(uri.contains("%20"))
    }
}

@Suite("URL Conformance to IRI.Representable")
struct URLIRIConformanceTests {

    @Test("URL conforms to IRI.Representable")
    func urlConformsToIRI() {
        let url = URL(string: "https://example.com/path")!
        let iri: any RFC_3987.IRI.Representable = url
        #expect(iri.iriString == "https://example.com/path")
    }

    @Test("URL with Unicode characters")
    func urlWithUnicode() {
        // Note: URL.absoluteString returns percent-encoded (URI) form, not IRI form
        let url = URL(string: "https://example.com/寿司")!
        #expect(url.iriString.contains("%E5%AF%BF%E5%8F%B8"))  // percent-encoded "寿司"
    }

    @Test("URL can be validated as HTTP IRI")
    func urlValidation() {
        let httpURL = URL(string: "https://example.com")!
        let ftpURL = URL(string: "ftp://example.com")!

        #expect(RFC_3987.isValidHTTP(httpURL))
        #expect(!RFC_3987.isValidHTTP(ftpURL))
    }
}
