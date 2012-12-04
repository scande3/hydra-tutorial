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
    say %Q{
  We'll launch the console again.\n}, STATEMENT
    say %Q{
  Hit Ctrl-D (^D) to stop the Rails console and continue this tutorial.\n}, WAIT
    run "rails c"
  end

  # Runs the Rails server for the user, optionally
  # directing their attention to a particular URL.
  def rails_server url = '/'
    return if @@conf.quick
    say %Q{
  We'll start the Rails server for you. It should be available in
  your browser at:

     http://localhost:3000#{url}\n}, STATEMENT
    say %Q{
  Hit Ctrl-C (^C) to stop the Rails server and continue this tutorial.\n}, WAIT
    run "rails s"
  end

  # Offers the user a continue prompt. This is relevant only if
  # the user is running all steps at once rather than one by one.
  def continue_prompt
    return if @@conf.quick
    return unless @@conf.run_all
    ask %Q{
  HIT <ENTER> KEY TO CONTINUE}, WAIT
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

  # get the say string for the named method using i18n gem
  def get_say_string(*params)
    vals=params[0]
    method=caller[0][/`.*'/][1..-2]
    key = "steps.#{method}"
    key << ".#{vals[:substep]}" if (!vals.nil? && vals.include?(:substep))
    I18n.t(key,vals)
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
    return tasks.keys.reject { |t| t == 'main' }
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
    conf_name=@@conf.app
    say get_say_string(:conf_app=>conf_name,:var2=>'yo'),STATEMENT
  end

  desc('install_ruby: FIX', 'FIX')
  def install_ruby
    #return if @@conf.quick
    say get_say_string(:substep => 'one'), STATEMENT

    ruby_executable = run 'which ruby', :capture => true, :verbose => false
    ruby_executable.strip!

    say get_say_string(:substep => 'two', :ruby_executable => 'rvm ruby'), STATEMENT

    if (ruby_executable =~ /rvm/ or ruby_executable =~ /rbenv/ or ruby_executable =~ /home/ or ruby_executable =~ /Users/)
      say say get_say_string(:substep => 'three'), STATEMENT
    else
      say say get_say_string(:substep => 'four'), WARNING

      continue_prompt
    end
  end

  desc('install_bundler_and_rails: FIX', 'FIX')
  def install_bundler_and_rails
    say %Q{
  We're going to install some prerequisite gems in order to create our
  skeleton Rails application.\n}, STATEMENT
    run 'gem install bundler rails', :capture => false
  end

  desc('new_rails_app: FIX', 'FIX')
  def new_rails_app
    say %Q{
  Now we'll create the application.\n}, STATEMENT

    if File.exists? @@conf.app
      say %Q{
  #{@@conf.app} already exists. Either remove it or provide
  a different application name using the --app option.}, WARNING
      exit
    end

    run "rails new #{@@conf.app}", :capture => false
  end

  desc('git_initial_commit: FIX', 'FIX')
  def git_initial_commit
    say %Q{
  We will keep track of our work using Git so that you can see how
  the files in the project change from one step to the next. To see
  the difference you can open a terminal in the Rails application
  directory and run the following Git command.

    git diff HEAD^1..HEAD

  Or you can simply run the tutorial with the --diff option.

  Alternatively, you can use a tool like Gitx to see the differences
  in the code from one step in the tutorial to the next.

  First, we'll initialize our project's Git repository.\n\n}, STATEMENT
    run_git('', 'init')
    run_git('Initial commit')
  end

  desc('out_of_the_box: FIX', 'FIX')
  def out_of_the_box
    say %Q{
  Here's a chance to look around. You can see the structure of
  a Rails application. In particular, look at:
     ./app
     ./config
     ./lib
     Gemfile

  If we launched the Rails application server, we can see the application
  running in the browser and you can see if everything is working.\n}, STATEMENT
    rails_server
  end

  desc('adding_dependencies: FIX', 'FIX')
  def adding_dependencies
    say %Q{
  Now we'll add some Javascript dependencies.\n}, STATEMENT
    gem_group :assets do
      gem 'execjs'
      gem 'therubyracer'
    end
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
    append_to_file '.gitignore', "\njetty\n"
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
  And we will add the 'jettywrapper' gem, which adds Rake tasks to start
  and stop Jetty.\n}, STATEMENT

    gem_group :development, :test do
      gem 'jettywrapper'
    end
    run 'bundle install', :capture => false
    run_git('Solr and Fedora configuration')
  end

  desc('starting_jetty: FIX', 'FIX')
  def starting_jetty
    say %Q{
  Now we'll start Jetty.\n}, STATEMENT
    rake 'jetty:start'

    say %Q{
  Jetty should be running on port 8983. You can see the Fedora server at:

    http://localhost:8983/fedora/

  And a Solr index at:

    http://localhost:8983/solr/development/admin/\n}, STATEMENT

    continue_prompt
  end

  desc('remove_public_index: FIX', 'FIX')
  def remove_public_index
    say %Q{
  Removing the default home page from Rails. We will replace it later.\n}, STATEMENT
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
    run 'bundle install', :capture => false
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

      # CREATE
      > obj = Record.new
      > xml = '<xyz><foo>ABC</foo><foo>DEF</foo><bar>123</bar></xyz>'
      > obj.descMetadata.content = xml
      > obj.save

      > pid = obj.pid

      # RETRIEVE
      > obj = Record.find(pid)
      > ds = obj.descMetadata
      > puts ds.content

      # UPDATE
      > doc = ds.ng_xml
      > elements = doc.xpath '//foo'
      > elements.each { |e| puts e }

      # Now check the Fedora object in the browser.
      #   -> open http://localhost:8983/fedora/objects
      #   -> click search
      #   -> click the hyperlink of the object's PID (eg, 'changeme:1')
      #   -> click hyperlink to view the object's datastreams list
      #   -> click hyperlink to view the content of the descMetadata datastream

      # Back in the Rails console.

      # DELETE
      > obj.delete
      > exit\n}, STATEMENT

    rails_console
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
  If we launch the Rails interactive console, you can now create and
  manipulate our object using methods provided by OM.

    > obj = Record.new
    > obj.descMetadata.title = "My object title"
    > obj.save

  Notice also that OM also makes it easy to instantiate an empty version
  of a datastream. This behavior is controlled by the code in the
  xml_template() method of our Record model. Having set a value for
  the title and saved the object, you can now take a look at the entire
  datastream spawned by OM according to the instructions in the
  xml_template() method:

    > puts obj.descMetadata.content

    > obj.delete
    > exit\n}, STATEMENT
    rails_console
  end

  desc('use_the_delegate_method: FIX', 'FIX')
  def use_the_delegate_method
    say %Q{
  We can use the delegate() method to tell the model object how
  to access its descMetadata attributes.\n\n}, STATEMENT

    loc = %Q{\nend\n}
    insert_into_file "app/models/record.rb", :before => loc do
      "\n  delegate :title, :to => 'descMetadata'"
    end
    run_git('Modify Record model to delegate title to descMetadata')

    say %Q{
  Back in the Rails console you can now access the title attribute directly
  from the object:

    > obj = Record.new
    > obj.title = "My object title"
    > obj.save
    > puts obj.descMetadata.content
    > puts obj.title.inspect
    > obj.delete
    > exit\n}, STATEMENT

    rails_console
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
    > puts obj.descMetadata.content
    > exit\n}, STATEMENT
    rails_console
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
  You can see a set of Rails ERB templates, along with a controller that
  ties the Record model to those view, if you look in the following
  directories of the application:

      app/controlers/records_controller.rb
      app/views/records/\n}, STATEMENT

    continue_prompt
  end

  desc('add_new_form: FIX', 'FIX')
  def add_new_form
    say %Q{
  The scaffold provided only the basic outline for an application, so
  we need to provide the guts for the web form.\n\n}, STATEMENT
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
    say %Q{
  If we start the Rails server, we should now be able to visit the records
  in the browser, create new records, and edit existing records.

  Start by creating a new record:\n}, STATEMENT
    rails_server '/records/new'
  end

  desc('add_hydra_gems: FIX', 'FIX')
  def add_hydra_gems
    say %Q{
  Thus far, we've been using component parts of the Hydra framework, but
  now we'll add in the whole framework so we can take advantage of common
  patterns that have emerged in the Hydra community, including search,
  gated discovery, etc.

  We'll add a few gems:

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
    run 'bundle install', :capture => false
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
  searches, etc. We'll run the migrations next:\n\n}, STATEMENT
    rake 'db:migrate'
    rake 'db:test:prepare'
    run_git('Ran db:migrate, which created db/schema.rb')
  end

  desc('hydra_jetty_config: FIX', 'FIX')
  def hydra_jetty_config
    say %Q{
  Hydra provides some configuration for Solr and Fedora. We will use them.\n}, STATEMENT
    rake 'jetty:stop'
    rake 'hydra:jetty:config'
    rake 'jetty:start'
  end

  desc('add_access_rights: FIX', 'FIX')
  def add_access_rights
    say %Q{
  We need to make a couple changes to our controller and model to make
  them fully-compliant objects by teaching them about access rights.

  We'll also update our controller to provide access controls on records.\n\n}, STATEMENT

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

    inject_into_class "app/controllers/records_controller.rb", 'RecordsController' do
      "  include Hydra::AccessControlsEnforcement\n" +
      "  before_filter :enforce_access_controls\n"
    end

    run_git('Modify controller and model to include access rights')
  end

  desc('check_catalog: FIX', 'FIX')
  def check_catalog
    say %Q{
  Blacklight and Hydra-Head have added some new functionality to the
  application. We can now look at a search interface (provided by Blacklight)
  and use gated discovery over our repository. By default, objects are only
  visible to their creator.

  First create a new user account:

      http://localhost:3000/users/sign_up

  Then create some Record objects:

      http://localhost:3000/records/new

  And then check the search catalog:

      http://localhost:3000/catalog\n}, STATEMENT

    # TODO: remove this monkey-patch fixing a bug in hydra-head.
    f = `bundle show hydra-head`
    f = "#{f.strip}/app/views/_user_util_links.html.erb"
    gsub_file f, /.+folder_index_path.+/, ''

    rails_server('/records/new')
  end

  desc('install_rspec: FIX', 'FIX')
  def install_rspec
    say %Q{
  One of the great things about the Rails framework is the strong
  testing ethic. We'll use rspec to write a couple tests for
  this application.\n\n}, STATEMENT
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
    say %Q{
  Here's a quick example of a test.\n\n}
    copy_file 'records_controller_spec.rb', 'spec/controllers/records_controller_spec.rb'
    run_git('Added a controller test')
    run 'rspec'
  end

  desc('install_capybara: FIX', 'FIX')
  def install_capybara
    say %Q{
  We also want to write integration tests to test the end-result that
  a user may see. We'll add the capybara gem to do that.\n\n}, STATEMENT
    gem_group :development, :test do
      gem 'capybara'
    end
    run 'bundle install', :cature => true
    run_git('Added capybara gem')
  end

  desc('write_integration_test: FIX', 'FIX')
  def write_integration_test
    say %Q{
  Here's a quick integration test that proves deposit works.\n}, STATEMENT
    copy_file 'integration_spec.rb', 'spec/integration/integration_spec.rb'
    run_git('Added an integration test')
  end

  desc('run_integration_test_fail: FIX', 'FIX')
  def run_integration_test_fail
    say %Q{
  Now that the integration spec is in place, when we try to run rspec,
  we'll get a test failure because it can't connect to Fedora.\n}, STATEMENT
    run 'rspec'
  end

  desc('add_jettywrapper_ci_task: FIX', 'FIX')
  def add_jettywrapper_ci_task
    say %Q{
  Instead, we need to add a new Rake task that knows how to wrap the
  test suite --  start jetty before running the tests and stop jetty
  at the end. We can use a feature provided by jettywrapper to do this.\n\n}, STATEMENT
    copy_file 'ci.rake', 'lib/tasks/ci.rake'
    run_git('Added ci task')
    rake 'jetty:stop'
    rake 'ci'
    rake 'jetty:start'
  end

  desc('add_coverage_stats: FIX', 'FIX')
  def add_coverage_stats
    say %Q{
  Now that we have tests, we also want to have some coverage statistics.\n}, STATEMENT

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

    say %Q{
  Go take a look at the coverage report, open the file coverage/index.html
  in your browser.\n}, STATEMENT
    continue_prompt
  end

  desc('add_file_uploads: FIX', 'FIX')
  def add_file_uploads
    say %Q{
  Now that we have a basic Hydra application working with metadata-only, we
  want to enhance that with the ability to upload files. Let's add a new
  datastream to our model.\n\n}, STATEMENT
    inject_into_class 'app/models/record.rb', 'Record' do
      "has_file_datastream :name => 'content', :type => ActiveFedora::Datastream\n"
    end
    run_git('Add file uploads to model')
  end

  # TODO: combine with previous task.
  desc('add_file_upload_controller: FIX', 'FIX')
  def add_file_upload_controller
    say %Q{
  And educate our controller for managing file objects.\n\n}, STATEMENT
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
    say %Q{
  And add a file upload field on the form.\n}, STATEMENT
    f = "app/views/records/_form.html.erb"
    remove_file f
    copy_file "_form.add_file_upload.html.erb", f
    run_git('Add file uploads to UI')
  end

  desc('fix_add_assets_links: FIX', 'FIX')
  def fix_add_assets_links
    say %Q{
  We'll add a little styling to the Hydra app and add a link to add a new
  Record in the header of the layout.\n\n}, STATEMENT
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
    say %Q{
  Before the tutorial ends, we'll give you a final chance to look
  at the web application.\n\n}, STATEMENT
    rake 'jetty:stop'
    rake 'jetty:start'
    rails_server
  end

  desc('stop_jetty: FIX', 'FIX')
  def stop_jetty
    say %Q{
  This is the end of the tutorial. We'll shut down the jetty server.\n}, STATEMENT
    rake 'jetty:stop'
  end


end


####
#
####

HydraTutorial.start
