require 'hoe'

$:.unshift './lib'
require 'production_log/analyzer'

Hoe.new 'production_log_analyzer', '1.5.0' do |p|
  p.summary = p.paragraphs_of('README.txt', 1).join ' '
  p.description = p.paragraphs_of('README.txt', 7).join ' '
  p.author = 'Eric Hodel'
  p.email = 'drbrain@segment7.net'
  p.url = p.paragraphs_of('README.txt', 2).join ' '

  p.rubyforge_name = 'seattlerb'

  p.extra_deps << ['rails_analyzer_tools', '>= 1.4.0']
end

