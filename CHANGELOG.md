## [Unreleased]

## [0.1.0] - 2022-08-22

- Initial release

## [1.0.0]

- Release of gem to rubygems
- Proxy now defines zero methods besides `method_missing`
- Addition of `bin/example` script

## [1.0.1]

- Add missing CHANGELOG updates
- Commit updates to compiled `dist/` version of library

## [1.0.2]

- Improved log formatting
- Fix to proxy method overwrite behavior

## [1.1.0]

- Don't show object IDs for args arrays. It's confusing.
- BREAKING: Proxies most `Object` methods by default now

## [1.1.1]

- Allow proxying of `nil`
- Add require statements to copy+paste version

## [1.2.0]

- Overwrite as many `Object` methods as we can by default

## [1.3.0]

- Add `inspect_method` configuration option

## [1.3.1]

- Object inspection improvements and fixes
- Implement `inspect_method: :limited` configuration option
