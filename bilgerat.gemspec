Gem::Specification.new do |s|
  s.name = "bilgerat"
  s.version = '0.1.0'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.9.3'
  s.authors = ["Joseph Shraibman"]
  s.email = ["jshraibman@mdsol.com"]
  s.homepage = "https://github.com/mdsol/bilgerat"
  s.summary = "Cucumber output formatter that sends failure messages to Hipchat"

  s.add_dependency "cucumber", ">= 1.0.0"
  s.add_dependency 'hipchat', '~> 0.7.0'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
 end
