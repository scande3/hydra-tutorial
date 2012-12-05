# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
Bundler::GemHelper.install_tasks

load 'tutorial.thor'

task :create_and_commit_guide do
  HydraTutorial.new.create_guide

  sh "git add hydra-tutorial-guide.md"
  sh "git commit -m 'Updated hydra-tutorial-guide.md'"
  sh "git push"

end

task :build_guide_and_gem  => [:create_and_commit_guide, :build]