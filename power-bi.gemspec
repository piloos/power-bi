Gem::Specification.new do |s|
  s.name        = 'power-bi'
  s.version     = '2.4.0'
  s.date        = '2024-05-21'
  s.summary     = "Ruby wrapper for the Power BI API"
  s.description = "Ruby wrapper for the Power BI API"
  s.authors     = ["Lode Cools"]
  s.email       = 'lode.cools1@gmail.com'
  s.files       =  Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.homepage    = 'https://github.com/piloos/power-bi'
  s.license     = 'MIT'

  s.add_runtime_dependency 'faraday', '~> 1.0'

  s.add_development_dependency 'webmock', '~> 3.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'oauth2'
end
