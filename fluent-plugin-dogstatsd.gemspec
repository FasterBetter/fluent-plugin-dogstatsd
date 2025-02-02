# coding: utf-8
require "fileutils"

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-dogstatsd"
  spec.version       = "0.0.7"
  spec.authors       = ["Ryota Arai"]
  spec.email         = ["ryota.arai@gmail.com"]
  spec.summary       = %q{Fluent plugin for Dogstatsd, that is statsd server for Datadog.}
  spec.homepage      = "https://github.com/ryotarai/fluent-plugin-dogstatsd"
  spec.license       = "MIT"

  FileUtils.cd(File.expand_path('..', __FILE__)) do
    spec.files       = `git ls-files -z`.split("\x0")
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", [">= 0.14.0", "< 2"]
  spec.add_dependency "dogstatsd-ruby", [">= 3.3.0", "< 6"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
end
