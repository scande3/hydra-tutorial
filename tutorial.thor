#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'thor/group'

class HydraTutorialApp < Thor::Group
  include Thor::Actions

  class Prerequisites < Thor::Group
    include Thor::Actions

    def install_ruby
      # since you're here, you've done this..
      #
      # but does your ruby install check out?
    end

    # lets get bundler and rails going
    def install_bundler_and_rails
      run 'gem install bundler rails'
    end

    # and start a new rails app
    def new_rails_app
      run 'rails new hydra_tutorial_app'
      run 'cd hydra_tutorial_app'
    end

    def out_of_the_box
      # it's just a framework..
      yes?
    end

    # and then clean up some cruft
    def remove_public_index
      within 'hydra_tutorial_app' do
        run 'rm public/index.html'
      end
    end
  end

  class BuildingABasicRailsApp < Thor::Group
    include Thor::Actions

    # lets build a basic app..
    # we want to track images and metadata
    #
    # so we build some models
    # and all is good..
    #
    # rake db:migrate
    #
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

  def application
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
