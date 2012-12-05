#! /usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'
require 'rails/generators/actions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'
require 'fileutils'
require 'yaml'
require 'set'
require 'i18n'

# Colors used in messages to the user.
STATEMENT = Thor::Shell::Color::YELLOW
QUESTION  = Thor::Shell::Color::GREEN
WAIT      = Thor::Shell::Color::CYAN
WARNING   = Thor::Shell::Color::RED

I18n.load_path += Dir[File.join(File.dirname(__FILE__),'config','locales','*.yml')]

####
# Some utility methods used by the tutorial.
####

module HydraTutorialHelpers

  @@conf = nil

  # Runs the Rails console for the user.
  def rails_console
    return if @@conf.quick
    say I18n.t('helpers.rails_console.start'), STATEMENT
    say I18n.t('helpers.rails_console.stop'), WAIT
    run "rails c"
  end

  # Runs the Rails server for the user, optionally
  # directing their attention to a particular URL.
  def rails_server url = '/'
    return if @@conf.quick
    say I18n.t('helpers.rails_server.start',:url=>url), STATEMENT
    say I18n.t('helpers.rails_server.stop'), WAIT
    run "rails s"
  end

  # Offers the user a continue prompt. This is relevant only if
  # the user is running all steps at once rather than one by one.
  def continue_prompt
    return if @@conf.quick
    return unless @@conf.run_all
    ask I18n.t('helpers.continue'), WAIT
  end

  # Takes a commit message an an optional array of git commands.
  # Runs either the given commands or the default commands.
  def run_git(msg, *cmds)
    return if @@conf.no_git
    cmds = ['add -A', 'commit -m'] if cmds.size == 0
    cmds.each do |cmd|
      cmd += " '#{msg}'" if cmd =~ /^commit/
      run "git #{cmd}", :capture => false
    end
  end

  # get the say string for the calling method using i18n gem
  def user_message(*params)
    vals=params[0]
    method=caller[0][/`.*'/][1..-2]
    key = "steps.#{method}"
    key << ".#{vals[:substep]}" if (!vals.nil? && vals.include?(:substep))
    I18n.t(key,vals) + "\n"
  end

  # collect all the keys from the translation file
  def collect_keys(scope, translations)
    full_keys = []
    translations.to_a.each do |key, translations|
      new_scope = scope.dup << key
      if translations.is_a?(Hash)
        full_keys += collect_keys(new_scope, translations)
      else
        full_keys << new_scope.join('.')
      end
    end
    return full_keys
  end
  
end


####
# The tutorial contains the following major components:
#
#   - A couple of class methods to define the steps in the tutorial.
#     Each step is a Thor task.
#
#   - A main() task. This is the task invoked when the user runs
#     the bin/hydra-tutorial script. It's job is to determine
#     the which steps to run (either the next step in the process
#     or the specific steps requested on the command line). As
#     the main() task invokes those other tasks, it also persists
#     information to a YAML file to keep track of the user's
#     progress through the tutorial.
#
#   - The other tasks: these are the steps in the tutorial, defined
#     in the order that they should be run.
#
####

class HydraTutorial < Thor

  include Thor::Actions
  include Rails::Generators::Actions
  include HydraTutorialHelpers

  # Returns an array of task names for the tasks that
  # constituting the steps in the tutorial.
  def self.tutorial_tasks
    return tasks.keys.reject { |t| t == 'main' || t =='create_guide' }
  end

  # Returns a set of task names for the tasks that should not
  # be run inside the Rails application directory.
  def self.outside_tasks
    return Set.new(%w(
      welcome
      install_ruby
      install_bundler_and_rails
      new_rails_app
    ))
  end

  # Returns array of directory paths used by Thor to find
  # source files when running copy_file().
  def self.source_paths
    [@@conf.templates_path]
  end

  ####
  # The main task that is invoked by the gem's executable script.
  #
  # This task invokes either the next task in the tutorial or
  # the task(s) explicitly requested by the user.
  ####

  # Define a Struct that we will use hold some global values we need.
  # An instance of this Struct will be kept in @@conf.
  HTConf = Struct.new(
    # Command-line options.
    :run_all,        # If true, run all remaining tasks rather than only the next task.
    :thru,           # Implies :run_all and stores name of last task to be run.
    :quick,          # If true, bypass interactive user confirmations.
    :reset,          # If true, reset the tutorial back to the beginning.
    :gems_from_git,  # If true, get a couple of gems directly from github.
    :debug_steps,    # If true, just print task names rather than running tasks.
    :no_git,         # If true, do not create Git commits as the Rails app is modified.
    :diff,           # If true, run git diff: previous vs. current code.
    :app,            # Name of the Rails application's subdirectory.

    # Other config.
    :progress_file,  # Name of YAML file used to keep track of finished steps.
    :done,           # Array of tasks that have been completed already.
    :templates_path  # Directory where Thor can file source files for copy_file().
  )

  desc('create_guide: FIX', 'FIX')
  def create_guide    
    
    HydraTutorial.initialize_config(options)
    params={:conf_app=>@@conf.app} # interpolations we will just pass into every translations
    
    guide_output_filename=File.join(Dir.pwd, 'hydra-tutorial-guide.md') # guide output filename
    
    I18n.backend.send(:init_translations)
    # Get all keys from all locales
    all_keys = I18n.backend.send(:translations).collect do |check_locale, translations|
      collect_keys([], translations)
    end.uniq.flatten
    prev_title=''
    
    File.open(guide_output_filename, 'w') do |file|  
      file.puts "# HYDRA TUTORIAL GUIDE"
      file.puts "_auto generated on #{Time.now}_"
      file.puts ""
      counter=1
      step_keys=all_keys.each do |key|
        if key.include?('steps.') # only print out the keys containing steps
          key_split=key.split('.') # split key into parts
          title=key_split[1].split("_").map {|word| word.capitalize}.join(" ") # get title, uppercasing it and converting _ to spaces
          if title != prev_title # only print the title once per step (it could occur multiple times if there are substeps)
            file.puts "## Step #{counter}. #{title}"
            counter+=1
          end
          prev_title=title.dup
          if !(key.include?('_conditional') || key.include?('_noguide'))
            file.puts I18n.t(key,params)
            file.puts ""
          end
        end
      end
    end
    
    puts "Guide written to #{guide_output_filename}"
    
  end
  
  # Command-line options for the main() method.
  desc('main: FIX', 'FIX')
  method_options(
    :run_all       => :boolean,
    :thru          => :string,
    :quick         => :boolean,
    :reset         => :boolean,
    :gems_from_git => :boolean,
    :debug_steps   => :boolean,
    :no_git        => :boolean,
    :diff          => :boolean,
    :app           => :string
  )
  def main(*requested_tasks)
    # Setup.
    HydraTutorial.initialize_config(options)
    HydraTutorial.initialize_progress_file
    HydraTutorial.load_progress_info
    ts      = HydraTutorial.determine_tasks_to_run(requested_tasks)
    outside = HydraTutorial.outside_tasks

    # If user requests --diff, just run git diff and exit.
    if @@conf.diff
      inside(@@conf.app) { run 'git diff HEAD^1..HEAD' }
      exit
    end

    # Run tasks.
    ts.each do |t|
      # Either print the task that would be run (in debug mode) or run the task.
      if @@conf.debug_steps
        say "Running: task=#{t.inspect}", STATEMENT
      else
        # A few of the initial tasks run outside the Rails app directory,
        # but most run inside the app directory.
        if outside.include?(t)
          invoke(t, [], {})
        else
          inside(@@conf.app) { invoke(t, [], {}) }
        end
      end
      # Persist the fact that the task was run to the YAML progress file.
      @@conf.done << t
      File.open(@@conf.progress_file, "w") { |f| f.puts(@@conf.to_yaml) }

      # Exit loop if we just ran the task user supplied with --thru option.
      break if t == @@conf.thru
    end

    # Inform user if the tutorial is finished.
    if ts.size == 0
      msg = "All tasks have been completed. Use the --reset option to start over."
      say(msg, WARNING)
    end

    # In debug mode, we print the contents of the progress file.
    run("cat #{@@conf.progress_file}", :verbose => false) if @@conf.debug_steps
  end

  # Sets up configuration information in the @@conf variable.
  def self.initialize_config(opts)
    @@conf                = HTConf.new
    @@conf.run_all        = opts[:run_all]
    @@conf.thru           = opts[:thru]
    @@conf.quick          = opts[:quick]
    @@conf.reset          = opts[:reset]
    @@conf.gems_from_git  = opts[:gems_from_git]
    @@conf.debug_steps    = opts[:debug_steps]
    @@conf.no_git         = opts[:no_git]
    @@conf.diff           = opts[:diff]
    @@conf.app            = (opts[:app]           || 'hydra_tutorial_app').strip.parameterize('_')
    @@conf.progress_file  = (opts[:progress_file] || '.hydra-tutorial-progress')
    @@conf.done           = nil
    @@conf.templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    @@conf.run_all = true if @@conf.thru
  end

  # Initializes the YAML progress file that keeps track of which
  # tutorial tasks have been completed. This needs to occur if
  # the YAML file does not exist yet or if the user requested a reset.
  # In the latter case, the program exits immediately.
  def self.initialize_progress_file
    return if (File.file?(@@conf.progress_file) and ! @@conf.reset)
    File.open(@@conf.progress_file, "w") { |f|
      f.puts("---\n")    # Empty YAML file.
    }
    exit if @@conf.reset
  end

  # Loads the progress info from the YAML file, and
  # sets the corresponding @@conf.done value.
  def self.load_progress_info
    h           = YAML.load_file(@@conf.progress_file) || {}
    @@conf.done = (h[:done] || [])
  end

  # Takes an array of task names: those requested on the command line
  # by the user (typically this list is empty).
  # Returns an arrray of task names: those that the main() taks will invoke.
  def self.determine_tasks_to_run(requested_tasks)
    if requested_tasks.size == 0
      # User did not request any tasks, so we determine which tasks
      # have not been done yet. We either return all of those tasks
      # or, more commonly, just the next text.
      done = Set.new(@@conf.done)
      ts   = tutorial_tasks.reject { |t| done.include?(t) }
      ts   = [ts.first] unless (@@conf.run_all or ts == [])
      return ts
    else
      # User requested particular tasks, so we will simply return
      # them, provided that they are valid task names.
      valid = Set.new(tutorial_tasks)
      requested_tasks.each { |rt|
        abort "Invalid task name: #{rt}." unless valid.include?(rt)
      }
      return requested_tasks
    end
  end


  ####
  # The remaining methods represent the steps in the tutorial.
  # The tasks should be defined in the order they should run.
  ####
  
  desc('welcome: FIX', 'FIX')
  def welcome
    say user_message(:conf_app=>@@conf.app),STATEMENT
  end

  desc('install_ruby: FIX', 'FIX')
  def install_ruby
    #return if @@conf.quick
    say user_message(:substep => 'one'), STATEMENT

    ruby_executable = run 'which ruby', :capture => true, :verbose => false
    ruby_executable.strip!

    say user_message(:substep => 'two_noguide', :ruby_executable => ruby_executable), STATEMENT

    if (ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_executable =~ /Users/)
      say user_message(:substep => 'three_conditional'), STATEMENT
    else
      say user_message(:substep => 'four_conditional'), WARNING
      say user_message(:substep => 'five'), WARNING
      continue_prompt
    end
  end

  desc('install_bundler_and_rails: FIX', 'FIX')
  def install_bundler_and_rails
    say user_message, STATEMENT
    run 'gem install bundler rails', :capture => false
  end

  desc('new_rails_app: FIX', 'FIX')
  def new_rails_app
    say user_message(:substep => 'one'), STATEMENT

    if File.exists? @@conf.app
      say user_message(:substep => 'two_conditional',:conf_app=>@@conf.app), WARNING
      exit
    end

    run "rails new #{@@conf.app}", :capture => false
  end

  desc('git_initial_commit: FIX', 'FIX')
  def git_initial_commit
    say user_message, STATEMENT
    run_git('', 'init')
    run_git('Initial commit')
  end

  desc('out_of_the_box: FIX', 'FIX')
  def out_of_the_box
    say user_message, STATEMENT
    rails_server
  end

  desc('adding_dependencies: FIX', 'FIX')
  def adding_dependencies
    say user_message, STATEMENT
    gem_group :assets do
      gem 'execjs'
      gem 'therubyracer'
    end
    run_git('Added gems for Javascript: execjs and therubyracer')
  end

  desc('add_fedora_and_solr_with_hydrajetty: FIX', 'FIX')
  def add_fedora_and_solr_with_hydrajetty
    say user_message(:substep=>'one'), STATEMENT
    say user_message(:substep=>'two'), STATEMENT
    unless File.exists? '../jetty'
      git :clone => 'http://github.com/projecthydra/hydra-jetty.git ../jetty'
    end
    unless File.exists? 'jetty'
      run 'cp -R ../jetty jetty'
    end
    append_to_file '.gitignore', "\njetty\n"
    run_git('Added jetty to project and git-ignored it')
  end

  desc('jetty_configuration: FIX', 'FIX')
  def jetty_configuration
    say user_message(:substep=>'one'), STATEMENT
    copy_file 'solr.yml', 'config/solr.yml'
    copy_file 'fedora.yml', 'config/fedora.yml'
    say user_message(:substep=>'two'), STATEMENT

    gem_group :development, :test do
      gem 'jettywrapper'
    end
    run 'bundle install', :capture => false
    run_git('Solr and Fedora configuration')
  end

  desc('starting_jetty: FIX', 'FIX')
  def starting_jetty
    say user_message(:substep=>'one'), STATEMENT
    rake 'jetty:start'
    say user_message(:substep=>'two'), STATEMENT

    continue_prompt
  end

  desc('remove_public_index: FIX', 'FIX')
  def remove_public_index
    say user_message, STATEMENT
    remove_file 'public/index.html'
    run_git('Removed the Rails index.html file')
  end

  desc('add_activefedora: FIX', 'FIX')
  def add_activefedora
    say user_message, STATEMENT
    gem 'active-fedora'
    gem 'om'
    run 'bundle install', :capture => false
    run_git('Added gems: active-fedora and om')
  end

  desc('add_initial_model: FIX', 'FIX')
  def add_initial_model
    say user_message, STATEMENT
    copy_file "basic_af_model.rb", "app/models/record.rb"
    run_git('Created a minimal Record model')
  end

  desc('rails_console_tour: FIX', 'FIX')
  def rails_console_tour
    say user_message, STATEMENT
    rails_console
  end

  desc('enhance_model_with_om_descmd: FIX', 'FIX')
  def enhance_model_with_om_descmd
    say user_message, STATEMENT
    f = "app/models/record.rb"
    remove_file f
    copy_file "basic_om_model.rb", f
    run_git('Set up basic OM descMetadata for Record model')
  end

  desc('experiment_with_om_descmd: FIX', 'FIX')
  def experiment_with_om_descmd
    say user_message, STATEMENT
    rails_console
  end

  desc('use_the_delegate_method: FIX', 'FIX')
  def use_the_delegate_method
    say user_message(:substep=>'one'), STATEMENT

    loc = %Q{\nend\n}
    insert_into_file "app/models/record.rb", :before => loc do
      "\n  delegate :title, :to => 'descMetadata'"
    end
    run_git('Modify Record model to delegate title to descMetadata')

    say user_message(:substep=>'two'), STATEMENT

    rails_console
  end

  desc('add_mods_model_with_mods_descmd: FIX', 'FIX')
  def add_mods_model_with_mods_descmd
    say user_message, STATEMENT
    f = "app/models/record.rb"
    remove_file f
    copy_file "basic_mods_model.rb", f
    copy_file "mods_desc_metadata.rb", "app/models/mods_desc_metadata.rb"
    run_git('Set up MODS descMetadata')
  end

  desc('experiment_with_mods_descmd: FIX', 'FIX')
  def experiment_with_mods_descmd
    say user_message, STATEMENT
    rails_console
  end

  desc('record_generator: FIX', 'FIX')
  def record_generator
    say user_message(:substep=>'one'), STATEMENT
    generate "scaffold_controller Record --no-helper --skip-test-framework"
    route "resources :records"
    run_git('Used Rails generator to create controller and views for the Record model')
    say user_message(:substep=>'two'), STATEMENT

    continue_prompt
  end

  desc('add_new_form: FIX', 'FIX')
  def add_new_form
    say user_message, STATEMENT
    files = [
      ["_form.wiring_it_into_rails.html.erb", "app/views/records/_form.html.erb"],
      ["show.html.erb",                       "app/views/records/show.html.erb"],
      ["index.html.erb",                      "app/views/records/index.html.erb"],
    ]
    files.each do |src, dst|
      remove_file dst
      copy_file src, dst
    end
    run_git('Fleshed out the edit form and show page')
  end

  desc('check_the_new_form: FIX', 'FIX')
  def check_the_new_form
    say user_message, STATEMENT
    rails_server '/records/new'
  end

  desc('add_hydra_gems: FIX', 'FIX')
  def add_hydra_gems
    say user_message, STATEMENT
    if @@conf.gems_from_git
      gem 'blacklight', :git => "http://github.com/projectblacklight/blacklight.git"
      gem 'hydra-head', :git => "http://github.com/projecthydra/hydra-head.git"
    else
      gem 'blacklight'
      gem 'hydra-head', ">= 5.x"
    end
    gem 'devise'
    run 'bundle install', :capture => false
    run_git('Added gems: blacklight, hydra-head, devise')
  end

  desc('run_hydra_generators: FIX', 'FIX')
  def run_hydra_generators
    say user_message, STATEMENT
    f = 'config/solr.yml'
    remove_file f
    generate 'blacklight', '--devise'
    remove_file f
    remove_file 'app/controllers/catalog_controller.rb'
    generate 'hydra:head', 'User'
    run_git('Ran blacklight and hydra-head generators')
  end

  desc('db_migrate: FIX', 'FIX')
  def db_migrate
    say user_message, STATEMENT
    rake 'db:migrate'
    rake 'db:test:prepare'
    run_git('Ran db:migrate, which created db/schema.rb')
  end

  desc('hydra_jetty_config: FIX', 'FIX')
  def hydra_jetty_config
    say user_message, STATEMENT
    rake 'jetty:stop'
    rake 'hydra:jetty:config'
    rake 'jetty:start'
  end

  desc('add_access_rights: FIX', 'FIX')
  def add_access_rights
    say user_message, STATEMENT
    # inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
    #   "  include Hydra::AssetsControllerHelper\n"
    # end

    insert_into_file "app/controllers/records_controller.rb", :after => "@record = Record.new(params[:record])\n" do
      "    apply_depositor_metadata(@record)\n"
    end

    inject_into_class "app/models/record.rb", "Record" do
      "
include Hydra::ModelMixins::CommonMetadata
include Hydra::ModelMethods
      "
    end

    insert_into_file "app/models/solr_document.rb", :after => "include Blacklight::Solr::Document\n" do
      "
include Hydra::Solr::Document
      "
    end

    insert_into_file "app/assets/javascripts/application.js", :after => "//= require_tree .\n" do
      "Blacklight.do_search_context_behavior = function() { }\n"
    end

    inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
      "  include Hydra::AccessControlsEnforcement\n" +
      "  before_filter :enforce_access_controls\n"
    end

    run_git('Modify controller and model to include access rights')
  end

  desc('check_catalog: FIX', 'FIX')
  def check_catalog
    say user_message, STATEMENT

    copy_file '_user_util_links.html.erb', 'app/views/_user_util_links.html.erb'

    rails_server
  end

  desc('install_rspec: FIX', 'FIX')
  def install_rspec
    say user_message, STATEMENT

    gem_group :development, :test do
      gem 'rspec'
      gem 'rspec-rails'
    end
    run 'bundle install', :capture => false
    generate 'rspec:install'
    run_git('Added rspec to project')
  end

  # TODO: write the test.
  # desc('write_model_test: FIX', 'FIX')
  # def write_model_test
  #   # copy_file 'record_test.rb', 'spec/models/record_test.rb'
  #   # run_git('Added a model test')
  #   run 'rspec'
  # end

  # TODO: this test should do something.
  desc('write_controller_test: FIX', 'FIX')
  def write_controller_test
    say user_message, STATEMENT
    copy_file 'records_controller_spec.rb', 'spec/controllers/records_controller_spec.rb'
    run_git('Added a controller test')
    run 'rspec'
  end

  desc('install_capybara: FIX', 'FIX')
  def install_capybara
    say user_message, STATEMENT
    gem_group :development, :test do
      gem 'capybara'
    end
    run 'bundle install', :cature => true
    run_git('Added capybara gem')
  end

  desc('write_integration_test: FIX', 'FIX')
  def write_integration_test
    say user_message, STATEMENT
    copy_file 'integration_spec.rb', 'spec/integration/integration_spec.rb'
    run_git('Added an integration test')
  end

  desc('run_integration_test_fail: FIX', 'FIX')
  def run_integration_test_fail
    say user_message, STATEMENT
    run 'rspec'
  end

  desc('add_jettywrapper_ci_task: FIX', 'FIX')
  def add_jettywrapper_ci_task
    say user_message, STATEMENT
    copy_file 'ci.rake', 'lib/tasks/ci.rake'
    run_git('Added ci task')
    rake 'jetty:stop'
    rake 'ci'
    rake 'jetty:start'
  end

  desc('add_coverage_stats: FIX', 'FIX')
  def add_coverage_stats
    say user_message(:substep=>'one'), STATEMENT

    gem_group :development, :test do
      gem 'simplecov'
    end
    run 'bundle install', :capture => false

    f = 'lib/tasks/ci.rake'
    remove_file f
    copy_file 'ci_with_coverage.rake', f

    insert_into_file "spec/spec_helper.rb", :after => "ENV[\"RAILS_ENV\"] ||= 'test'\n"do
      %Q{
if ENV['COVERAGE'] == "true"
require 'simplecov'
SimpleCov.start do
  add_filter "config/"
  add_filter "spec/"
end
end
      }
    end

    append_to_file '.gitignore', "\ncoverage\n"
    run_git('Added simplecov')

    rake 'jetty:stop'
    rake 'ci'
    rake 'jetty:start'

    say user_message(:substep=>'two'), STATEMENT

    continue_prompt
  end

  desc('add_file_uploads: FIX', 'FIX')
  def add_file_uploads
    say user_message, STATEMENT

    inject_into_class 'app/models/record.rb', 'Record' do
      "has_file_datastream :name => 'content', :type => ActiveFedora::Datastream\n"
    end
    run_git('Add file uploads to model')
  end

  # TODO: combine with previous task.
  desc('add_file_upload_controller: FIX', 'FIX')
  def add_file_upload_controller
    say user_message, STATEMENT

    inject_into_class "app/controllers/records_controller.rb", "RecordsController" do
      "    include Hydra::Controller::UploadBehavior\n"
    end
    insert_into_file "app/controllers/records_controller.rb", :after => "apply_depositor_metadata(@record)\n" do
      "    @record.label = params[:record][:title] # this is a bad hack to work around an AF bug\n" +
      "    add_posted_blob_to_asset(@record, params[:filedata]) if params.has_key?(:filedata)\n"
    end
    run_git('Add file uploads to controller')
  end

  # TODO: combine with previous task.
  desc('add_file_upload_ui: FIX', 'FIX')
  def add_file_upload_ui
    say user_message, STATEMENT
    f = "app/views/records/_form.html.erb"
    remove_file f
    copy_file "_form.add_file_upload.html.erb", f
    run_git('Add file uploads to UI')
  end

  desc('fix_add_assets_links: FIX', 'FIX')
  def fix_add_assets_links
    say user_message, STATEMENT
    copy_file "_add_assets_links.html.erb", "app/views/_add_assets_links.html.erb"
    run_git('Add asset links')
  end

  # # TODO
  # desc('add_collection_model: FIX', 'FIX')
  # def add_collection_model
  # end

  # # TODO
  # desc('add_collection_controller: FIX', 'FIX')
  # def add_collection_controller
  # end

  # # TODO
  # desc('add_collection_reference_to_record: FIX', 'FIX')
  # def add_collection_reference_to_record
  # end

  # # TODO
  # desc('add_datastream_and_terminology: FIX', 'FIX')
  # def add_datastream_and_terminology
  # end

  desc('start_everything: FIX', 'FIX')
  def start_everything
    say user_message, STATEMENT
    rake 'jetty:stop'
    rake 'jetty:start'
    rails_server
  end

  desc('stop_jetty: FIX', 'FIX')
  def stop_jetty
    say user_message, STATEMENT
    rake 'jetty:stop'
  end


end


####
#
####

HydraTutorial.start
