
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rspec/generators/version"

Gem::Specification.new do |spec|
  spec.name          = "rspec-generators"
  spec.version       = RSpec::Generators::VERSION
  spec.authors       = ["Jamie English"]
  spec.email         = ["jamienglish@gmail.com"]

  spec.summary       = %q{Adds generators for RSpec built-in matchers}
  spec.homepage      = "https://github.com/english/rspec-generators"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-expectations", "~> 3.5"
  spec.add_dependency "radagen", "~> 0.3.6"

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "appraisal", "~> 2.2.0"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "pry-byebug", "~> 3.6.0" if RUBY_ENGINE == "ruby"
  spec.add_development_dependency "rspec", "~> 3.5"
end
