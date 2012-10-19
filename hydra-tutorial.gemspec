Gem::Specification.new do |s|
  s.name        = "hydra-tutorial"
  s.version     = "0.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Beer"]
  s.email       = ["hydra-tech@googlegroups.com"]
  s.homepage    = "http://projecthydra.org"
  s.summary     = "Hydra head tutorial walkthrough"
  s.description = "Tutorial that works through setting up a hydra head"
  s.files       = `git ls-files`.split("\n")
  s.executables = ['hydra-tutorial']
  s.add_dependency "thor", "~> 0.15"
  s.add_dependency "rails"
  s.add_dependency "bundler"
end
