# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-esx/version"

Gem::Specification.new do |s|
  s.name        = "knife-esx"
  s.version     = Knife::ESX::VERSION
  s.has_rdoc = true
  s.authors     = ["Sergio Rubio", "Massimo Maino"]
  s.email       = ["maintux@gmail.com"]
  s.homepage = "http://github.com/maintux/knife-esx"
  s.summary = "ESX Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.md", "LICENSE" ]
  s.license       = 'Apache 2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "esx", ">= 0.4.4"
  s.add_dependency "terminal-table"
  s.add_dependency "chef", ">= 0.10"
  s.add_dependency "open4"
  s.require_paths = ["lib"]

end
