# -*- encoding: utf-8 -*-
require "pathname"

lib = File.expand_path("../lib", __FILE__)
$: << lib unless $:.include?(lib)
require "librarian/version"
require "librarian/gem_spec/file_finder"

excludes        = %w(.*/* tmp pkg)
file_finder     = Librarian::GemSpec::FileFinder(__FILE__, excludes)

Gem::Specification.new do |s|
  s.name        = "librarian"
  s.version     = Librarian::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Feldblum"]
  s.email       = ["y_feldblum@yahoo.com"]
  s.homepage    = ""
  s.summary     = %q{Librarian}
  s.description = %q{Librarian}

  s.rubyforge_project = "librarian"

  s.files         = file_finder.files
  s.test_files    = file_finder.test_files
  s.executables   = file_finder.executables
  s.require_paths = ["lib"]

  s.add_dependency "thor", "~> 0.15"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
  s.add_development_dependency "webmock"

  s.add_dependency "chef", ">= 0.10"
  s.add_dependency "highline"
  s.add_dependency "archive-tar-minitar", ">= 0.5.2"
end
