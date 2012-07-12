# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'redis-widgets/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Doug Barth"]
  gem.email         = ["doug@signalhq.com"]
  gem.description   = %q{A collection of Ruby classes that use Redis to implement useful thread safe behavior}
  gem.summary       = %q{A collection of Ruby classes that use Redis to implement useful thread safe behavior}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "redis-widgets"
  gem.require_paths = ["lib"]
  gem.version       = Redis::Widgets::VERSION

  gem.add_dependency 'redis'
  gem.add_dependency 'activesupport'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'mocha'
end
