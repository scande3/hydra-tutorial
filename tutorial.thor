#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'

$base_templates_path = File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

class HydraTutorialApp < Thor::Group
  class_option :quick, :default => false

  def welcome
    $quick = options[:quick]
    say %Q{
    Welcome to this Hydra tutorial. We're going to go through some steps to
    set up a working Hydra head. We'll build the application gradually, and give you
    opportunities to stop and look around on the way.
    }

    if $quick
      say %Q{
    We'll quickly build the application, give you some Hydra models, and send you on your way.
      }

    else
      say %Q{
    We'll go through this tour slowly, starting by creating a pure Rails application, 
    and then introduce Hydra components. If you want to speed things along, 
      }

     exit unless yes? %Q{
    If you want to speed things along, you should quit this tutorial (by saying 'no'), 
    and run it again with ./tutorial.thor --quick=yes. 

    Do you want to continue at this pace? (y/n) }
    end
  end

  include Thor::Actions

  class Prerequisites < Thor::Group
    class_option :quick, :default => false
    include Thor::Actions

    def install_ruby
      return if $quick
      say %Q{ 
    Obviously, if you can run this tutorial, you have already installed ruby.
      }

      ruby_executable = run 'which ruby', :capture => true

      say %Q{
    You are running this using:
    #{ruby_executable}
      }

      if ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_Executable =~ /Users/
        say %Q{
    It looks like you're using rvm/rbenv/etc. (with a gemset?) We'll use this environment to build the application.
      }

      else

      say %Q{
    We checked, and it looks like you might be using a system-wide ruby. We'd like to
    suggest you use somethng like rvm [1], rbenv [2], etc to manage your ruby projects.

    [1] http://rvm.io/
    [2] https://github.com/sstephenson/rbenv/
      }

      exit unless yes? %Q{
    You can continue and hope for the best, or go install one of these ruby managers, which may make your life easier.

    Do you want to continue anyway? (y/n)
      }
      end

    end

    def install_bundler_and_rails
      say %Q{
    We're going to install some prerequisite gems in order to create our skeleton Rails application.
      }
      run 'gem install bundler rails'
    end

    def new_rails_app
      say %Q{
    Now we'll create the application.
      }
      run 'rails new hydra_tutorial_app'
      run 'cd hydra_tutorial_app'

    end

    def out_of_the_box
      return if $quick
      ask %Q{ 
    Here's a chance to look around. You can see the structure of a Rails application.
       ./app
       ./config
       ./lib
       Gemfile

    Hit ENTER when you're ready to continue.
      }
    end

    # and then clean up some cruft
    def remove_public_index
      say %Q{
    We'll now remove the Rails directions from the application.
      }
      inside 'hydra_tutorial_app' do
        run 'rm public/index.html'
      end
    end
  end

  class BuildingABasicRailsApp < Thor::Group
    include Thor::Actions

    def self.source_paths
      [File.join($base_templates_path, "building_a_basic_rails_app")]
    end

    def notes
      say %Q{
    We're going to build an application to track (simplified) datasets and their metadata.
      }
    end

    def as_if_this_was_just_a_rails_applications
      say %Q{
    If we wanted to build a Rails application to do this, we would add some models and controllers.

    Rails can help "scaffold" the application for us.
      }

      run 'rails generate scaffold dataset title author url description:text'
      run 'rake db:migrate'

      say %Q{
    This created a Dataset model (in ./app/models/dataset.rb), a controller, and some views.
      }

      ask %Q{
    Take a look around. Hit ENTER when you're ready to continue.
      }
    end

    def but_maybe_we_want_to_store_our_metadata_as_xml
      say %Q{
    But it turns out a relational database is not a great place to store complex metadata objects, 
    with nesting, hierarchy, repetition, etc like we often fine in the digital library world. We'd 
    also like to store and manage our data in an exchangeable form rather than a custom-built database.

    In our world, we often find ourselves dealing with XML-based metadata. Fortunately, we have a gem called 'om' that can help us deal with XML metadata.
    To start using it, we need to add it to our Gemfile.
      }

      run %q{echo 'gem "om"' >> Gemfile}
      run 'bundle install'

      say %Q{
    Now let's adapt our Dataset model to use OM. Press 'd' to see the difference between the Rails version and the OM version.
      }

      run "mkdir db/datasets"
      copy_file "dataset_simple_om.rb", "app/models/dataset.rb"

      say %Q{
    Some caveats:
    For now, we'll pretend we're getting our metadata from somewhere on the filesystem.
      }


      ask %Q{ 
    Take a look around. Hit ENTER when you're ready to continue.
      }

      exit

    end

    # but then we want repeating fields
    # and tracking versioning..
    #
    # so we use XML and OM
    #
    # and we use Fedora and ActiveFedora
    #
    # and we want it to be searchable..
    #

    def install_hydra_jetty
      run 'git clone git://github.com/projecthydra/hydra-jetty.git jetty'
      run 'rake hydra:jetty:config'
    end

    # eventually, there are sharable, reusable components
  end

  class Application < Thor::Group
    include Thor::Actions

    # here are some gems that help
    def add_things_to_gemfile
      run %q{echo 'gem "blacklight"' >> Gemfile}
      run %q{echo 'gem "hydra-head"' >> Gemfile}
      run %q{echo 'gem "jettywrapper"' >> Gemfile}
    end

    def bundle_install
      run 'bundle install'
    end

    def run_blacklight_generators
      run 'rails generate blacklight --devise'
    end

    def run_hydra_generators
      run 'rails generate hydra:head User'
    end

    def rake_db_migrate
      run 'rake db:migrate'
      run 'rake db:test:prepare'
    end

    def install_hydra_jetty
      run 'git clone git://github.com/projecthydra/hydra-jetty.git jetty'
      run 'rake hydra:jetty:config'
    end

  end

  class Models < Thor::Group
    include Thor::Actions

    # now we want our app to do stuff.. so lets enhance our old models

  end

  class StartServices < Thor::Group
    include Thor::Actions

    def start_jetty
      run 'rake jetty:start'
    end

    def start_rails
      run 'rails server'
    end
  end

  class Tests < Thor::Group
    include Thor::Actions

    # and write some tests

  end

  class InitialSteps < Thor::Group
    include Thor::Actions

    # here are some steps you can do to get started
    
    def create_a_user_account

    end

    def explore_the_application

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
    exit
    inside 'hydra_tutorial_app' do
      Application.start
    end
  end

  def models
    inside 'hydra_tutorial_app' do
      Models.start
    end
  end

  def tests
    inside 'hydra_tutorial_app' do
      Tests.start
    end
  end

  def start_services
    inside 'hydra_tutorial_app' do
      StartServices.start
    end
  end

  def initial_steps
    inside 'hydra_tutorial_app' do
      InitialSteps.start
    end
  end

end

HydraTutorialApp.start
