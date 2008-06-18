Gem::Specification.new do |s|
  s.name = %q{injour}
  s.version = "0.1.1"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Arun Thampi"]
  s.autorequire = %q{injour}
  s.date = %q{2008-06-18}
  s.default_executable = %q{injour}
  s.description = %q{Publish your statuses over Bonjour. A distributed approach to the In/Out app created by 37Signals.}
  s.email = %q{arun.thampi@gmail.com}
  s.executables = ["injour"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "bin/injour", "lib/injour", "lib/injour/version.rb", "lib/injour.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/arunthampi/injour}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Publish your statuses over Bonjour. A distributed approach to the In/Out app created by 37Signals.}

  s.add_dependency(%q<dnssd>, [">= 0.6.0"])
end
