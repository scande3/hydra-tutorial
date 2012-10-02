# Hydra Tutorial Application

The tutorial will:

* install all Hydra / Rails application prerequisites
* generate a new rails application
* walk through building a Hydra model:
  * first, as a AF::Base object with an XML datastream
  * then, with a simple OM terminology for a basic, contrived schema
  * finally, with a simple MODS-based terminology
* wire the model into Rails using standard Rails scaffolding
* add blacklight and hydra-head gems for object discovery
* add a basic rspec/capybara test

Throughout the process, there's a number of prompts to poke around the
rails console and/or in a browser. At the end of the tutorial, you have
a working Hydra Head for adding MODS-based metadata records. In the next
release, I'll try to wire in file uploads, collections, etc. 

## Pre-requisites
 * ruby v 1.8.7 or higher
 * java 1.5 or higher (in order to run solr under a java servlet container)
 * [RVM](https://rvm.beginrescueend.com/rvm/install/) (recommended)

ActiveFedora, Hydra, and Rails require some gems that compile binaries and
rely on installed system libraries like libxml, libxslt, and sqlite.  If
these aren't installed, the tutorial *will not function properly*.  If
something seems wrong, try running `bundle install` directly inside the
tutorial directory, and watch the output carefully.

## Using

* Install rvm to get Ruby:

```bash
$ curl -L https://get.rvm.io | bash -s stable --ruby
$ rvm install 1.9.3 # (See https://rvm.io/rvm/install/ )

# Consider a hydra-specific gemset
$ rvm use 1.9.3@hydra --create
```

* Install the gem and run the tutorial:

```bash
$ gem install hydra-tutorial
$ hydra-tutorial
```

If the tutorial app bombs with the `execJs: 'Could not find a JavaScript runtime'` 
error, you may need to install a Javascript runtime such as [node.js](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager).


## Testing

If you are playing with the tutorial source code and want to make a
change, you need to make sure the tutorial does what you expected!
You can run a non-interactive install from the root of the git project
checkout:

```bash
# If you've just finished another tutorial run, destroy it
$ rm hydra_tutorial_app/ -rf

# Just in case...
$ rake jetty:stop

# Bash "yes" command bypasses all interactive rails generators; "--quick"
# flag internally skips interactive consoles and server runs
$ yes | bin/hydra-tutorial  --quick
```
