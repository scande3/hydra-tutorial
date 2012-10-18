#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'
require 'rails/generators/actions'
require 'active_support/core_ext/array/extract_options'

$base_templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

class HydraTutorialApp < Thor::Group
  class_option :quick, :default => false

  def welcome
    $quick = options[:quick]
    say %Q{
    Welcome to this Hydra tutorial. We're going to go through some steps to
    set up a working Hydra head. We'll build the application gradually, and give you
    opportunities to stop and look around on the way.
    }, Thor::Shell::Color::YELLOW

    if $quick
      say %Q{
    We'll quickly build the application, give you some Hydra models, and send you on your way.
      }, Thor::Shell::Color::YELLOW

    else
      say %Q{
    We'll go through this tour slowly, starting by creating a pure Rails application, 
    and then introduce Hydra components. If you want to speed things along, 
      }, Thor::Shell::Color::YELLOW

     exit unless yes? %Q{
    If you want to speed things along, you should quit this tutorial (by saying 'no'), 
    and run it again with ./tutorial.thor --quick=yes. 

    Do you want to continue at this pace? (y/n) }, Thor::Shell::Color::GREEN
    end
  end

  include Thor::Actions
  include Rails::Generators::Actions

  class Prerequisites < Thor::Group
    class_option :quick, :default => false
    include Thor::Actions
    include Rails::Generators::Actions

    def install_ruby
      return if $quick
      say %Q{ 
    Obviously, if you can run this tutorial, you have already installed ruby.
      }, Thor::Shell::Color::YELLOW


      ruby_executable = run 'which ruby', :capture => true

      say %Q{
    You are running this using:
    #{ruby_executable}
      }, Thor::Shell::Color::YELLOW

      if ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_Executable =~ /Users/
        say %Q{
    It looks like you're using rvm/rbenv/etc. (with a gemset?) We'll use this environment to build the application.
      }, Thor::Shell::Color::YELLOW

      else

      say %Q{
    We checked, and it looks like you might be using a system-wide ruby. We'd like to
    suggest you use somethng like rvm [1], rbenv [2], etc to manage your ruby projects.

    [1] http://rvm.io/
    [2] https://github.com/sstephenson/rbenv/
      }, Thor::Shell::Color::RED

      exit unless yes? %Q{
    You can continue and hope for the best, or go install one of these ruby managers, which may make your life easier.

    Do you want to continue anyway? (y/n)
      }, Thor::Shell::Color::GREEN
      end

    end

    def install_bundler_and_rails
      say %Q{
    We're going to install some prerequisite gems in order to create our skeleton Rails application.
      }, Thor::Shell::Color::YELLOW
      run 'gem install bundler rails'
    end

    def new_rails_app
      say %Q{
    Now we'll create the application.
      }, Thor::Shell::Color::YELLOW
      run 'rails new hydra_tutorial_app'
      run 'cd hydra_tutorial_app'

    end

    def out_of_the_box
      return if $quick
      say %Q{ 
    Here's a chance to look around. You can see the structure of a Rails application.
       ./app
       ./config
       ./lib
       Gemfile
      }

      ask %Q{

    Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN
    end

    # and then clean up some cruft
    def remove_public_index
      say %Q{
    We'll now remove the Rails directions from the application.
      }, Thor::Shell::Color::YELLOW
      inside 'hydra_tutorial_app' do
        remove_file 'public/index.html'
      end
    end
  end

  class BuildingABasicRailsApp < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "building_a_basic_rails_app")]
    end

    def notes
      say %Q{
    We're going to build an application to track (simplified) datasets and their metadata.
      }, Thor::Shell::Color::YELLOW
    end

    def as_if_this_was_just_a_rails_applications
      say %Q{
    If we wanted to build a Rails application to do this, we would add some models and controllers.

    Rails can help "scaffold" the application for us.
      }, Thor::Shell::Color::YELLOW

      generate 'scaffold', 'dataset', 'title', 'author', 'url', 'description:text'
      rake 'db:migrate'

      say %Q{
    This created a Dataset model (in ./app/models/dataset.rb), a controller, and some views.
      }, Thor::Shell::Color::YELLOW

      ask %Q{
    Take a look around. Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN
    end

    def but_maybe_we_want_to_store_our_metadata_as_xml
      say %Q{
    But it turns out a relational database is not a great place to store complex metadata objects, 
    with nesting, hierarchy, repetition, etc like we often fine in the digital library world. We'd 
    also like to store and manage our data in an exchangeable form rather than a custom-built database.

    In our world, we often find ourselves dealing with XML-based metadata. Fortunately, we have a gem called 'om' that can help us deal with XML metadata.
    To start using it, we need to add it to our Gemfile.
      }, Thor::Shell::Color::YELLOW

      gem 'om'
      run 'bundle install'

      say %Q{
    Now let's adapt our Dataset model to use OM. First we'll add some code that allows us to persist our
    OM Documents on the filesystem (in db/datasets) and then add a simple OM terminology as a drop-in
    replacement for the ActiveRecord scaffold object.

      }, Thor::Shell::Color::YELLOW

      run "mkdir db/datasets"
      copy_file "om_record.rb", "app/models/om_record.rb"

      say %Q{
    Press 'd' to see the difference between the Rails version and the OM version of Dataset.
      }, Thor::Shell::Color::YELLOW

      copy_file "dataset_simple_om.rb", "app/models/dataset.rb"

      ask %Q{ 
    Take a look around. 

    Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN

    end


    def stop_using_the_filesystem
      say %Q{
    Storing the documents on the filesystem has worked so far, but what if we wanted to start
    managing whole objects (instead of XML documents), version datastream, keep checksums...

    We use Fedora [3], and ActiveFedora to work with data in our repository. We also use Solr to
    index and provide searching, faceting, etc for our content. For now, you can just concentrate on
    Fedora. We'll have a section on Solr and discovery interfaces later.

    [3] http://fedora-commons.org 
      }, Thor::Shell::Color::YELLOW

      say %Q{
    Fedora runs as a java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled
    version of Fedora and Solr for testing and development.
      }, Thor::Shell::Color::YELLOW

      say %Q{
    We'll download a copy now. It may take awhile.
      }, Thor::Shell::Color::YELLOW
      unless File.exists? '../jetty'
        git :clone => 'git://github.com/projecthydra/hydra-jetty.git ../jetty'
      end
      run 'cp -R ../jetty jetty'
#      run 'rake hydra:jetty:config'

      say %Q{ 
    Now we're configure it and start the application.
      }, Thor::Shell::Color::YELLOW
      rake 'hydra:jetty:config'

      copy_file 'solr.yml', 'config/solr.yml'
      copy_file 'fedora.yml', 'config/fedora.yml'

      say %Q{
    And we'll use jettywrapper to help start and stop the service.
      }, Thor::Shell::Color::YELLOW

      gem 'jettywrapper'
      run 'bundle install'
      rake 'jetty:start'

      say %Q{ 
    Take a look around. Jetty should be running on port 8983. You can see the Fedora server at

      http://localhost:8983/fedora/

    And a Solr index at

      http://localhost:8983/solr/development/admin/
      }, Thor::Shell::Color::YELLOW

      ask %Q{
    Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN

    end

    def convert_our_model_to_activefedora
      say %Q{
    We'll update our Dataset object to use ActiveFedora.
      }, Thor::Shell::Color::YELLOW

      gem 'active-fedora'
      run 'bundle install'
      copy_file "dataset_af_om.rb", "app/models/dataset.rb"

      say %Q{
    You should be able to create new dataset objects and see them updated in Fedora.
      }, Thor::Shell::Color::YELLOW

      ask %Q{
    Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN
    end
  end

  class Application < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "application")]
    end

    # here are some gems that help
    def add_blacklight_and_hydra
      say %Q{
    Eventually, common patterns get packaged up into new gems.
      }, Thor::Shell::Color::YELLOW

      say %Q{ 
    We use blacklight to provide a search interface.
      }, Thor::Shell::Color::YELLOW

      gem 'blacklight'
      run 'bundle install'
      generate 'blacklight', '--devise'

      say %Q{
    And hydra-head bundles OM, ActiveFedora, etc for us. It also includes things like
    gated discovery and permissions (through hydra-access-controls).
      }, Thor::Shell::Color::YELLOW

      gem 'hydra-head', "~> 4.1"
      run 'bundle install'
      generate 'hydra:head', 'User'
    end

    def rake_db_migrate
      rake 'db:migrate'
      rake 'db:test:prepare'
    end

    def install_hydra_jetty
      if $quick # if we were in quick mode, we skipped this step from before.. 
        say %Q{
    Fedora runs as a java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled
    version of Fedora and Solr for testing and development.
        }, Thor::Shell::Color::YELLOW

        say %Q{
    We'll download a copy now. It may take awhile.
        }, Thor::Shell::Color::YELLOW

        unless File.exists? '../jetty'
          git :clone => 'git://github.com/projecthydra/hydra-jetty.git ../jetty'
        end
        run 'cp -R ../jetty jetty'

        rake 'hydra:jetty:config'

        gem 'jettywrapper'
        run 'bundle install'
        rake 'jetty:start'
      else

        rake 'jetty:stop'
        rake 'hydra:jetty:config'
        rake 'jetty:start'
      end

    end

    def fixup_ui
      remove_file 'app/assets/stylesheets/datasets.css.scss'
      remove_file 'app/assets/stylesheets/scaffolds.css.scss'
    end

    def fixup_datasets
      return if $quick
      say %Q{
    We need to make a couple of tweaks to our Dataset model and controller in order
    to make it a Hydra-compliant object.

    Because Hydra enforces access controls in the discovery layer (and, by default, no one
    has access), we need to teach our model and controller about the Hydra rightsMetadata model
    and have the controller tell the object who deposited it.
      }, Thor::Shell::Color::YELLOW

      copy_file "dataset_hydra_om.rb", "app/models/dataset.rb"

      inject_into_class "app/controllers/datasets_controller.rb", 'DatasetsController' do
        "  include Hydra::AssetsControllerHelper\n"
      end

      insert_into_file "app/controllers/datasets_controller.rb", :after => "@dataset = Dataset.new(params[:dataset])\n" do
        "    apply_depositor_metadata(@dataset)\n"
      end
    end

    def lets_make_a_better_terminology
      say %Q{
    So far, we've been working with a made-up XML schema, however, in the real world, we're probably
    dealing with more complex data in well-known standards like MODS.

    Now we'll replace our custom schema with a basic MODS schema.
      }, Thor::Shell::Color::YELLOW
      copy_file "mods_desc_metadata.rb", "app/models/mods_desc_metadata.rb"
      copy_file "dataset_hydra_mods_om.rb", "app/models/dataset.rb"
    end

  end

  class MakeItNice < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "make_it_nice")]
    end

    # now we want our app to do stuff.. so lets enhance our old models

    def some_better_views

    end

    def file_uploads

    end


    def sprinkle_some_css

    end

  end

  class Tests < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    # and write some tests

  end

  class InitialSteps < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    # here are some steps you can do to get started
    def create_a_user_account

    end

    def explore_the_application
      run 'rails s'

    end
  end

  
  class Cleanup < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    # and write some tests
    #
    def stop_jetty
      rake 'jetty:stop'
    end

  end

  def prerequisites
    Prerequisites.start
  end

  def building_a_basic_rails_app
    return if $quick

    inside 'hydra_tutorial_app' do
      BuildingABasicRailsApp.start
    end
  end
  
  def application
    inside 'hydra_tutorial_app' do
      Application.start
    end
  end

  def make_it_nice
    return if $quick
    inside 'hydra_tutorial_app' do
      MakeItNice.start
    end 
  end

  def tests
    inside 'hydra_tutorial_app' do
      Tests.start
    end
  end

  def initial_steps
    return if $quick
    inside 'hydra_tutorial_app' do
      InitialSteps.start
    end
  end

  def cleanup
    yes? "All Done?", Thor::Shell::Color::GREEN
    inside 'hydra_tutorial_app' do
      Cleanup.start
    end
  end

end

HydraTutorialApp.start
