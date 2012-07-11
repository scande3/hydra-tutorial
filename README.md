# Hydra Tutorial Application

The tutorial will:

* installs basic application prerequisites
* generate a new rails application
* walks through building a Hydra model:
  * first, as a AF::Base object with an XML datastream
  * then, with a simple OM terminology for a basic, contrived schema
  * finally, with a simple MODS-based terminology
* wire the model into Rails using standard Rails scaffolding
* adding blacklight and hydra-head gems for object discovery
* add a basic rspec/capybara test

Throughout the process, there's a number of prompts to poke around the
rails console and/or in a browser. At the end of the tutorial, you have
a working Hydra Head for adding MODS-based metadata records. In the next
release, I'll try to wire in file uploads, collections, etc. 

## Pre-requisites
 * ruby v 1.8.7 or higher
 * java 1.5 or higher (in order to run solr under a java servlet container)
 * [[RVM|https://rvm.beginrescueend.com/rvm/install/]] (recommended)

## Using
```bash
<INSTALL RUBY, e.g.:
$ curl -L https://get.rvm.io | bash -s stable --ruby
$ rvm install 1.9.3
  (See https://rvm.io/rvm/install/ )
>
$ gem install hydra-tutorial
$ hydra-tutorial
```

