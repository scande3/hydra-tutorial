Gem::Specification.new do |s|
  s.name = "hydra-tutorial"
  s.version = "0.0.9"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chris Beer"]
  s.email = ["hydra-tech@googlegroups.com"]
  s.homepage = "http://projecthydra.org"
  s.summary = "Hydra head tutorial walkthrough"
  s.description = "Tutorial that works through setting up a hydra head"

  s.add_dependency "thor"
  s.add_dependency "rails"
  s.add_dependency "bundler"

  s.files = `git ls-files`.split("\n")
  s.executables = ['hydra-tutorial']
end
