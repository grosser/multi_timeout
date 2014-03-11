$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
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
  cert = File.expand_path("~/.ssh/gem-private-key-grosser.pem")
  if File.exist?(cert)
    s.signing_key = cert
    s.cert_chain = ["gem-public_cert.pem"]
  end
end
