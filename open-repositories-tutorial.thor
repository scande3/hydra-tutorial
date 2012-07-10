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

class HydraOpenRepositoriesTutorialApp < Thor::Group
  include Thor::Actions
  include Rails::Generators::Actions

  class_option :quick, :default => false

  def welcome
    $quick = options[:quick]
    say %Q{
    Welcome to this Hydra tutorial. We're going to step through building a working
    Hydra application. We'll build the application gradually, starting by building
    our "business logic", wiring in HTML views, and then connecting it to our
    Rails application.
    }, STATEMENT

    name = ask %Q{
    What do you want to call your application?
    }, QUESTION unless $quick

    name ||= 'hydra_tutorial_app'

    dir = name.parameterize('_')

    $application_name = name
    $application_root = dir

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

  def cleanup
    inside $application_root do
      rake 'jetty:stop'
    end
  end

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
    We checked, and it looks like you might be using a system-wide ruby. We suggest
    you use somethng like rvm [1], rbenv [2], etc to manage your ruby projects.

    [1] http://rvm.io/
    [2] https://github.com/sstephenson/rbenv/
      }, Thor::Shell::Color::RED

      ask? %Q{
    You can continue and hope for the best, or go install one of these ruby managers, which may make your life easier.

    HIT <ENTER> KEY TO CONTINUE
      }, QUESTION
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
    We'll also start the Rails server so you can preview the application in your browser.

    Hit Ctrl-C (^C) when you're ready to continue.
      }, STATEMENT

      run "rails s"

    end
  end

  class BuildingABasicRailsApp < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "building_a_basic_rails_app")]
    end


    def adding_dependencies

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

    end

    def jetty_configuration 

      copy_file 'solr.yml', 'config/solr.yml'
      copy_file 'fedora.yml', 'config/fedora.yml'

      say %Q{
    We'll use jettywrapper to help start and stop the service.
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
      }, Thor::Shell::Color::GREEN unless $quick

    end

    # and then clean up some cruft
    def remove_public_index
      say %Q{
    We'll now remove the Rails directions from the application.
      }, STATEMENT
      inside $application_root do
        remove_file 'public/index.html'
      end
    end

  end

  class AddingOurModels < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "adding_our_models")]
    end

    def add_activefedora
      say %Q{
    We're going to use the active-fedora gem to help create our Fedora objects.
      }, STATEMENT
      gem 'active-fedora'
      gem 'om'
      run 'bundle install'

      ask %Q{
    Hit ENTER when you're ready to continue.
      }, Thor::Shell::Color::GREEN unless $quick
    end

    def add_initial_model
      copy_file "basic_af_model.rb", "app/models/record.rb"
      print_wrapped File.read('app/models/record.rb')
    end

    def rails_console_tour
      say %Q{
        obj = Record.new
        obj.descMetadata.content = '<my_xml_content />'
        obj.save
      }
    end

    def enhance_model_with_contrieved_descmd
      copy_file "basic_om_model.rb", "app/models/record.rb"
    end

    def add_mods_model_with_mods_descmd
      copy_file "basic_mods_model.rb", "app/models/record.rb"

      say %Q{
    And we have modeled how to make sense of the MODS XML datastream
      }
      copy_file "mods_desc_metadata.rb", "app/models/mods_desc_metadata.rb"
    end
  end

  class WiringItIntoRails < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def self.source_paths
      [File.join($base_templates_path, "wiring_it_into_rails")]
    end
    
    def record_generator
      generate "scaffold_controller Record --no-helper --skip-test-framework"
      route "resources :records"
    end

    def add_new_form
      copy_file "_form.html.erb", "app/views/records/_form.html.erb"
    end

  end

  class AddBlacklightAndHydra < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def add_blacklight
      gem 'blacklight'
    end

    def add_hydra
      gem 'hydra-head'
    end

    def add_devise
      gem 'devise'
    end

    def bundle_install
      run 'bundle install'
    end

    def run_generators
      generate 'blacklight', '--devise'
      generate 'hydra:head', 'User'
    end

    def db_migrate
      rake 'db:migrate'
      rake 'db:test:prepare'
    end

    def hydra_jetty_conf
      rake 'jetty:stop'
      rake 'hydra:jetty:config'
      rake 'jetty:start'
    end
  end

  class FixupForHydra < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    def update_controller
      inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
        "  include Hydra::AssetsControllerHelper\n"
      end

      insert_into_file "app/controllers/records_controller.rb", :after => "@record = Record.new(params[:record])\n" do
        "    apply_depositor_metadata(@record)\n"
      end
    end

    def update_model
      inject_into_class "app/models/record.rb", "Record" do
        "
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
        "
      end

    end

  end

  class AddFileAssets

  end

  class SprinkeSomeBootstrapCSS

  end

  class AddCollections

  end

  class AddRightsEnforcement

  end

  class AddTechnicalMetadata

  end
end

HydraOpenRepositoriesTutorialApp.start
