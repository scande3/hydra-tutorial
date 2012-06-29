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
    Now let's adapt our Dataset model to use OM. First we'll add some code that allows us to persist our
    OM Documents on the filesystem (in db/datasets) and then add a simple OM terminology as a drop-in
    replacement for the ActiveRecord scaffold object.

      }

      run "mkdir db/datasets"
      copy_file "om_record.rb", "app/models/om_record.rb"

      say %Q{
    Press 'd' to see the difference between the Rails version and the OM version of Dataset.
      }
      copy_file "dataset_simple_om.rb", "app/models/dataset.rb"

      ask %Q{ 
    Take a look around. 

    Hit ENTER when you're ready to continue.
      }

    end

    def lets_make_a_better_terminology
      say %Q{
    In the last step, we made up a basic XML schema for our data. In the real world, we're probably
    dealing with more complex data in well-known standards like MODS.

    Now we'll replace our custom schema with a basic MODS schema.
      }
      #copy_file "dataset_better_om.rb", "app/models/dataset.rb"
    end

    def stop_using_the_filesystem
      say %Q{
    Storing the documents on the filesystem has worked so far, but what if we wanted to start
    managing whole objects (instead of XML documents), version datastream, keep checksums...

    We use Fedora [3], and ActiveFedora to work with data in our repository. We also use Solr to
    index and provide searching, faceting, etc for our content. For now, you can just concentrate on
    Fedora. We'll have a section on Solr and discovery interfaces later.

    [3] http://fedora-commons.org 
      }

      say %Q{
    Fedora runs as a java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled
    version of Fedora and Solr for testing and development.
      }

      say %Q{
    We'll download a copy now. It may take awhile.
      }
      unless File.exists? '../jetty'
        run 'git clone git://github.com/projecthydra/hydra-jetty.git ../jetty'
      end
      run 'cp -R ../jetty jetty'
#      run 'rake hydra:jetty:config'

      say %Q{ 
    Now we're configure it and start the application.
      }
      run 'rake hydra:jetty:config'

      copy_file 'solr.yml', 'config/solr.yml'
      copy_file 'fedora.yml', 'config/fedora.yml'

      say %Q{
    And we'll use jettywrapper to help start and stop the service.
      }
      run %q{echo 'gem "jettywrapper"' >> Gemfile}
      run 'bundle install'
      run 'rake jetty:start'

      ask %Q{ 
    Take a look around. Jetty should be running on port 8983. You can see the Fedora server at

      http://localhost:8983/fedora/

    And a Solr index at

      http://localhost:8983/solr/development/admin/

    Hit ENTER when you're ready to continue.
      }

    end

    def convert_our_model_to_activefedora
      say %Q{
    We'll update our Dataset object to use ActiveFedora.
      }
      run %q{echo 'gem "active-fedora"' >> Gemfile}
      run 'bundle install'
      copy_file "dataset_af_om.rb", "app/models/dataset.rb"

      ask %Q{
    You should be able to create new dataset objects and see them updated in Fedora.

    Hit ENTER when you're ready to continue.
      }
    end
  end

  class Application < Thor::Group
    include Thor::Actions

    # here are some gems that help
    def add_blacklight_and_hydra
      say %Q{
    Eventually, common patterns get packaged up into new gems.
      }

      say %Q{ 
    We use blacklight to provide a search interface.
      }
      run %q{echo 'gem "blacklight"' >> Gemfile}
      run 'bundle install'
      run 'rails generate blacklight --devise'

      say %Q{
    And hydra-head bundles OM, ActiveFedora, etc for us. It also includes things like
    gated discovery and permissions (through hydra-access-controls).
      }
      run %Q{echo '\ngem "hydra-head"' >> Gemfile}
      run 'bundle install'
      run 'rails generate hydra:head User'
    end

    def rake_db_migrate
      run 'rake db:migrate'
      run 'rake db:test:prepare'
    end

    def install_hydra_jetty
      if $quick # if we were in quick mode, we skipped this step from before.. 
        say %Q{
    Fedora runs as a java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled
    version of Fedora and Solr for testing and development.
        }

        say %Q{
    We'll download a copy now. It may take awhile.
        }
        unless File.exists? '../jetty'
          run 'git clone git://github.com/projecthydra/hydra-jetty.git ../jetty'
        end
        run 'cp -R ../jetty jetty'

        run 'rake hydra:jetty:config'

        run %q{echo 'gem "jettywrapper"' >> Gemfile}
        run 'bundle install'
        run 'rake jetty:start'
      else

        run 'rake jetty:stop'
        run 'rake hydra:jetty:config'
        run 'rake jetty:start'
      end

    end

  end

  class MakeItNice < Thor::Group
    include Thor::Actions

    # now we want our app to do stuff.. so lets enhance our old models


    def sprinkle_some_css

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
      run 'rails s'

    end
  end

  
  class Cleanup < Thor::Group
    include Thor::Actions

    # and write some tests
    #
    def stop_jetty
      run 'rake jetty:stop'
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
    yes? "All Done?"
    inside 'hydra_tutorial_app' do
      Cleanup.start
    end
  end

end

HydraTutorialApp.start
