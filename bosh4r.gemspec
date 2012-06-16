# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bosh4r/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ganesh Gunaegaran"]
  gem.email         = ["me@itsgg.com"]
  gem.description   = %q{BOSH ruby client}
  gem.summary       = %q{XMPP BOSH ruby client}
  gem.homepage      = "https://github.com/itsgg/bosh4r"
  gem.add_dependency 'rest-client', '>= 1.6.7'
  gem.add_dependency 'builder', '>= 3.0.0'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bosh4r"
  gem.require_paths = ["lib"]
  gem.version       = Bosh4r::VERSION
end
