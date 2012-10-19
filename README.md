# Hydra Tutorial Application

The tutorial will:

* Install all Hydra / Rails application prerequisites.
* Generate a new rails application.
* Walk through building a Hydra model:
  * First, as an ActiveFedora::Base object with an XML datastream.
  * Then, with a simple OM terminology for a basic, contrived schema
  * Finally, with a simple MODS-based terminology.
* Wire the model into Rails using standard Rails scaffolding.
* Add blacklight and hydra-head gems for object discovery.
* Add some basic Rspec and Capybara tests.

At the end of the tutorial, you will have a working Hydra Head for adding
MODS-based metadata records.

Throughout the process, there are several prompts to poke around the Rails
console and/or in a browser. In addition, Git is used to help you track changes
in the code from one step of the tutorial to the next.

In subsequent releases of the tutorial, we will try to wire in file uploads, 
collections, more complete test example, etc.

## Pre-requisites

This tutorial depends on the following:

 * A Unix-like operating system.
 * Ruby 1.8.7 or higher (but 1.9 is recommended).
 * Java 1.5 or higher (to run Solr under a Java servlet container).
 * [RVM](https://rvm.beginrescueend.com/rvm/install/) (recommended).
 * Git (recommended).

ActiveFedora, Hydra, and Rails require some gems that compile binaries and
rely on installed system libraries like libxml, libxslt, and sqlite. If
these aren't installed, the tutorial *will not function properly*. If
something seems wrong, try running `bundle install` directly inside the
tutorial directory, and watch the output carefully.

## Setup

Install rvm to get Ruby:

```bash
$ curl -L https://get.rvm.io | bash -s stable --ruby
$ rvm install 1.9.3 # (See https://rvm.io/rvm/install/ )
```

Consider using a hydra-specific gemset.

```bash
$ rvm use 1.9.3@hydra-tutorial --create
```

Install the hydra-tutorial gem:

```bash
$ gem install hydra-tutorial
```

## Running the tutorial

Run the tutorial one step at a time -- specifically, run the next step
in the tutorial:

```bash
$ hydra-tutorial
```

Run all remaining steps in the tutorial:

```bash
$ hydra-tutorial --run-all
```

Reset the tutorial back to the beginning:

```bash
$ hydra-tutorial --reset
$ rm -rf hydra_tutorial_app   # Or rename the directory.
```

Other options relevant to users:

    --no-git   # Do not create Git commits for each tutorial step.
    --diff     # Run git diff: previous vs. current code.
    --app FOO  # Set the name of the Rails application subdirectory.
               # The default is hydra_tutorial_app.

## Known issues

If the tutorial bombs with the `execJs: 'Could not find a JavaScript runtime'`
error, you may need to install a Javascript runtime such as
[node.js](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager).


## Developer notes

You can run the entire tutorial non-interactively from the root of the Git
project checkout:

```bash
$ bin/hydra-tutorial --run-all --quick
```
