# swift-rfc-3987

[![CI](https://github.com/swift-standards/swift-rfc-3987/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-3987/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 3987: Internationalized Resource Identifiers (IRIs)

## Overview

This package provides a Swift implementation of IRIs (Internationalized Resource Identifiers) as defined in [RFC 3987](https://www.ietf.org/rfc/rfc3987.txt). IRIs extend URIs (RFC 3986) to support Unicode characters from the Universal Character Set, allowing resource identifiers to use characters from any language or script.

## Features

- ✅ IRI validation
- ✅ IRI normalization (scheme/host lowercasing, default port removal, path normalization)
- ✅ IRI to ASCII string conversion (percent-encoding)
- ✅ Unicode character support
- ✅ HTTP/HTTPS specific validation
- ✅ Protocol-based design with `IRI.Representable`
- ✅ Foundation `URL` conformance to `IRI.Representable`
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` conformance

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-web-standards/swift-rfc-3987", from: "0.1.0")
]
```

## Usage

### Creating IRIs

```swift
import RFC_3987

// From string literal (no validation)
let iri: RFC_3987.IRI = "https://example.com/path"

// With validation
let validatedIRI = try RFC_3987.IRI("https://example.com/寿司")
print(validatedIRI.value) // "https://example.com/寿司"
```

### Using Foundation URL

Foundation's `URL` type conforms to `IRI.Representable`, allowing seamless interoperability:

```swift
let url = URL(string: "https://example.com")!

// URL conforms to IRI.Representable
func process(iri: any RFC_3987.IRI.Representable) {
    print(iri.iriString)
}

process(iri: url)  // Works!

// URL can be validated as HTTP IRI
RFC_3987.isValidHTTP(url)  // true
```

**Note:** `URL.absoluteString` returns percent-encoded (URI) form, not the original IRI form with Unicode characters. For true IRI preservation, use the `RFC_3987.IRI` struct.

### Validation

```swift
// Validate any IRI string
if RFC_3987.isValidIRI("https://example.com") {
    print("Valid IRI")
}

// Validate HTTP(S) specifically
if RFC_3987.isValidHTTP("https://example.com") {
    print("Valid HTTP IRI")
}

// Validate IRI.Representable types
let url = URL(string: "https://example.com")!
if RFC_3987.isValidHTTP(url) {
    print("Valid HTTP URL")
}
```

### Normalization

```swift
let iri = try RFC_3987.IRI("HTTPS://EXAMPLE.COM:443/path")
let normalized = iri.normalized()
print(normalized.value) // "https://example.com/path"
```

### IRI to ASCII Conversion

```swift
let iri = try RFC_3987.IRI("https://example.com/hello world")
let asciiString = iri.uriString
print(asciiString) // "https://example.com/hello%20world"
```

The `uriString` property provides an ASCII-compatible string representation using percent-encoding.

## IRI vs URI

**IRI (Internationalized Resource Identifier)**
- Allows Unicode characters
- User-friendly for international audiences
- Example: `https://例え.jp/寿司`

**URI (Uniform Resource Identifier)**
- ASCII-only
- Used in protocols and systems
- Example: `https://xn--r8jz45g.jp/%E5%AF%BF%E5%8F%B8`

IRIs can be mapped to ASCII-compatible strings when needed for protocol operations.

## RFC 3987 Compliance

This implementation provides lenient validation suitable for most use cases:
- ✅ Requires scheme (http, https, urn, mailto, etc.)
- ✅ Accepts Unicode characters
- ✅ Performs basic structure validation
- ✅ Normalizes according to RFC 3987 Section 5.3

For production use with strict compliance requirements, consider additional validation.

## Related Packages

- [swift-rfc-4287](https://github.com/swift-standards/swift-rfc-4287) - Swift types for RFC 4287 (Atom Syndication Format)
- [swift-atom](https://github.com/coenttb/swift-atom) - Atom feed generation and XML rendering

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## Related RFCs

- [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt) - Uniform Resource Identifier (URI)
- [RFC 3987](https://www.ietf.org/rfc/rfc3987.txt) - Internationalized Resource Identifiers (IRIs)
- [RFC 4287](https://www.ietf.org/rfc/rfc4287.txt) - Atom Syndication Format

## License & Contributing

Licensed under Apache 2.0.

Contributions welcome! Please ensure:
- All tests pass
- Code follows existing style
- RFC 3987 compliance maintained
