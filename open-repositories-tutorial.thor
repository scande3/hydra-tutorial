#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'
require 'rails/generators/actions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'

$base_templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'or_templates'))
$application_name = ''
$application_root = ''

STATEMENT = Thor::Shell::Color::YELLOW
QUESTION = Thor::Shell::Color::GREEN
WAIT = Thor::Shell::Color::CYAN

class HydraOpenRepositoriesTutorialApp < Thor::Group
  include Thor::Actions
  include Rails::Generators::Actions

  module TutorialActions
    def continue_prompt
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
    We'll start the Rails server for you. It should be available in your browser at:

       http://localhost:3000#{url}
      }, STATEMENT

      say %Q{

    Hit Ctrl-C (^C) to stop the Rails server and continue this tutorial.
      }, WAIT

      run "rails s"
    end
  end

  include TutorialActions
  class_option :quick, :default => false
  class_option :git, :default => false

  def setup_parameters
    $quick = options[:quick]
    $git = options[:git]
  end

  def welcome
    say %Q{
    Welcome to this Hydra tutorial. We're going to step through building a working
    Hydra application. We'll build the application gradually, starting by building
    our "business logic", wiring in HTML views, and then connecting it to our
    Rails application.

    At several points in this tutorial, as we iteratively develop our files, you may
    be prompted to review conflicts between versions of files. It is safe to blindly
    accept the changes ('y'), however you may wish to view the diff ('d') to see the
    things we're change.
    }, STATEMENT

    name = ask %Q{
    What do you want to call your application?
    }, QUESTION unless $quick

    name = name.to_s.strip
    name = 'hydra_tutorial_app' if name.empty?


    $application_name = name

    dir = $application_name.parameterize('_')
    $application_root = dir

    if File.exists? $application_root
      say %Q{
        #{$application_root} already exists. Either remove it or provide a different
        application name.
      }, Thor::Shell::Color::RED
      exit
    end

    say %Q{
    We'll generate a stub application #{$application_name} into the folder 
    #{$application_root}. But, first, lets check your Ruby environment.
    }

  end

  def prerequisites
    Prerequisites.start
  end

  def building_a_basic_rails_app
    inside $application_root do
      BuildingABasicRailsApp.start
    end
  end
  
  def adding_our_models
    inside $application_root do
      AddingOurModels.start
    end
  end

  def wiring_it_into_rails 
    inside $application_root do
      WiringItIntoRails.start
    end
  end

  def add_blacklight_and_hydra
    inside $application_root do
      AddBlacklightAndHydra.start
    end
  end

  def fixup_for_hydra
    inside $application_root do
      FixupForHydra.start
    end
  end

  def add_tests
    inside $application_root do
      AddTests.start
    end
  end


  def sprinkle_some_styling
    inside $application_root do
      SprinkeSomeStyling.start
    end
  end

  def cleanup
    inside $application_root do
      Cleanup.start
    end
  end

  class Cleanup < Thor::Group

    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def start_everything
      say %Q{
  This is the end of the tutorial. We'll give you a final chance to look at the web application.
      }, STATEMENT
      rake 'jetty:stop'
      rake 'jetty:start'
      rails_server
    end

    def stop_jetty
      rake 'jetty:stop'
    end
  end

  class Prerequisites < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def install_ruby
      return if $quick
      say %Q{ 
    Obviously, if you can run this tutorial, you have already installed ruby.
      }, STATEMENT


      ruby_executable = run 'which ruby', :capture => true

      say %Q{
    You are running this using:
    #{ruby_executable}
      }, STATEMENT

      if ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_Executable =~ /Users/
        say %Q{
    It looks like you're using rvm/rbenv/etc. (with a gemset?) We'll use this environment to build the application.
      }, STATEMENT

      else

      say %Q{
    We checked, and it looks like you might be using a system-wide ruby. We suggest
    you use somethng like rvm [1], rbenv [2], etc to manage your ruby projects.

    You can continue and hope for the best, or go install one of these ruby managers, which may make your life easier.

    [1] http://rvm.io/
    [2] https://github.com/sstephenson/rbenv/
      }, Thor::Shell::Color::RED

      continue_prompt unless $quick

      end

    end

    def install_bundler_and_rails
      say %Q{
    We're going to install some prerequisite gems in order to create our skeleton Rails application.
      }, STATEMENT
      run 'gem install bundler rails'
    end

    def new_rails_app
      say %Q{
    Now we'll create the application.
      }, Thor::Shell::Color::YELLOW
      run "rails new #{$application_root}"
      run "cd #{$application_root}"
    end

    def out_of_the_box
      return if $quick
      say %Q{
    Here's a chance to look around. You can see the structure of a Rails application.
    In particular, look at:
       ./app
       ./config
       ./lib
       Gemfile
      }, STATEMENT


      say %Q{
    If we launched the Rails application server, we can see the application running in the browser
    and you can see if everything is working.
      }, STATEMENT


      inside $application_root do
        rails_server unless $quick
      end
    end
  end

  class BuildingABasicRailsApp < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "building_a_basic_rails_app")]
    end


    def adding_dependencies

      say %Q{
    Fedora runs as a Java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled
    version of Fedora and Solr for testing and development.
      }, STATEMENT

      say %Q{
    We'll download a copy now. It may take awhile.
      }, STATEMENT
      unless File.exists? '../jetty'
        git :clone => 'git://github.com/projecthydra/hydra-jetty.git ../jetty'
      end
      run 'cp -R ../jetty jetty'

    end

    def jetty_configuration 
      say %Q{
    We'll add some configuration yml files with information to connect to Solr and Fedora.
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
    Take a look around. Jetty should be running on port 8983. You can see the Fedora server at

      http://localhost:8983/fedora/

    And a Solr index at

      http://localhost:8983/solr/development/admin/
      }, STATEMENT

      continue_prompt unless $quick

    end

    # and then clean up some cruft
    def remove_public_index
      remove_file 'public/index.html'
    end

  end

  class AddingOurModels < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "adding_our_models")]
    end

    def add_activefedora
      say %Q{
    The active-fedora gem provides a way to model Fedora objects within Ruby. It will help
    you create Ruby models for creating, updating and reading objects from Fedora using a 
    domain-specific language (DSL) similar to the Rails' ActiveRecord.

    The om gem provides mechanisms for mapping XML documents into Ruby.

    We'll add both of these to the Gemfile.
      }, STATEMENT

      gem 'active-fedora'
      gem 'om'
      run 'bundle install'
    end

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

    def rails_console_tour

      say %Q{
        Now we'll give you a chance to look at the Record model. If you launch the 
        Rails interactive console, we can create and manipulate our object:

           ## CREATE
           > obj = Record.new
           # => #<Record:1571331701243443635 @pid="__DO_NOT_USE__" >
           > obj.descMetadata.content = 'e.g. <my_xml_content />'
           > obj.save

           > obj.pid  
           # => e.g. 'changeme:1'

           ## RETRIEVE
           > obj = Record.find('changeme:1')
           > ds = obj.descMetadata
           # => #<ActiveFedora::NokogiriDatastream:3283711306477137919 @pid="changeme:1" @dsid="descMetadata" @controlGroup="X" @dirty="false" @mimeType="text/xml" > 
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

    def enhance_model_with_contrieved_descmd
      say %Q{
    Instead of working with the Nokogiri XML document directly, we can use OM to
    make querying an XML document easier. We'll replace the previous Record with a
    OM-enabled document.
      }
      copy_file "basic_om_model.rb", "app/models/record.rb"
    end

    def testing_the_contrieved_descmd
      say %Q{
    If you launch the Rails interactive console, we can now create and manipulate our object
    using methods provided by OM.

        > obj = Record.new
        > obj.descMetadata.title = "My object title"
        > obj.save
        > obj.descMetadata.content
        # => An XML document with the title "My object title"
      }, STATEMENT

      rails_console unless $quick
    end

    def use_the_delegate_method
      say %Q{
    We can use the #delegate method to tell the model-object how to access these attributes.

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
    If you launch the Rails interactive console, we can now create and manipulate our object
    using methods provided by OM.

        > obj = Record.new
        > obj.title = "My object title"
        > obj.save
        > obj.descMetadata.content
        # => A MODS XML document
      }, STATEMENT

      rails_console unless $quick
    end
  end

  class WiringItIntoRails < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "wiring_it_into_rails")]
    end
    
    def record_generator
      say %Q{ 
    Now that we've set up our model and successfully added content into Fedora, now we want to
    connect the model to a Rails web application.

    We'll start by using the standard Rails generators to create a scaffold controller and views, 
    which will give us a place to start working.
      }, STATEMENT

      generate "scaffold_controller Record --no-helper --skip-test-framework"
      route "resources :records"

      say %Q{
    If you look in ./app/views/records, you can see a set of Rails ERB templates.

    ./app/controlers/records_controller.rb contains the controller that ties the model to the views.
      }, STATEMENT

      continue_prompt unless $quick
    end

    def add_new_form

      say %Q{
   The scaffold just provided the basic outline for an application, so we need to provide the guts for the 
   web form. Here's a simple one:
      }, STATEMENT

      copy_file "_form.html.erb", "app/views/records/_form.html.erb"
      copy_file "show.html.erb", "app/views/records/show.html.erb"
    end

    def check_it_out

      say %Q{
   If we start the Rails server, we should now be able to visit the records in the browser, create new records,
   and edit existing records. Start by creating a new record:
      }, STATEMENT

      rails_server '/records/new' unless $quick
    end

  end

  class AddBlacklightAndHydra < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def add_gems
      say %Q{
    Thus far, we've been using component parts of the Hydra framework, but now we'll add in the whole framework so
    we can take advantage of common patterns that have emerged in the Hydra community, including search, gated discovery,
    etc.

    We'll add a few new gems:

      - blacklight provides a discovery interface on top of the Solr index
      - hydra-head provides a number of common Hydra patterns
      - devise is a standard Ruby gem for providing user-related functions, like registration, sign-in, etc.

      }, STATEMENT

      if $git
        gem 'blacklight', :git => "git://github.com/projectblacklight/blacklight.git"
        gem 'hydra-head', :git => "git://github.com/projecthydra/hydra-head.git"
      else
        gem 'blacklight'
        gem 'hydra-head'
      end
      gem 'devise'

      run 'bundle install'
    end

    def run_generators

      say %Q{
    These gems provide generators for adding basic views, styles, and override points into your application. We'll run these
    generators now.
      }, STATEMENT
      run 'rm config/solr.yml' # avoid meaningless conflict
      generate 'blacklight', '--devise'
      run 'rm config/solr.yml' # avoid meaningless conflict
      generate 'hydra:head', 'User'
    end

    def db_migrate
      say %Q{
    Blacklight uses a SQL database for keeping track of user bookmarks, searches, etc. We'll run the migrations next:
      }, STATEMENT
      rake 'db:migrate'
      rake 'db:test:prepare'
    end

    def hydra_jetty_conf
      say %Q{
    Hydra provides some configuration for Solr and Fedora. Use them.
      }, STATEMENT
      rake 'jetty:stop'
      rake 'hydra:jetty:config'
      rake 'jetty:start'
    end
  end

  class FixupForHydra < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def do_it

      say %Q{
    We need to make a couple changes to our controller and model to make them fully-compliant objects by 
    teaching them about access rights.
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

    end

    def look_at_it
      say %Q{
    Blacklight and Hydra-Head have added some new functionality to the application. We can now look at a search interface 
    (provided by Blacklight) and use gated discovery over our repository. By default, objects are only visible to their
    creator.

    Create some new objects, and then check out the search catalog at:

       http://localhost:3000/catalog

      }, STATEMENT

      rails_server('/records/new') unless $quick
    end

  end

  class AddTests < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "add_tests")]
    end


    def install_rspec
      gem_group :development, :test do
        gem 'rspec'
        gem 'rspec-rails'
      end
      run 'bundle install'

      generate 'rspec:install'
    end
    
    def write_our_first_test
      copy_file 'records_controller_spec.rb', 'spec/controlers/records_controller_spec.rb'
    end

    def run_tests
      run 'rspec'
    end

    def a_model_test
   #   copy_file 'record_test.rb', 'spec/models/record_test.rb'
    end

  end

  class AddFileAssets < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "add_tests")]
    end


  end

  class SprinkeSomeStyling < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions
    include TutorialActions

    def self.source_paths
      [File.join($base_templates_path, "sprinkle_some_styling")]
    end


    def fix_add_assets_links
      copy_file "_add_assets_links.html.erb", "app/views/_add_assets_links.html.erb"
    end


  end

  class AddCollections

  end

  class AddRightsEnforcement

  end

  class AddTechnicalMetadata

  end
end

HydraOpenRepositoriesTutorialApp.start
