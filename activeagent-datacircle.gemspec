require_relative 'lib/activeagent/datacircle/version'

Gem::Specification.new do |spec|
  spec.name          = 'activeagent-datacircle'
  spec.version       = ActiveAgent::Datacircle::VERSION
  spec.authors       = ['Wayne Hamadi']
  spec.email         = ['wayne@datacircle.dev']

  spec.summary       = 'Find the best GTM APIs, in Active Agent.'
  spec.description   = 'Four Active Agent tools on Datacircle\'s open API, with no key: list the GTM APIs, the best plans of ' \
                       'one API, a search of every plan and one provider\'s ranks. We benchmark all the GTM APIs and we put ' \
                       'the results on our website: https://datacircle.dev'
  spec.homepage      = 'https://datacircle.dev'
  spec.license       = 'MIT'
  spec.metadata      = {
    'homepage_uri' => 'https://datacircle.dev',
    'source_code_uri' => 'https://github.com/waynehamadi/activeagent-datacircle',
    'documentation_uri' => 'https://github.com/waynehamadi/activeagent-datacircle#readme',
    'bug_tracker_uri' => 'https://github.com/waynehamadi/activeagent-datacircle/issues'
  }

  spec.files         = Dir['LICENSE.txt', 'README.md', 'lib/**/*.rb']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'activeagent', '>= 1.9', '< 2'
end
