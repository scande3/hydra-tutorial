#! /usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'
require 'rails/generators/actions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'
require 'fileutils'
require 'yaml'

STATEMENT = Thor::Shell::Color::YELLOW
QUESTION  = Thor::Shell::Color::GREEN
WAIT      = Thor::Shell::Color::CYAN
WARNING   = Thor::Shell::Color::RED

module HydraTutorialHelpers

  @@conf = nil

  def run_git(msg, *cmds)
    cmds = ['add -A', 'commit -m'] if cmds.size == 0
    cmds.each do |cmd|
      cmd += " '#{msg}'" if cmd =~ /^commit/
      run "git #{cmd}", :capture => true
    end
  end

  def continue_prompt
    return if @@conf.quick
    return unless @@conf.run_all
    ask %Q{
  HIT <ENTER> KEY TO CONTINUE}, WAIT
  end

  def rails_console
    say %Q{
  We'll launch the console again. Give some of those commands a try.\n}, STATEMENT
    say %Q{
  Hit Ctrl-D (^D) to stop the Rails console and continue this tutorial.\n}, WAIT
    run "rails c"
  end

  def rails_server url = '/'
    say %Q{
  We'll start the Rails server for you. It should be available in 
  your browser at:

     http://localhost:3000#{url}\n}, STATEMENT
    say %Q{
  Hit Ctrl-C (^C) to stop the Rails server and continue this tutorial.\n}, WAIT
    run "rails s"
  end

end

class HydraTutorial < Thor

  include Thor::Actions
  include Rails::Generators::Actions
  include HydraTutorialHelpers

  HTConf = Struct.new(
    :templates_path,
    :quick,
    :run_all,
    :gems_from_git,
    :reset,
    :app_root,
    :debug_steps,
    :progress_file,
    :done
  )

  desc('main: FIX', 'FIX')
  method_options(
    :quick         => :boolean,
    :all           => :boolean,
    :gems_from_git => :boolean,
    :reset         => :boolean,
    :debug_steps   => :boolean,
    :app           => :string,
  )

  def self.tutorial_tasks
    return [
      [ false, 'welcome' ],
      [ false, 'install_ruby' ],
      [ false, 'install_bundler_and_rails' ],
      [ false, 'new_rails_app' ],
      [ true,  'git_initial_commit' ],
      [ true,  'out_of_the_box' ],
      [ true,  'adding_dependencies' ],
      [ true,  'add_fedora_and_solr_with_hydrajetty' ],
      [ true,  'jetty_configuration' ],
      [ true,  'remove_public_index' ],
      [ true,  'add_activefedora' ],
      [ true,  'add_initial_model' ],
      [ true,  'rails_console_tour' ],
      [ true,  'enhance_model_with_om_descmd' ],
      [ true,  'experiment_with_om_descmd' ],
      [ true,  'use_the_delegate_method' ],
      [ true,  'add_mods_model_with_mods_descmd' ],
      [ true,  'experiment_with_mods_descmd' ],
      [ true,  'record_generator' ],
      [ true,  'add_new_form' ],
      [ true,  'check_the_new_form' ],
      [ true,  'add_hydra_gems' ],
      [ true,  'run_hydra_generators' ],
    ]
    to_do = [
      [ true,  'db_migrate' ],
      [ true,  'hydra_jetty_conf' ],
      [ true,  'do_it' ],
      [ true,  'look_at_it' ],
      [ true,  'install_rspec' ],
      [ true,  'write_our_first_test' ],
      [ true,  'a_model_test' ],
      [ true,  'install_capybara' ],
      [ true,  'an_integration_test' ],
      [ true,  'run_tests_x3' ],
      [ true,  'add_jettywrapper_ci_task' ],
      [ true,  'add_coverage_stats' ],
      [ true,  'coverage_prompt' ],
      [ true,  'add_file_uploads' ],
      [ true,  'add_file_upload_controller' ],
      [ true,  'add_file_upload_ui' ],
      [ true,  'fix_add_assets_links' ],
      [ true,  'add_collection_model' ],
      [ true,  'add_collection_controller' ],
      [ true,  'add_collection_reference_to_record' ],
      [ true,  'add_datastream_and_terminology' ],
      [ true,  'start_everything' ],
      [ true,  'stop_jetty' ],
    ]
  end

  def self.source_paths
    [@@conf.templates_path]
  end

  ####
  # The main task that is invoked by the gem's executable script.
  #
  # This task invokes either the next task in the tutorial or
  # the task(s) explicitly requested by the user.
  ####

  def main(*requested_tasks)
    # Setup.
    HydraTutorial.initialize_config(options)
    HydraTutorial.initialize_progress_file
    HydraTutorial.load_progress_info
    tasks = HydraTutorial.determine_tasks_to_run(requested_tasks)

    # Run tasks.
    tasks.each do |i, t|
      # Either print the task that would be run (in debug mode) or run the task.
      # Each task knows whether it should be run inside the app directory (when i==true).
      if @@conf.debug_steps
        say "Running: task=#{t.inspect}", STATEMENT
      else
        if i
          inside(@@conf.app_root) { invoke(t, [], {}) }
        else
          invoke(t, [], {})
        end
      end
      # Persist the fact that the task was run to the YAML progress file.
      @@conf.done << t
      File.open(@@conf.progress_file, "w") { |f|
        h = { :app_root => @@conf.app_root, :done => @@conf.done }
        f.puts(h.to_yaml)
      }
    end

    # Inform user if the tutorial is finished.
    if tasks.size == 0
      msg = "All tasks have been completed. Use the --reset option to start over."
      say(msg, WARNING)
    end

    # In debug mode, we print the contents of the progress file.
    run("cat #{@@conf.progress_file}", :verbose => false) if @@conf.debug_steps
  end

  def self.initialize_config(opts)
    @@conf                = HTConf.new
    @@conf.templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    @@conf.quick          = opts[:quick]
    @@conf.run_all        = opts[:all]
    @@conf.gems_from_git  = opts[:gems_from_git]
    @@conf.reset          = opts[:reset]
    @@conf.app_root       = opts[:app]
    @@conf.debug_steps    = opts[:debug_steps]
    @@conf.progress_file  = '.hydra-tutorial-progress'
    @@conf.done           = nil
  end

  def self.initialize_progress_file
    return if (File.file?(@@conf.progress_file) and ! @@conf.reset)
    File.open(@@conf.progress_file, "w") { |f|
      f.puts("---\n")
    }
    exit if @@conf.reset
  end

  def self.load_progress_info
    # Load progress info from YAML, and set defaults as needed.
    # Set some @@conf values.
    h               = YAML.load_file(@@conf.progress_file) || {}
    root            = (@@conf.app_root || h[:app_root] || 'hydra_tutorial_app')
    @@conf.app_root = root.strip.parameterize('_')
    @@conf.done     = (h[:done] || [])
  end

  def self.determine_tasks_to_run(requested_tasks)
    if requested_tasks.size == 0
      tasks = tutorial_tasks.reject { |i, t| @@conf.done.include?(t) }
      tasks = [tasks.first] unless (@@conf.run_all or tasks == [])
    else
      tasks = requested_tasks.map { |rt| 
        task = tutorial_tasks.find { |i, t| rt == t }
        abort "Invalid task name: #{rt}." unless task
        task
      }
    end
    return tasks
  end


  ####
  # Steps in the tutorial.
  ####

  desc('welcome: FIX', 'FIX')
  def welcome
    say %Q{
    Welcome to this Hydra tutorial. We're going to step through building a 
    working Hydra application. We'll build the application gradually, starting 
    by building our "business logic", wiring in HTML views, and then 
    connecting it to our Rails application.

    At several points in this tutorial, as we iteratively develop our files, 
    you may be prompted to review conflicts between versions of files. It is 
    safe to blindly accept the changes ('y'), however you may wish to view 
    the diff ('d') to see the things we're change.

    This tutorial, a README file, and our bug tracker are at:
        
        https://github.com/projecthydra/hydra-tutorial

    We'll generate a stub application in the #{@@conf.app_root} 
    folder. You can change that using the --app option.
    }, STATEMENT
  end

  desc('install_ruby: FIX', 'FIX')
  def install_ruby
    return if @@conf.quick
    say %Q{ 
  Obviously, if you can run this tutorial, you have already installed ruby.
    }, STATEMENT


    ruby_executable = run 'which ruby', :capture => true, :verbose => false
    ruby_executable.strip!

    say %Q{
  You are running this using:

      #{ruby_executable}
    }, STATEMENT

    if ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_executable =~ /Users/
      say %Q{
  It looks like you're using rvm/rbenv/etc. We'll use 
  this environment to build the application.
    }, STATEMENT

    else

    say %Q{
  We checked, and it looks like you might be using a system-wide ruby. 
  We suggest you use somethng like rvm [1], rbenv [2], etc to manage 
  your ruby projects.

  You can continue and hope for the best, or go install one of these 
  ruby managers, which may make your life easier.

  [1] http://rvm.io/
  [2] https://github.com/sstephenson/rbenv/
    }, WARNING

    continue_prompt

    end

  end

  desc('install_bundler_and_rails: FIX', 'FIX')
  def install_bundler_and_rails
    say %Q{
  We're going to install some prerequisite gems in order to create our 
  skeleton Rails application.\n}, STATEMENT
    run 'gem install bundler rails', :capture => true
  end

  desc('new_rails_app: FIX', 'FIX')
  def new_rails_app
    say %Q{
  Now we'll create the application.\n}, STATEMENT

    if File.exists? @@conf.app_root
      say %Q{
    #{@@conf.app_root} already exists. Either remove it or provide 
    a different application name using the --app option.}, WARNING
      exit
    end

    run "rails new #{@@conf.app_root}", :capture => true
  end

  desc('git_initial_commit: FIX', 'FIX')
  def git_initial_commit
    say %Q{
  We will keep track of our work using Git so that you can see how
  the files in the project change from one step to the next.

  First, we'll initialize our project's Git repository.\n}, STATEMENT

    run_git('', 'init')
    run_git('Initial commit')
  end

  desc('out_of_the_box: FIX', 'FIX')
  def out_of_the_box
    return if @@conf.quick
    say %Q{
  Here's a chance to look around. You can see the structure of 
  a Rails application. In particular, look at:
     ./app
     ./config
     ./lib
     Gemfile

  If we launched the Rails application server, we can see the application 
  running in the browser and you can see if everything is working.\n}, STATEMENT

    rails_server unless @@conf.quick
  end

  desc('adding_dependencies: FIX', 'FIX')
  def adding_dependencies
    gem 'execjs'
    gem 'therubyracer'
    run_git('Added gems for Javascript: execjs and therubyracer')
  end

  desc('add_fedora_and_solr_with_hydrajetty: FIX', 'FIX')
  def add_fedora_and_solr_with_hydrajetty
    say %Q{
  Fedora runs as a Java servlet inside a container like Tomcat or Jetty.
  Hydra provides a bundled version of Fedora and Solr for 
  testing and development.\n}, STATEMENT

    say %Q{
  We'll download it now and put a copy into your application's directory.
  This might take awhile.\n}, STATEMENT
    unless File.exists? '../jetty'
      git :clone => '-b 4.x git://github.com/projecthydra/hydra-jetty.git ../jetty'
    end
    unless File.exists? 'jetty'
      run 'cp -R ../jetty jetty'
    end
    append_to_file '.gitignore', "\njetty"
    run_git('Added jetty to project and git-ignored it')
  end

  desc('jetty_configuration: FIX', 'FIX')
  def jetty_configuration 
    say %Q{
  We'll add some configuration yml files with information to connect 
  to Solr and Fedora.\n\n}, STATEMENT

    copy_file 'solr.yml', 'config/solr.yml'
    copy_file 'fedora.yml', 'config/fedora.yml'

    say %Q{
  Add the 'jettywrapper' gem, which adds Rake tasks to start and stop Jetty.\n}, STATEMENT

    gem 'jettywrapper'
    run 'bundle install', :capture => true
    run_git('Solr and Fedora configuration')

    say %Q{
  Starting Jetty\n}, STATEMENT
    rake 'jetty:start'

    say %Q{ 
  Take a look around. Jetty should be running on port 8983. You can see 
  the Fedora server at:

    http://localhost:8983/fedora/

  And a Solr index at:

    http://localhost:8983/solr/development/admin/\n}, STATEMENT

    continue_prompt
  end

  desc('remove_public_index: FIX', 'FIX')
  def remove_public_index
    remove_file 'public/index.html'
    run_git('Removed the Rails index.html file')
  end

  desc('add_activefedora: FIX', 'FIX')
  def add_activefedora
    say %Q{
  The active-fedora gem provides a way to model Fedora objects within Ruby.
  It will help you create Ruby models for creating, updating and reading 
  objects from Fedora using a domain-specific language (DSL) similar 
  to the Rails' ActiveRecord.

  The om gem provides mechanisms for mapping XML documents into Ruby.

  We'll add both of these to the Gemfile.\n\n}, STATEMENT
    gem 'active-fedora'
    gem 'om'
    run 'bundle install', :capture => true
    run_git('Added gems: active-fedora and om')
  end

  desc('add_initial_model: FIX', 'FIX')
  def add_initial_model
    say %Q{ 
  Now we'll add a basic ActiveFedora stub model for a 'Record'.\n\n}, STATEMENT
    copy_file "basic_af_model.rb", "app/models/record.rb"
    run_git('Created a minimal Record model')
  end

  desc('rails_console_tour: FIX', 'FIX')
  def rails_console_tour
    say %Q{
  Now we'll give you a chance to look at the Record model. If you 
  launch the Rails interactive console (`rails c`), we can create 
  and manipulate our object:

      ## CREATE
      > obj = Record.new
      # => #<Record:1571331701243443635 @pid="__DO_NOT_USE__" >
      > obj.descMetadata.content = e.g. '<my_xml_content />'
      > obj.save

      > obj.pid  
      # => e.g. 'changeme:1'

      ## RETRIEVE
      > obj = Record.find('changeme:1')
      > ds = obj.descMetadata
      # => #<ActiveFedora::NokogiriDatastream:3283711306477137919 ...>
      > ds.content
      # => (should be the XML document you added before)

      ## UPDATE
      # manipulating XML:
      > ds.ng_xml.xpath('//my_xml_content') 

      ## DELETE
      > obj.delete\n}, STATEMENT
    rails_console unless @@conf.quick
  end

  desc('enhance_model_with_om_descmd: FIX', 'FIX')
  def enhance_model_with_om_descmd
    say %Q{
  Instead of working with the Nokogiri XML document directly, we 
  can use OM to make querying an XML document easier. We'll replace the 
  previous Record with a OM-enabled document.\n\n}, STATEMENT
    f = "app/models/record.rb"
    remove_file f
    copy_file "basic_om_model.rb", f
    run_git('Set up basic OM descMetadata for Record model')
  end

  desc('experiment_with_om_descmd: FIX', 'FIX')
  def experiment_with_om_descmd
    say %Q{
  If you launch the Rails interactive console, we can now create and 
  manipulate our object using methods provided by OM.

      > obj = Record.new
      > obj.descMetadata.title = "My object title"
      > obj.save
      > obj.descMetadata.content
      # => An XML document with the title "My object title"\n}, STATEMENT
    rails_console unless @@conf.quick
  end

  desc('use_the_delegate_method: FIX', 'FIX')
  def use_the_delegate_method
    say %Q{
  We can use the #delegate method to tell the model-object how 
  to access these attributes.

      > obj = Record.new
      > obj.title = "My object title"
      > obj.save
      > obj.descMetadata.content
      # => An XML document with the title "My object title"\n\n}, STATEMENT

    loc = 'has_metadata :name => "descMetadata", :type => DatastreamMetadata\n'
    insert_into_file "app/models/record.rb", :after => loc do
      "delegate :title, :to => 'descMetadata'\n"
    end
    run_git('Modify Record model to delegate title to descMetadata')
  end

  desc('add_mods_model_with_mods_descmd: FIX', 'FIX')
  def add_mods_model_with_mods_descmd
    say %Q{
  We'll now replace the minimal XML metadata schema with a simple
  MODS-based example, using an OM terminology we prepared earlier.

  We'll put the MODS datastream in a separate module and file, so that
  it can be easily reused in other ActiveFedora-based objects.\n}, STATEMENT

    f = "app/models/record.rb"
    remove_file f
    copy_file "basic_mods_model.rb", f
    copy_file "mods_desc_metadata.rb", "app/models/mods_desc_metadata.rb"
    run_git('Set up MODS descMetadata')
  end

  desc('experiment_with_mods_descmd: FIX', 'FIX')
  def experiment_with_mods_descmd
    say %Q{
  If you launch the Rails interactive console, we can now create 
  and manipulate our object using methods provided by OM.

      > obj = Record.new
      > obj.title = "My object title"
      > obj.save
      > obj.descMetadata.content
      # => A MODS XML document\n}, STATEMENT
    rails_console unless @@conf.quick
  end

  desc('record_generator: FIX', 'FIX')
  def record_generator
    say %Q{ 
  Now that we've set up our model and successfully added content
  into Fedora, now we want to connect the model to a Rails web application.

  We'll start by using the standard Rails generators to create 
  a scaffold controller and views, which will give us a 
  place to start working.\n\n}, STATEMENT

    generate "scaffold_controller Record --no-helper --skip-test-framework"
    route "resources :records"
    run_git('Used Rails generator to create controller and views for the Record model')

    say %Q{
  If you look in ./app/views/records, you can see a set of 
  Rails ERB templates.

  ./app/controlers/records_controller.rb contains the controller 
  that ties the model to the views.\n}, STATEMENT

    continue_prompt
  end

  desc('add_new_form: FIX', 'FIX')
  def add_new_form
    say %Q{
 The scaffold just provided the basic outline for an application, so 
 we need to provide the guts for the web form. Here's a simple one:\n\n}, STATEMENT
    copy_file "_form.wiring_it_into_rails.html.erb", "app/views/records/_form.html.erb"
    copy_file "show.html.erb", "app/views/records/show.html.erb"
    run_git('Fleshed out the edit form and show page')
  end

  desc('check_the_new_form: FIX', 'FIX')
  def check_the_new_form
    say %Q{
 If we start the Rails server, we should now be able to visit the records
 in the browser, create new records, and edit existing records. 

 Start by creating a new record:\n}, STATEMENT
    rails_server '/records/new' unless @@conf.quick
  end

  desc('add_hydra_gems: FIX', 'FIX')
  def add_hydra_gems
    say %Q{
  Thus far, we've been using component parts of the Hydra framework, but 
  now we'll add in the whole framework so we can take advantage of common 
  patterns that have emerged in the Hydra community, including search, 
  gated discovery, etc.

  We'll add a few new gems:

    - blacklight provides a discovery interface on top of the Solr index

    - hydra-head provides a number of common Hydra patterns

    - devise is a standard Ruby gem for providing user-related 
      functions, like registration, sign-in, etc.\n\n}, STATEMENT

    if @@conf.gems_from_git
      gem 'blacklight', :git => "git://github.com/projectblacklight/blacklight.git"
      gem 'hydra-head', :git => "git://github.com/projecthydra/hydra-head.git"
    else
      gem 'blacklight'
      gem 'hydra-head', ">= 4.1.1"
    end
    gem 'devise'
    run 'bundle install', :capture => true
    run_git('Added gems: blacklight, hydra-head, devise')
  end

  desc('run_hydra_generators: FIX', 'FIX')
  def run_hydra_generators
    say %Q{
  These gems provide generators for adding basic views, styles, and override 
  points into your application. We'll run these generators now.\n}, STATEMENT
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
    say %Q{
  Blacklight uses a SQL database for keeping track of user bookmarks, 
  searches, etc. We'll run the migrations next:
    }, STATEMENT
    rake 'db:migrate'
    rake 'db:test:prepare'
  end

  desc('hydra_jetty_conf: FIX', 'FIX')
  def hydra_jetty_conf
    say %Q{
  Hydra provides some configuration for Solr and Fedora. Use them.
    }, STATEMENT
    rake 'jetty:stop'
    rake 'hydra:jetty:config'
    rake 'jetty:start'
  end

  desc('do_it: FIX', 'FIX')
  def do_it

    say %Q{
  We need to make a couple changes to our controller and model to make 
  them fully-compliant objects by teaching them about access rights.
    }, STATEMENT

    inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
      "  include Hydra::AssetsControllerHelper\n"
    end

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
    say %Q{
  We'll also update our controller to provide access controls on records.
    }

    inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
      "  include Hydra::AccessControlsEnforcement\n" +
      "  before_filter :enforce_access_controls\n"
    end

  end

  desc('look_at_it: FIX', 'FIX')
  def look_at_it
    say %Q{
  Blacklight and Hydra-Head have added some new functionality to the 
  application. We can now look at a search interface (provided 
  by Blacklight) and use gated discovery over our repository. By default, 
  objects are only visible to their creator.

  Create some new objects, and then check out the search catalog at:

     http://localhost:3000/catalog

    }, STATEMENT

    rails_server('/records/new') unless @@conf.quick
  end

  desc('install_rspec: FIX', 'FIX')
  def install_rspec
    say %Q{
  One of the great things about the Rails framework is the strong
  testing ethic. We'll use rspec to write a couple tests for 
  this application.
    }, STATEMENT
    gem_group :development, :test do
      gem 'rspec'
      gem 'rspec-rails'
    end
    run 'bundle install'

    generate 'rspec:install'
  end
  
  desc('write_our_first_test: FIX', 'FIX')
  def write_our_first_test
    say %Q{
  Here's a quick example of a test.
    }
    copy_file 'records_controller_spec.rb', 'spec/controllers/records_controller_spec.rb'
    run 'rspec'
  end

  desc('a_model_test: FIX', 'FIX')
  def a_model_test
 #   copy_file 'record_test.rb', 'spec/models/record_test.rb'
    #run 'rspec'
  end

  desc('install_capybara: FIX', 'FIX')
  def install_capybara
    say %Q{ 
  We also want to write integration tests to test the end-result that
  a user may see. We'll add the capybara gem to do that.
    }, STATEMENT
    gem_group :development, :test do
      gem 'capybara'
    end
    run 'bundle install'
   # inject_into_file 'spec/spec_helper.rb' do
   #   "  require 'capybara/rails'\n"
   # end
  end

  desc('an_integration_test: FIX', 'FIX')
  def an_integration_test
    say %Q{
  Here's a quick integration test that proves deposit works.
    }, STATEMENT
    copy_file 'integration_spec.rb', 'spec/integration/integration_spec.rb'
  end

  desc('run_tests_x3: FIX', 'FIX')
  def run_tests_x3
    say %Q{
    Now that the integration spec is in place, when we try to run rspec,
    we'll get a test failure because it can't connect to Fedora.
    }, STATEMENT
    run 'rspec'
  end

  desc('add_jettywrapper_ci_task: FIX', 'FIX')
  def add_jettywrapper_ci_task
    say %Q{
    Instead, we need to add a new Rake task that knows how to wrap the 
    test suite --  start jetty before running the tests and stop jetty
    at the end. We can use a feature provided by jettywrapper to do this.
    }, STATEMENT
    copy_file 'ci.rake', 'lib/tasks/ci.rake'

    rake 'jetty:stop'
    rake 'ci'
    rake 'jetty:start'
  end

  desc('add_coverage_stats: FIX', 'FIX')
  def add_coverage_stats
    say %Q{
    Now that we have tests, we also want to have some coverage statistics.
    }, STATEMENT

    gem_group :development, :test do
      gem 'simplecov'
    end

    run 'bundle install'

    copy_file 'ci_with_coverage.rake', 'lib/tasks/ci.rake'
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

    rake 'jetty:stop'
    rake 'ci'
    rake 'jetty:start'
  end

  desc('coverage_prompt: FIX', 'FIX')
  def coverage_prompt
    say %Q{
    Go take a look at the coverage report, open the file ./coverage/index.html
    in your browser.
    }, STATEMENT
    continue_prompt
  end

  desc('add_file_uploads: FIX', 'FIX')
  def add_file_uploads
    say %Q{ 
  Now that we have a basic Hydra application working with metadata-only, we
  want to enhance that with the ability to upload files. Let's add a new 
  datastream to our model.
    }, STATEMENT
    inject_into_class 'app/models/record.rb', 'Record' do
      "has_file_datastream :name => 'content', :type => ActiveFedora::Datastream\n"
    end
  end
  
  desc('add_file_upload_controller: FIX', 'FIX')
  def add_file_upload_controller
    say %Q{
  And educate our controller for managing file objects.
    }, STATEMENT
    inject_into_class "app/controllers/records_controller.rb", "RecordsController" do
      "    include Hydra::Controller::UploadBehavior\n"
    end
    insert_into_file "app/controllers/records_controller.rb", :after => "apply_depositor_metadata(@record)\n" do
      "    @record.label = params[:record][:title] # this is a bad hack to work around an AF bug\n" +
      "    add_posted_blob_to_asset(@record, params[:filedata]) if params.has_key?(:filedata)\n" 
    end
  end

  desc('add_file_upload_ui: FIX', 'FIX')
  def add_file_upload_ui
    say %Q{
  And add a file upload field on the form.
    }, STATEMENT
    copy_file "_form.html.erb", "app/views/records/_form.html.erb"
  end

  desc('fix_add_assets_links: FIX', 'FIX')
  def fix_add_assets_links
    say %Q{ 
  We'll add a little styling to the Hydra app and add a link to add a new 
  Record in the header of the layout.
    }, STATEMENT
    copy_file "_add_assets_links.html.erb", "app/views/_add_assets_links.html.erb"
  end

  desc('add_collection_model: FIX', 'FIX')
  def add_collection_model
    # TODO
  end

  desc('add_collection_controller: FIX', 'FIX')
  def add_collection_controller
    # TODO
  end

  desc('add_collection_reference_to_record: FIX', 'FIX')
  def add_collection_reference_to_record
    # TODO
  end

  desc('add_datastream_and_terminology: FIX', 'FIX')
  def add_datastream_and_terminology
    # TODO
  end

  desc('start_everything: FIX', 'FIX')
  def start_everything
    say %Q{
  This is the end of the tutorial. We'll give you a final chance to look 
  at the web application.
    }, STATEMENT
    rake 'jetty:stop'
    rake 'jetty:start'
    rails_server
  end

  desc('stop_jetty: FIX', 'FIX')
  def stop_jetty
    rake 'jetty:stop'
  end

end

HydraTutorial.start
