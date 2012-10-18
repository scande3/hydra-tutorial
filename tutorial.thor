#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'
require 'rails/generators/actions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'
require 'set'
require 'fileutils'
require 'yaml'

$base_templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

STATEMENT = Thor::Shell::Color::YELLOW
QUESTION = Thor::Shell::Color::GREEN
WAIT = Thor::Shell::Color::CYAN

class HydraTutorialApp < Thor::Group

  include Thor::Actions
  include Rails::Generators::Actions

  module TutorialActions

    def all_tasks
      return %w(
        welcome
        install_ruby
        install_bundler_and_rails
        new_rails_app
        git_initial_commit
        out_of_the_box
      )
    end

    def progress_file_name
      return '.hydra-tutorial-progress'
    end

    def run_git_commands(cmds, msg = 'COMMIT_MSG')
      inside $app_root do
        cmds.each do |cmd|
          cmd += " '#{msg}'" if cmd =~ /^commit/
          run "git #{cmd}", :capture => true
        end
      end
    end

    def continue_prompt
      return if $quick
      return unless $run_all
      ask %Q{
    HIT <ENTER> KEY TO CONTINUE
      }, WAIT
    end

    def rails_console
      say %Q{
    We'll launch the console again. Give some of those commands a try.
      }, STATEMENT

      say %Q{

    Hit Ctrl-D (^D) to stop the Rails console and continue this tutorial.
      }, WAIT

      run "rails c"
    end

    def rails_server url = '/'
      say %Q{
    We'll start the Rails server for you. It should be available in 
    your browser at:

       http://localhost:3000#{url}
      }, STATEMENT

      say %Q{
    Hit Ctrl-C (^C) to stop the Rails server and continue this tutorial.
      }, WAIT

      run "rails s"
    end
  end

  include TutorialActions

  class_option :quick
  class_option :all
  class_option :git
  class_option :reset
  class_option :debug_steps
  class_option :app, :type => :string

  argument(
    :task_args, 
    :type     => :array, 
    :desc     => "Task name and its arguments",
    :optional => true
  )

  def main
    $quick       = options[:quick]
    $run_all     = options[:all]
    $git         = options[:git]
    $reset       = options[:reset]
    $app_root    = options[:app]
    $debug_steps = options[:debug_steps]

    pfn = progress_file_name()

    if $reset or not(File.file?(pfn))
      File.open(pfn, "w") { |f| f.puts("---\n") }
      exit
    end

    h = YAML.load_file(pfn) || {}
    h[:app_root] = ($app_root || h[:app_root] || 'hydra_tutorial_app').strip.parameterize('_')
    h[:done]   ||= []
    $app_root = h[:app_root]

    if task_args and task_args.size > 0
      tasks = task_args.dup
    else
      tasks = all_tasks.reject { |t| h[:done].include?(t) }
      tasks = [tasks.first] unless $run_all
      tasks = [] if tasks == [nil]
    end

    if tasks.size > 0
      tasks.each do |t|
        if $debug_steps
          puts "Running: task=#{t.inspect}"
        else
          Tutorial.new.send(t)
        end
        h[:done] << t
        File.open(pfn, "w") { |f| f.puts(h.to_yaml) }
      end
    else
      puts "All tasks have been completed. Use --reset."
    end

    if $debug_steps
      run "cat #{pfn}", :verbose => false
      exit
    end

  end

  class Tutorial < Thor

    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [$base_templates_path]
    end

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

      We'll generate a stub application in the #{$app_root} 
      folder. You can change that using the --app option.
      }, STATEMENT
    end

    desc('install_ruby: FIX', 'FIX')
    def install_ruby
      return if $quick
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
      }, Thor::Shell::Color::RED

      continue_prompt

      end

    end

    desc('install_bundler_and_rails: FIX', 'FIX')
    def install_bundler_and_rails
      say %Q{
    We're going to install some prerequisite gems in order to create our 
    skeleton Rails application.
      }, STATEMENT
      run 'gem install bundler rails', :capture => true
    end

    desc('new_rails_app: FIX', 'FIX')
    def new_rails_app
      say %Q{
    Now we'll create the application.
      }, Thor::Shell::Color::YELLOW

      if File.exists? $app_root
        say %Q{
      #{$app_root} already exists. Either remove it or provide 
      a different application name using the --app option.
        }, Thor::Shell::Color::RED
        exit
      end

      run "rails new #{$app_root}", :capture => true
    end

    desc('git_initial_commit: FIX', 'FIX')
    def git_initial_commit
      say %Q{
    We will keep track of our work using Git so that you can see how
    the files in the project change from one step to the next.

    First, we'll initialize our project's Git repository.}, STATEMENT

      cmds = ["init", "add .", "commit -m"]
      run_git_commands(cmds, 'Initial commit')
    end

    desc('out_of_the_box: FIX', 'FIX')
    def out_of_the_box
      return if $quick
      say %Q{
    Here's a chance to look around. You can see the structure of 
    a Rails application. In particular, look at:
       ./app
       ./config
       ./lib
       Gemfile
      }, STATEMENT


      say %Q{
    If we launched the Rails application server, we can see the application 
    running in the browser and you can see if everything is working.
      }, STATEMENT

      inside $app_root do
        rails_server unless $quick
      end
    end

    desc('adding_dependencies: FIX', 'FIX')
    def adding_dependencies
      gem 'execjs'
      gem 'therubyracer'
    end

    desc('add_fedora_and_solr_with_hydrajetty: FIX', 'FIX')
    def add_fedora_and_solr_with_hydrajetty

      say %Q{
    Fedora runs as a Java servlet inside a container like Tomcat or Jetty.
    Hydra provides a bundled version of Fedora and Solr for 
    testing and development.
      }, STATEMENT

      say %Q{
    We'll download a copy now. It may take awhile.
      }, STATEMENT
      unless File.exists? '../jetty'
        git :clone => '-b 4.x git://github.com/projecthydra/hydra-jetty.git ../jetty'
      end
      run 'cp -R ../jetty jetty'

    end

    desc('jetty_configuration: FIX', 'FIX')
    def jetty_configuration 
      say %Q{
    We'll add some configuration yml files with information to connect 
    to Solr and Fedora.
      }, STATEMENT

      copy_file 'solr.yml', 'config/solr.yml'
      copy_file 'fedora.yml', 'config/fedora.yml'

      say %Q{
    Add the 'jettywrapper' gem, which adds Rake tasks for start and stop Jetty.
      }, STATEMENT

      gem 'jettywrapper'
      run 'bundle install'

      say %Q{
    Starting Jetty
      }, STATEMENT
      rake 'jetty:start'

      say %Q{ 
    Take a look around. Jetty should be running on port 8983. You can see 
    the Fedora server at:

      http://localhost:8983/fedora/

    And a Solr index at:

      http://localhost:8983/solr/development/admin/
      }, STATEMENT

      continue_prompt

    end

    # and then clean up some cruft
    desc('remove_public_index: FIX', 'FIX')
    def remove_public_index
      remove_file 'public/index.html'
    end

    desc('add_activefedora: FIX', 'FIX')
    def add_activefedora
      say %Q{
    The active-fedora gem provides a way to model Fedora objects within Ruby.
    It will help you create Ruby models for creating, updating and reading 
    objects from Fedora using a domain-specific language (DSL) similar 
    to the Rails' ActiveRecord.

    The om gem provides mechanisms for mapping XML documents into Ruby.

    We'll add both of these to the Gemfile.
      }, STATEMENT

      gem 'active-fedora'
      gem 'om'
      run 'bundle install'
    end

    desc('add_initial_model: FIX', 'FIX')
    def add_initial_model
      say %Q{ 
    Now we'll add a basic ActiveFedora stub model for a 'Record'. 
      }, STATEMENT

      copy_file "basic_af_model.rb", "app/models/record.rb"

      say %Q{ 
    It looks like this:
      }, STATEMENT

      print_wrapped File.read('app/models/record.rb')
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
        > obj.delete

      }, STATEMENT


      rails_console unless $quick
    end

    desc('enhance_model_with_contrieved_descmd: FIX', 'FIX')
    def enhance_model_with_contrieved_descmd
      say %Q{
    Instead of working with the Nokogiri XML document directly, we 
    can use OM to make querying an XML document easier. We'll replace the 
    previous Record with a OM-enabled document.
      }, STATEMENT
      copy_file "basic_om_model.rb", "app/models/record.rb"
    end

    desc('testing_the_contrieved_descmd: FIX', 'FIX')
    def testing_the_contrieved_descmd
      say %Q{
    If you launch the Rails interactive console, we can now create and 
    manipulate our object using methods provided by OM.

        > obj = Record.new
        > obj.descMetadata.title = "My object title"
        > obj.save
        > obj.descMetadata.content
        # => An XML document with the title "My object title"
      }, STATEMENT

      rails_console unless $quick
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
        # => An XML document with the title "My object title"
      }, STATEMENT

      insert_into_file "app/models/record.rb", :after => %Q{has_metadata :name => "descMetadata", :type => DatastreamMetadata\n} do
        "delegate :title, :to => 'descMetadata'\n"
      end
    end

    desc('add_mods_model_with_mods_descmd: FIX', 'FIX')
    def add_mods_model_with_mods_descmd
      say %Q{
    We'll now replace the contrieved XML metadata schema with a simple
    MODS-based example, using an OM terminology we prepared earlier.

    We'll put the MODS datastream in a separate module and file, so that
    it can be easily reused in other ActiveFedora-based objects.
      }, STATEMENT

      copy_file "basic_mods_model.rb", "app/models/record.rb"
      copy_file "mods_desc_metadata.rb", "app/models/mods_desc_metadata.rb"

      say %Q{
    If you launch the Rails interactive console, we can now create 
    and manipulate our object using methods provided by OM.

        > obj = Record.new
        > obj.title = "My object title"
        > obj.save
        > obj.descMetadata.content
        # => A MODS XML document
      }, STATEMENT

      rails_console unless $quick
    end

    desc('record_generator: FIX', 'FIX')
    def record_generator
      say %Q{ 
    Now that we've set up our model and successfully added content
    into Fedora, now we want to connect the model to a Rails web application.

    We'll start by using the standard Rails generators to create 
    a scaffold controller and views, which will give us a 
    place to start working.
      }, STATEMENT

      generate "scaffold_controller Record --no-helper --skip-test-framework"
      route "resources :records"

      say %Q{
    If you look in ./app/views/records, you can see a set of 
    Rails ERB templates.

    ./app/controlers/records_controller.rb contains the controller 
    that ties the model to the views.
      }, STATEMENT

      continue_prompt
    end

    desc('add_new_form: FIX', 'FIX')
    def add_new_form

      say %Q{
   The scaffold just provided the basic outline for an application, so 
   we need to provide the guts for the web form. Here's a simple one:
      }, STATEMENT

      copy_file "_form.html.erb", "app/views/records/_form.html.erb"
      copy_file "show.html.erb", "app/views/records/show.html.erb"
    end

    desc('check_it_out: FIX', 'FIX')
    def check_it_out

      say %Q{
   If we start the Rails server, we should now be able to visit the records
   in the browser, create new records, and edit existing records. 

   Start by creating a new record:
      }, STATEMENT

      rails_server '/records/new' unless $quick
    end


    desc('add_gems: FIX', 'FIX')
    def add_gems
      say %Q{
    Thus far, we've been using component parts of the Hydra framework, but 
    now we'll add in the whole framework so we can take advantage of common 
    patterns that have emerged in the Hydra community, including search, 
    gated discovery, etc.

    We'll add a few new gems:

      - blacklight provides a discovery interface on top of the Solr index

      - hydra-head provides a number of common Hydra patterns

      - devise is a standard Ruby gem for providing user-related 
            functions, like registration, sign-in, etc.

      }, STATEMENT

      if $git
        gem 'blacklight', :git => "git://github.com/projectblacklight/blacklight.git"
        gem 'hydra-head', :git => "git://github.com/projecthydra/hydra-head.git"
      else
        gem 'blacklight'
        gem 'hydra-head', ">= 4.1.1"
      end
      gem 'devise'

      run 'bundle install'
    end

    desc('run_generators: FIX', 'FIX')
    def run_generators

      say %Q{
    These gems provide generators for adding basic views, styles, and override 
    points into your application. We'll run these generators now.
      }, STATEMENT
      run 'rm config/solr.yml' # avoid meaningless conflict
      generate 'blacklight', '--devise'
      run 'rm config/solr.yml' # avoid meaningless conflict
      generate 'hydra:head', 'User'
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

      rails_server('/records/new') unless $quick
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

end

HydraTutorialApp.start
