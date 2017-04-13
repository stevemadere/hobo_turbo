# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name = 'hobo_turbo'
  s.summary = 'Helpers and utilities that greatly ease the use of Hobo in a rails project'
  s.description = 'Module to include in controllers etc.,  command-line utility scripts.'
  s.email = 'steve@stevemadere.com'
  s.homepage = 'https://github.com/stevemadere/hobo_turbo'
  s.license = 'MIT'
  s.version = '0.0.5'
  s.authors = 'Steve Madere'
  s.files = Dir.glob('{lib}/**/*')
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.2'
  s.add_dependency 'activesupport'
  s.add_dependency 'hobo'
end
