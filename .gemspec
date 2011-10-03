# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'ubnt/version'
 
Gem::Specification.new do |s|
  s.name        = "ubbnut"
  s.version     = UBNT::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan Lassoff"]
  s.email       = ["jof@thejof.com"]
  s.homepage    = "http://github.com/jof/ubbnut"
  s.summary     = "A library for programmatically generating configuration for Ubiquiti Wireless devices."
  s.description = "A library for programmatically generating configuration for Ubiquiti Wireless devices."
 
  s.required_rubygems_version = ">= 1.3.6"
 
  #s.add_development_dependency "rspec"
 
  s.files        = Dir.glob("{bin,lib}/**/*")
  #s.executables  = ['bundle']
  s.require_path = 'lib'
end
