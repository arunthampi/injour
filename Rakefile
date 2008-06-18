require "date"
require "fileutils"
require "rubygems"
require "rake/gempackagetask"

require "./lib/injour/version.rb"

injour_gemspec = Gem::Specification.new do |s|
  s.name             = "injour"
  s.version          = Injour::VERSION
  s.platform         = Gem::Platform::RUBY
  s.has_rdoc         = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.summary          = "Publish your statuses over Bonjour. A distributed approach to the In/Out app created by 37Signals."
  s.description      = s.summary
  s.authors          = ["Arun Thampi"]
  s.email            = "arun.thampi@gmail.com"
  s.homepage         = "http://github.com/arunthampi/injour"
  s.require_path     = "lib"
  s.autorequire      = "injour"
  s.files            = %w(README.rdoc Rakefile) + Dir.glob("{bin,lib}/**/*")
  s.executables      = %w(injour)
  
  s.add_dependency "dnssd", ">= 0.6.0"
end

Rake::GemPackageTask.new(injour_gemspec) do |pkg|
  pkg.gem_spec = injour_gemspec
end

namespace :gem do
  namespace :spec do
    desc "Update injour.gemspec"
    task :generate do
      File.open("injour.gemspec", "w") do |f|
        f.puts(injour_gemspec.to_ruby)
      end
    end
  end
end

task :install => :package do
  sh %{sudo gem install pkg/injour-#{Injour::VERSION}}
end

desc "Remove all generated artifacts"
task :clean => :clobber_package