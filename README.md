# MarkdownLoggingProxy

Ruby object to wrap your ruby objects when you are trying to figure out how your ruby objects are being called.

## Installation

Meant to be installable as a gem, and also compile-able to a single file for copy+pasting to irb/pry sessions.

### Gem Install

Install the gem and add to the application's Gemfile by executing:

    $ bundle add markdown_logging_proxy

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install markdown_logging_proxy

### Copy+Paste

You can copy the contents of [`dist/markdown_logging_proxy.rb`](dist/markdown_logging_proxy.rb) into a live irb/pry session.

## Usage

Wrap an object in the proxy and tell it where to log and find out a lot about what happens to that object.

```ruby
user = User.find(123)
proxy = MarkdownLoggingProxy.new(target: user, location: "/home/deploy/user_trace.md")
ComplicatedProcess.for_user(proxy)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/carlzulauf/markdown_logging_proxy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/carlzulauf/markdown_logging_proxy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MarkdownLoggingProxy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/carlzulauf/markdown_logging_proxy/blob/main/CODE_OF_CONDUCT.md).
