import Testing
import Foundation
@testable import RFC_3987
@testable import RFC_3987_Foundation

@Suite
struct `README Verification` {

    @Test
    func `Creating IRIs - from string literal`() {
        // From README lines 38-39
        let iri: RFC_3987.IRI = "https://example.com/path"

        #expect(iri.value == "https://example.com/path")
    }

    @Test
    func `Creating IRIs - with validation`() throws {
        // From README lines 42-43
        let validatedIRI = try RFC_3987.IRI("https://example.com/寿司")

        #expect(validatedIRI.value == "https://example.com/寿司")
    }

    @Test
    func `Using Foundation URL - IRI.Representable conformance`() {
        // From README lines 51-58
        let url = URL(string: "https://example.com")!

        // URL conforms to IRI.Representable
        func process(iri: any RFC_3987.IRI.Representable) -> String {
            return iri.iriString
        }

        let result = process(iri: url)
        #expect(result == "https://example.com")
    }

    @Test
    func `Using Foundation URL - HTTP validation`() {
        // From README line 61
        let url = URL(string: "https://example.com")!
        let isValid = RFC_3987.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate IRI string`() {
        // From README lines 70-72
        let isValid = RFC_3987.isValidIRI("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate HTTP specifically`() {
        // From README lines 75-77
        let isValid = RFC_3987.isValidHTTP("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate IRI.Representable types`() {
        // From README lines 80-83
        let url = URL(string: "https://example.com")!
        let isValid = RFC_3987.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test
    func `Normalization example`() throws {
        // From README lines 89-91
        let iri = try RFC_3987.IRI("HTTPS://EXAMPLE.COM:443/path")
        let normalized = iri.normalized()

        #expect(normalized.value == "https://example.com/path")
    }

    @Test
    func `URI Conversion example`() throws {
        // From README lines 100-102
        let iri = try RFC_3987.IRI("https://example.com/hello world")
        let asciiString = iri.uriString

        // URL encoding may use + or %20 for spaces
        #expect(asciiString.contains("example.com"))
        #expect(asciiString.contains("hello"))
    }

    @Test
    func `IRI vs URI - IRI with Unicode`() throws {
        // From README line 107 - IRI example
        let iri = try RFC_3987.IRI("https://例え.jp/寿司")

        #expect(iri.value.contains("例え"))
        #expect(iri.value.contains("寿司"))
    }

    @Test
    func `RFC 3987 Compliance - requires scheme`() {
        // From README line 119
        let withScheme = RFC_3987.isValidIRI("https://example.com")
        let withoutScheme = RFC_3987.isValidIRI("example.com")

        #expect(withScheme == true)
        #expect(withoutScheme == false)
    }

    @Test
    func `RFC 3987 Compliance - accepts Unicode`() throws {
        // From README line 120
        let unicodeIRI = try RFC_3987.IRI("https://example.com/日本語")

        #expect(unicodeIRI.value.contains("日本語"))
    }

    @Test
    func `Protocol-based design - IRI.Representable`() {
        // From README line 16-17
        let url = URL(string: "https://test.com")!

        // URL should conform to IRI.Representable
        let representable: any RFC_3987.IRI.Representable = url
        #expect(representable.iriString == "https://test.com")
    }
}
