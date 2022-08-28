Gem::Specification.new do |spec|
  spec.name = "markdown_logging_proxy"
  spec.version = "1.0.0"
  spec.authors = ["Carl Zulauf"]
  spec.email = ["carl@linkleaf.com"]

  spec.summary = "Proxy object for debugging"
  spec.description = "Wrap your ruby objects in a proxy to find out what happens to them"
  spec.homepage = "https://github.com/carlzulauf/markdown_logging_proxy"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/carlzulauf/markdown_logging_proxy"
  spec.metadata["changelog_uri"] = "https://github.com/carlzulauf/markdown_logging_proxy/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
