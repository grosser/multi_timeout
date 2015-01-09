name = "multi_timeout"
require "./lib/#{name}/version"

Gem::Specification.new name, MultiTimeout::VERSION do |s|
  s.summary = "Use multiple timeouts to soft and then hard kill a command"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.executables = ["multi-timeout"]
  s.required_ruby_version = '>= 1.9.3' # Process.spawn is 1.9+
end
