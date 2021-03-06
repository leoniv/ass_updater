# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ass_updater/version'

Gem::Specification.new do |spec|
  spec.name          = "ass_updater"
  spec.version       = AssUpdater::VERSION
  spec.authors       = ["Leonid Vlasov"]
  spec.email         = ["leoniv.vlasov@gmail.com"]

  spec.summary       = %q{Wrapper for 1C configuration updates service}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/leoniv/ass_updater"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip", "~> 1.1"
  spec.add_dependency "nori", "~> 2.6"
  spec.add_dependency "rchardet", "~> 1.6.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
end
