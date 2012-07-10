# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis-widgets/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Doug Barth"]
  gem.email         = ["doug@signalhq.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
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
