# -*- encoding: utf-8 -*-
require File.expand_path('../lib/roborabb/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Shay"]
  gem.email         = ["hello@xaviershay.com"]
  gem.description   = %q{Algorithmically generate practice drum scores}
  gem.summary       = %q{
    Algorithmically generate practice drum scores. Customize algorithms with
    ruby with an archaeopteryx-inspired style, output to lilypond format.
  }
  gem.homepage      = "http://github.com/xaviershay/roborabb"

  gem.executables   = []
  gem.files         = Dir.glob("{spec,lib}/**/*.rb") + %w(
                        README.md
                        HISTORY.md
                        Rakefile
                        roborabb.gemspec
                      )
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.name          = "roborabb"
  gem.require_paths = ["lib"]
  gem.version       = Roborabb::VERSION
  gem.has_rdoc      = false
  gem.add_development_dependency 'rspec', '~> 2.0'
  gem.add_development_dependency 'rake'
end
