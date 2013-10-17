Quality Measure Engine
----------------------

This project is a library designed to calculate clinical quality measures over a given population. Quality measures are described via JSON and provide the details on what information is needed from a patient record to calculate a quality measure. The logic of the measure is described in JavaScript using the MapReduce algorithmic framework.

Calculating Quality Measures
----------------------------

Results of quality measures are represented by QME::QualityReport. This class provides ways to determine if a report has been calculated for a population in the database as well as ways to create jobs to run the calculations.

Environment
===========

This project currently uses Ruby 1.9.3 and is built using [Bundler](http://gembundler.com/). To get all of the dependencies for the project, first install bundler:

    gem install bundler

Then run bundler to grab all of the necessary gems:

    bundle install

The Quality Measure engine relies on a MongoDB [MongoDB](http://www.mongodb.org/) running a minimum of version 2.2.* or higher.  To get and install Mongo refer to:

    http://www.mongodb.org/display/DOCS/Quickstart

It also relies on [Redis](http://redis.io/) for background jobs via [Resque](https://github.com/defunkt/resque). To install Redis, please refer to:

    http://redis.io/download

You can also find information on Redis at the [Resque homepage](https://github.com/defunkt/resque). Resque is used by this project to calculate quality measures in  background jobs. We also use [resque-status](https://github.com/quirkey/resque-status). Please consult the resque-status instructions for working with the resque-web application if you would like to use it to monitor status.

Running Resque Workers
----------------------

QME::QualityReport will kick off background jobs with Resque. For these jobs to to actually get performed, you need to be running resque workers. This can be done with the following:

    QUEUE=* bundle exec rake resque:work

Testing
=======

This project uses [minitest](https://github.com/seattlerb/minitest) for testing. To run the suite, just enter the following:

    bundle exec rake test

The coverage of the test suite is monitored with [cover_me](https://github.com/markbates/cover_me). You can see the code coverage by looking in the coverage directory after running the test suite

Project Practices
=================

Please try to follow our [Coding Style Guides](http://github.com/eedrummer/styleguide). Additionally, we will be using git in a pattern similar to [Vincent Driessen's workflow](http://nvie.com/posts/a-successful-git-branching-model/). While feature branches are encouraged, they are not required to work on the project.

License
=======

Copyright 2012 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
