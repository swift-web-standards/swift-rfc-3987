import Testing
import Foundation
@testable import RFC_3987
@testable import RFC_3987_Foundation

@Suite
struct `IRI Validation` {

    @Test
    func `Valid HTTP IRI`() {
        #expect(RFC_3987.isValidIRI("https://example.com"))
        #expect(RFC_3987.isValidIRI("http://example.com/path"))
        #expect(RFC_3987.isValidIRI("https://example.com:8080/path?query=value"))
    }

    @Test
    func `Valid HTTPS IRI`() {
        #expect(RFC_3987.isValidHTTP("https://example.com"))
        #expect(RFC_3987.isValidHTTP("http://example.com"))
        #expect(!RFC_3987.isValidHTTP("ftp://example.com"))
    }

    @Test
    func `Valid URN IRI`() {
        #expect(RFC_3987.isValidIRI("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"))
        #expect(RFC_3987.isValidIRI("urn:isbn:0451450523"))
    }

    @Test
    func `Valid mailto IRI`() {
        #expect(RFC_3987.isValidIRI("mailto:user@example.com"))
    }

    @Test
    func `Invalid IRI - no scheme`() {
        #expect(!RFC_3987.isValidIRI("example.com"))
        #expect(!RFC_3987.isValidIRI("/path/to/resource"))
    }

    @Test
    func `Invalid IRI - empty string`() {
        #expect(!RFC_3987.isValidIRI(""))
    }

    @Test
    func `Unicode characters in IRI`() {
        #expect(RFC_3987.isValidIRI("https://example.com/寿司"))
        #expect(RFC_3987.isValidIRI("https://例え.jp"))
    }
}

@Suite
struct `IRI Creation` {

    @Test
    func `Create IRI from string literal`() {
        let iri: RFC_3987.IRI = "https://example.com"
        #expect(iri.value == "https://example.com")
    }
}

@Suite
struct `IRI Normalization` {

    @Test
    func `Normalize scheme to lowercase`() {
        let iri: RFC_3987.IRI = "HTTPS://example.com"
        let normalized = iri.normalized()
        #expect(normalized.value.hasPrefix("https://"))
    }

    @Test
    func `Normalize host to lowercase`() {
        let iri: RFC_3987.IRI = "https://EXAMPLE.COM"
        let normalized = iri.normalized()
        #expect(normalized.value.contains("example.com"))
    }

    @Test
    func `Remove default HTTP port`() {
        let iri: RFC_3987.IRI = "http://example.com:80/path"
        let normalized = iri.normalized()
        #expect(!normalized.value.contains(":80"))
    }

    @Test
    func `Remove default HTTPS port`() {
        let iri: RFC_3987.IRI = "https://example.com:443/path"
        let normalized = iri.normalized()
        #expect(!normalized.value.contains(":443"))
    }

    @Test
    func `Keep non-default port`() {
        let iri: RFC_3987.IRI = "https://example.com:8080/path"
        let normalized = iri.normalized()
        #expect(normalized.value.contains(":8080"))
    }

    @Test
    func `Remove dot segments from path`() {
        let iri: RFC_3987.IRI = "https://example.com/a/b/c/./../../g"
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/a/g"))
    }

    @Test
    func `Remove leading dot segment`() {
        let iri: RFC_3987.IRI = "https://example.com/./a/b"
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/a/b"))
    }

    @Test
    func `Remove double dot segments`() {
        let iri: RFC_3987.IRI = "https://example.com/a/../b"
        let normalized = iri.normalized()
        #expect(normalized.value.contains("/b"))
        #expect(!normalized.value.contains("/a/"))
    }
}

@Suite
struct `IRI to URI Conversion` {

    @Test
    func `Convert simple IRI to URI`() {
        let iri: RFC_3987.IRI = "https://example.com/path"
        let uri = iri.uriString
        #expect(uri == "https://example.com/path")
    }

    @Test
    func `Convert IRI with spaces`() {
        let iri: RFC_3987.IRI = "https://example.com/hello%20world"
        let uri = iri.uriString
        #expect(uri.contains("%20"))
    }
}

@Suite
struct `URL Conformance to IRI.Representable` {

    @Test
    func `URL conforms to IRI.Representable`() {
        let url = URL(string: "https://example.com/path")!
        let iri: any RFC_3987.IRI.Representable = url
        #expect(iri.iriString == "https://example.com/path")
    }

    @Test
    func `URL with Unicode characters`() {
        // Note: URL.absoluteString returns percent-encoded (URI) form, not IRI form
        let url = URL(string: "https://example.com/寿司")!
        #expect(url.iriString.contains("%E5%AF%BF%E5%8F%B8"))  // percent-encoded "寿司"
    }

    @Test
    func `URL can be validated as HTTP IRI`() {
        let httpURL = URL(string: "https://example.com")!
        let ftpURL = URL(string: "ftp://example.com")!

        #expect(RFC_3987.isValidHTTP(httpURL))
        #expect(!RFC_3987.isValidHTTP(ftpURL))
    }
}
