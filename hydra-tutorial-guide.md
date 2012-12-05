# HYDRA TUTORIAL GUIDE
_auto generated on 2012-12-05 11:25:28 -0800_

## Step 1. Welcome
Welcome to this Hydra tutorial. We're going to step through building a
working Hydra application. We'll build the application gradually, starting by
building our "business logic", wiring in HTML views, and then connecting it
to our Rails application.

We'll generate a stub application in the hydra_tutorial_app  folder. You can change
that using the --app option.

This tutorial, a README file, and our bug tracker are at:

<https://github.com/projecthydra/hydra-tutorial>


## Step 2. Install Ruby
Obviously, if you can run this tutorial, you have already installed ruby. If you are on a Mac, you might need to install homebrew and do a `brew install v8` to get therubyracer gem to install.

We suggest you use somethng like rvm [1], rbenv [2], etc to manage
your ruby projects.

You can continue and hope for the best, or go install one of these
ruby managers, which may make your life easier.

  [1] <http://rvm.io/>

  [2] <https://github.com/sstephenson/rbenv/>


## Step 3. Install Bundler And Rails
We're going to install some prerequisite gems in order to create our skeleton Rails application.

## Step 4. New Rails App
Now we'll create the application.

## Step 5. Git Initial Commit
We will keep track of our work using Git so that you can see how
the files in the project change from one step to the next. To see
the difference you can open a terminal in the Rails application
directory and run the following Git command.

    git diff HEAD^1..HEAD

Or you can simply run the tutorial with the --diff option.

Alternatively, you can use a tool like Gitx to see the differences
in the code from one step in the tutorial to the next.

First, we'll initialize our project's Git repository.


## Step 6. Out Of The Box
Here's a chance to look around. You can see the structure of
a Rails application. In particular, look at:

    ./app
    ./config
    ./lib
    Gemfile

If we launched the Rails application server, we can see the application
running in the browser and you can see if everything is working.


## Step 7. Adding Dependencies
Now we'll add some Javascript dependencies.

## Step 8. Add Fedora And Solr With Hydrajetty
Fedora runs as a Java servlet inside a container like Tomcat or Jetty. Hydra provides a bundled version of Fedora and Solr for testing and development.

We'll download it now and put a copy into your application's directory. This might take awhile.

## Step 9. Jetty Configuration
We'll add some configuration yml files with information to connect to Solr and Fedora.

And we will add the 'jettywrapper' gem, which adds Rake tasks to start and stop Jetty.

## Step 10. Starting Jetty
Now we'll start Jetty

Jetty should be running on port 8983. You can see the Fedora server at:

  <http://localhost:8983/fedora/>

And a Solr index at:

  <http://localhost:8983/solr/#/development>


## Step 11. Remove Public Index
Removing the default home page from Rails. We will replace it later.

## Step 12. Add Activefedora
The active-fedora gem provides a way to model Fedora objects within Ruby.
It will help you create Ruby models for creating, updating and reading
objects from Fedora using a domain-specific language (DSL) similar
to the Rails' ActiveRecord.

The om gem provides mechanisms for mapping XML documents into Ruby.

We'll add both of these to the Gemfile.

## Step 13. Add Initial Model
Now we'll add a basic ActiveFedora stub model for a 'Record'.

## Step 14. Rails Console Tour
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
    > exit


## Step 15. Enhance Model With Om Descmd
Instead of working with the Nokogiri XML document directly, we
can use OM to make querying an XML document easier. We'll replace the
previous Record with a OM-enabled document.

## Step 16. Experiment With Om Descmd
If we launch the Rails interactive console, you can now create and
manipulate our object using methods provided by OM.

    > obj = Record.new
    > obj.descMetadata.title = "My object title"
    > obj.save

Notice also that OM also makes it easy to instantiate an empty version
of a datastream. This behavior is controlled by the code in the
`xml_template()` method of our Record model. Having set a value for
the title and saved the object, you can now take a look at the entire
datastream spawned by OM according to the instructions in the
`xml_template()` method:

    > puts obj.descMetadata.content

    > obj.delete
    > exit


## Step 17. Use The Delegate Method
We can use the delegate() method to tell the model object how to access its descMetadata attributes.

Back in the Rails console you can now access the title attribute directly from the object:

    > obj = Record.new
    > obj.title = "My object title"
    > obj.save
    > puts obj.descMetadata.content
    > puts obj.title.inspect
    > obj.delete
    > exit


## Step 18. Add Mods Model With Mods Descmd
We'll now replace the minimal XML metadata schema with a simple
MODS-based example, using an OM terminology we prepared earlier.

We'll put the MODS datastream in a separate module and file, so that
it can be easily reused in other ActiveFedora-based objects.

## Step 19. Experiment With Mods Descmd
If you launch the Rails interactive console, we can now create
and manipulate our object using methods provided by OM.

    > obj = Record.new
    > obj.title = "My object title"
    > obj.save
    > puts obj.descMetadata.content
    > exit


## Step 20. Record Generator
Now that we've set up our model and successfully added content into Fedora, now we want to connect the model to a Rails web application.
We'll start by using the standard Rails generators to create a scaffold controller and views, which will give us a place to start working.

You can see a set of Rails ERB templates, along with a controller that
ties the Record model to those view, if you look in the following
directories of the application:

    app/controlers/records_controller.rb
    app/views/records/


## Step 21. Add New Form
The scaffold provided only the basic outline for an application, so we need to provide the guts for the web form.

## Step 22. Check The New Form
If we start the Rails server, we should now be able to visit the records
in the browser, create new records, and edit existing records.

Start by creating a new record:

## Step 23. Add Hydra Gems
Thus far, we've been using component parts of the Hydra framework, but
now we'll add in the whole framework so we can take advantage of common
patterns that have emerged in the Hydra community, including search,
gated discovery, etc.

We'll add a few gems:

  - blacklight provides a discovery interface on top of the Solr index

  - hydra-head provides a number of common Hydra patterns

  - devise is a standard Ruby gem for providing user-related
    functions, like registration, sign-in, etc.


## Step 24. Run Hydra Generators
These gems provide generators for adding basic views, styles, and override points into your application. We'll run these generators now.

## Step 25. Db Migrate
Blacklight uses a SQL database for keeping track of user bookmarks, searches, etc. We'll run the migrations next.

## Step 26. Hydra Jetty Config
Hydra provides some configuration for Solr and Fedora. We will use them.

## Step 27. Add Access Rights
We need to make a couple changes to our controller and model to make them fully-compliant objects by teaching them about access rights.
We'll also update our controller to provide access controls on records.

## Step 28. Check Catalog
Blacklight and Hydra-Head have added some new functionality to the
application. We can now look at a search interface (provided by Blacklight)
and use gated discovery over our repository. By default, objects are only
visible to their creator.

First create a new user account:

  <http://localhost:3000/users/sign_up>

Then create some Record objects:

  <http://localhost:3000/records/new>

And then check the search catalog:

  <http://localhost:3000/catalog>


## Step 29. Install Rspec
One of the great things about the Rails framework is the strong testing ethic. We'll use rspec to write a couple tests for this application.

## Step 30. Write Controller Test
Here's a quick example of a test.

## Step 31. Install Capybara
We also want to write integration tests to test the end-result that a user may see. We'll add the capybara gem to do that.

## Step 32. Write Integration Test
Here's a quick integration test that proves deposit works.

## Step 33. Run Integration Test Fail
Now that the integration spec is in place, when we try to run rspec, we'll get a test failure because it can't connect to Fedora.

## Step 34. Add Jettywrapper Ci Task
Instead, we need to add a new Rake task that knows how to wrap the test suite --  start jetty before running the tests and stop jetty at the end. We can use a feature provided by jettywrapper to do this.

## Step 35. Add Coverage Stats
Now that we have tests, we also want to have some coverage statistics.

Go take a look at the coverage report, open the file coverage/index.html in your browser.

## Step 36. Add File Uploads
Now that we have a basic Hydra application working with metadata-only, we want to enhance that with the ability to upload files. Let's add a new datastream to our model.

## Step 37. Add File Upload Controller
And educate our controller for managing file objects.

## Step 38. Add File Upload Ui
And add a file upload field on the form.

## Step 39. Fix Add Assets Links
We'll add a little styling to the Hydra app and add a link to add a new Record in the header of the layout.

## Step 40. Start Everything
Before the tutorial ends, we'll give you a final chance to look at the web application.

## Step 41. Stop Jetty
This is the end of the tutorial. We'll shut down the jetty server.

