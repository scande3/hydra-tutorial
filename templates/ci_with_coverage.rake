desc "Run Continuous Integration Suite (tests, coverage, docs)" 
task :ci do 
  Rake::Task["hydra:jetty:config"].invoke

  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 25
  })
  
  Jettywrapper.wrap(jetty_params) do
    Rails.env = "test"
    ENV['COVERAGE'] ||= 'true'
    Rake::Task['rspec'].invoke
  end
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.rspec_opts = ["-c", "-r ./spec/spec_helper.rb"]
end
