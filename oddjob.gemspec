# coding: utf-8

lib = File.expand_path('./lib', File.dirname( __FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oddjob/version'

Gem::Specification.new do |spec|
  spec.name          = "oddjob"
  spec.version       = OddJob::VERSION
  spec.authors       = ["Mike Fellows"]
  spec.email         = ["Mike.Fellows@shaw.ca"]

  spec.summary       = 'OddJob is simple command line driver web server'
  spec.description   = <<TXT
Oddjob is a simple command line driver web server, written in ruby and
utilizing ruby's built in web server webrick.  It is meant to be a test and
development tool, suitable for static content from a local directory.

Oddjob also provides basic file upload capabilities (single or multi-file
upload).  This includes the ability to save uploaded files locally.

As a stand alone application the server is quick and convenient application
for web developers working with static files.  Or get a copy of the source and
add in new endpoints for simple tests as needed.
TXT

  spec.homepage      = "https://github.com/MCF/oddjob"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
