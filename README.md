# Simple Server

[![Build Status](https://simple.semaphoreci.com/badges/simple-server/branches/master.svg)](https://simple.semaphoreci.com/projects/simple-server)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)


This is the backend for the Simple app to help track hypertensive patients across a population.

## Table of Contents

* [Development](#development)
* [Documentation](#documentation)
* [Deployment](#deployment)
* [Contributing](#contributing)

## Development

We have a `bin/setup` script that does most of the work of getting things setup, but you need a few things in place first.
If you are on a Mac, install [homebrew](https://brew.sh) and then install rbenv, redis, postgres@10, and yarn:

```
brew install rbenv ruby-build redis yarn postgresql@10
```

### bin/setup

To set up the Simple server for local development, clone the git repository and run the setup script included:

```
$ git clone git@github.com:simpledotorg/simple-server.git
$ cd simple-server
$ bin/setup
```

Note: If you already have a previous dev environment you're trying to refresh, it's easiest to drop your database run setup again.
```
$ rails db:drop
$ rails parallel:drop
$ bin/setup
```

If you encounter issues with this script, please open [a new issue with details](https://github.com/simpledotorg/simple-server/issues/new?title=Problems+with+bin/setup). Please include the entire log from bin/setup, as well as your computer / OS details.

### Note for Apple Silicon M1 Macs

With recent gem updates, all of our gems and dependencies now build ARM native on m1 macs. This means you do **not** need to use Rosetta to set up simple-server, and in fact using Rosetta will make things more complicated and confusing in day to day dev experience, and also hurts performance.

There is one possible caveat to this -- if you see any problems with google-protobuf, run the following:

```
gem uninstall google-protobuf
gem install google-protobuf -v 3.17.3 --platform=ruby
```

Then rerun bundler and everything will work. This is being tracked over in https://github.com/protocolbuffers/protobuf/issues/8682, hopefully there will be a better fix soon.

Beyond that, the setup instructions are now the same for Intel or M1 macs, as you can install homebrew normally and go from there.

#### Docker Compose

For quick development and testing, the server can be run locally using Docker Compose and the command:

```
docker compose up
```

The Dockerfile and docker-compose.yml files replicate the steps detailed below for manual installation, including the running of ngrok for local android development.

Once the Docker Compose server is running, the logs should provide the ngrok URL. For example: `SIMPLE_SERVER_HOST=91a705dde8c1.ngrok.io`. This is the value that should be used when setting up the Android app as described in the section below.

After a successful docker installation, an admin dashboard account is automatically created.

The default username and password for the dashboard account is:

```bash
username: admin@simple.org
password: Resolve2SaveLives
```

To remove the server and clear the volumes of database data, run the command:

```
docker compose down --volumes
```



#### Manual Setup

If the included `bin/setup` script fails for some reason, you can also manually
set up the application step by step. You can do so as follows.

First, you need to [install
ruby](https://www.ruby-lang.org/en/documentation/installation). It is
recommended to use [rbenv](https://github.com/rbenv/rbenv) to manage ruby
versions. Note that we currently use Bundler version 2.2.29, so that is also hardcoded below.

```bash
gem install bundler -v 2.2.29
bundle _2.2.29_ install
rake yarn:install
rails db:setup
```

We cleanup old migration files every once in a while and so running `db:migrate` would not work for the initial setup.
While setting up a fresh DB you will need to load the schema first with `db:schema:load`. `db:setup` already takes care of this.

#### Developing with the Android app

To run [simple-android](https://github.com/simpledotorg/simple-android/) app with the server running locally, you can
use [ngrok](https://ngrok.com).

```bash
brew install --cask ngrok
rails server
ngrok http 3000
```

The output of the ngrok command is HTTP and HTTPS URLs that can be used to access your local server. The HTTP URL cannot
be used since HTTP traffic will not be supported by the emulator. Configure the following places with the HTTPS URL.

In the `gradle.properties` file in the `simple-android` repository, set:
```
manifestEndpoint=<HTTPS URL>/api/
fallbackApiEndpoint=<HTTPS URL>/api/
```

In the `.env.development.local` (you can create this file if it doesn't exist),
```
SIMPLE_SERVER_HOST=<URL>  # i.e. without https://
SIMPLE_SERVER_HOST_PROTOCOL=https
```

Alternatively, you can make the change on the server side. In the server repo, open `app/views/api/manifests/show.json.jbuilder`. Change:
```
json.endpoint "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/"
```
to:
```
json.endpoint "<HTTPS URL>/api/"
```

#### Workers

We use [sidekiq](https://github.com/mperham/sidekiq) to run async tasks. To run, first make sure that redis (>4) is installed:

```bash
brew install redis

# after installing ensure your redis version is >4
redis-server -v
```

### Testing Email

We use [Mailcatcher](https://mailcatcher.me/) for testing email in development. Please use the
following to set it up on your machine.

_Note: Please don't add Mailcatcher to the `Gemfile`, as it causes conflicts._

```bash
gem install mailcatcher
mailcatcher
```

Now you should be able to see test emails at http://localhost:1080

### Testing Web Views

When testing web views like the progress tab or help screens, you will need to authenticate yourself with specific
request headers. You can run the following command to get a set of request headers for a user that you can attach to
your requests.

```
$ bundle exec rails get_user_credentials
```

The command will output a set of request headers that you can attach to your requests using tools like
[Postman](https://www.postman.com/) or [ModHeader](https://bewisse.com/modheader/).

```
Attach the following request headers to your requests:
Authorization: Bearer 9b54814d4b422ee37dad46e7ebee673c59eed088c264e479880cbe7fb5ac1ce7
X-User-ID: 452b96c2-e0cf-49e7-ab73-c328acd3f1e5
X-Facility-ID: dcda7d9d-48f9-47d2-b1cc-93d90c94386e
```

### Review Apps

Every pull request opened on the `simple-server` repo creates a [Heroku review app](https://devcenter.heroku.com/articles/github-integration-review-apps)
with the branch's code deployed to it. The review app is hosted at the URL [https://simple-review-pr-<PR number>.herokuapp.com](#).
This temporary environment can be used to test your changes in a production-like environment easily.

If you need to test your changes with a mobile app build as well, you can generate a mobile app build that points to
your review app. To do so:

* Navigate to the Github Actions page on the `simple-server` repository
* Select the "Mobile Review App Build" action
* Trigger a "workflow dispatch" at the top of the screen. You can keep the branch as `master` (it doesn't matter) and
  enter your PR number in the required input
* Once the Action is complete, its page will contain the APK as an artifact.

![trigger-mobile-review-app](https://user-images.githubusercontent.com/4241399/139230709-1604df1f-ad7d-4690-8bae-80d2a48cab37.gif)

<img width="1557" alt="Screen Shot 2021-10-28 at 3 11 44 PM" src="https://user-images.githubusercontent.com/4241399/139230802-39a38e26-7a96-4e00-9599-c8f7ce48d62d.png">


#### Testing messages

Messages sent through Twilio are currently fixed to specific countries. To override this setting, go to the [heroku console](https://dashboard.heroku.com/pipelines/30a12deb-f419-4dca-ad4a-6f26bf192e6f) and [add/update](https://devcenter.heroku.com/articles/config-vars#managing-config-vars) the `DEFAULT_COUNTRY` config variable on your review app to your desired country. The supported country codes are listed [here](https://github.com/simpledotorg/simple-server/blob/master/config/initializers/countries.rb).

```
# for US/Canada
DEFAULT_COUNTRY = US

# for UK
DEFAULT_COUNTRY = UK
```

Updating this config will automatically restart the review app and should allow one to receive messages in their appropriate ISD codes.

### Configuration

The app uses a base development configuration using `.env.development`. To add or override any configurations during
local development, create a `.env.development.local` file and add your necessary configurations there. If a
configuration change is applicable to all dev environments, ensure that it is added to `.env.development` and checked
into the codebase.

### Running the application locally

Foreman can be used to run the application locally. First, install foreman.

```bash
$ gem install foreman
```

Then, run the following command to start the Rails and Sidekiq together.

```bash
$ foreman start -f Procfile.dev
```

**Note:** Foreman will also execute the `whenever` gem in trial mode. This will validate that the `whenever`
configuration is valid, but will not actually schedule any cron jobs.

Alternatively, you can start these services locally _without_ foreman by using the following commands individually.

* Rails: `bundle exec rails server` or `bundle exec puma`
* Sidekiq: `bundle exec sidekiq`

### Running the tests

```bash
bin/rspec
```

Run tests interactively quickly while developing:


```
bin/guard
```

### Code

We use the [standard](https://github.com/testdouble/standard#how-do-i-run-standard-in-my-editor) gem as our default formatter and linter. To enable it directly in your editor, follow [this](https://github.com/testdouble/standard#how-do-i-run-standard-in-my-editor).

To check all the offenses throughout the codebase:

```bash
$ bin/rails standard
```

To automatically fix all offenses,

```bash
$ bundle exec standardrb --fix
```

**Note**: Some files have been temporarily ignored under a `.standard_todo.yml`. As we fix these files, remove them from the `yml` file so that they can be picked up by `standard` again for future offenses. Refer to [usage](https://github.com/testdouble/standard#usage) on how to generate todo files.

**Note**: Some files are permanently ignored under `.standard.yml` and do not require linting.

### Generating seed data

To generate seed (fake patients) data, execute the following command from the project root

```bash
$ bin/rails db:seed_patients
```

Need a larger dataset? Try adding the `SEED_TYPE` variable. (It takes longer to run, of course.) This works on all patient seeding commands:

```bash
  SEED_TYPE=medium bin/rails db:seed_patients
# You also may want an entirely new large dataset, with more facilities and regions. You can do that with a full reset:
SEED_TYPE=large bin/rails db:reset

Available sizes are `small`, `medium`, and `large`. (Large takes a LONG time to run. You probably don't need it.)

To purge the generated patient data, run

```bash
$ bin/rails db:purge_users_data
```

You can also purge and re-seed by running:

```bash
$ bin/rails db:purge_and_reseed
```

### Creating an admin user

Run the following command from the project root to create a new dashboard admin:
```bash
$ bin/rails 'create_admin_user[<name>,<email>,<password>]'
```

### View Sandbox data in your local environment

1. Follow the steps in the "How to add an SSH key..." section [here](https://github.com/simpledotorg/deployment) to add your SSH key to the deployment repo
2. Ask someone from the Simple team to add you as an admin to Sandbox
3. Create a password for your Sandbox account and use that to log into the Sandbox dashboard on https://api-sandbox.simple.org
4. Run `ssh deploy@ec2-13-235-33-14.ap-south-1.compute.amazonaws.com` to verify that your SSH access from step 1 was completed successfully.
5. Run `bundle exec cap sandbox db:pull` to sync Sandbox data with your local machine.
6. Use your Sandbox email and password to log into your local environment (http://localhost:3000).

### Profiling

We use the [vegeta](https://github.com/tsenart/vegeta) utility to run performance benchmarks. The suite and additional instructions are [here](./profiling/README.md).

## Documentation

### API

API Documentation can be accessed at `/api-docs` on local server and hosted at https://api.simple.org/api-docs

To regenerate the Swagger API documentation, run the following command.

```
$ bundle exec rake docs
```

### ADRs

Architecture decisions are captured in ADR format and are available in `/doc/arch`

### Wiki

Guides, instructions and long-form maintenance documentation can go in `/doc/wiki`

### ERD (Entity-Relationship Diagram)

These are not actively committed into the repository. But can be generated by running `bundle exec erd`

## Deployment

Simple Server is continuously deployed from master to all environments via [Semaphore Workflows](https://docs.semaphoreci.com/essentials/modeling-complex-workflows/) as long as the build passes. We use a mixture of tools under the hood for deployments:

* Ansible: Server management and configuration is done using Ansible. See the [deployment repository](https://github.com/simpledotorg/deployment/tree/master/ansible)
  for more information.
* Capistrano: Application code is deployed to servers for a specific country and environment using Capistrano.
* SemaphoreCI: Continuous deployment - all merges to master are auto-deployed to all environments.

If you need to make a manual production release, run the release script from master:

```
bin/release
```

This will create a git release tag and automatically trigger a deployment to all environments through Semaphore. You can monitor the deployment progress [in Semaphore](https://simple.semaphoreci.com/projects/simple-server) via the tagged release's workflow. Please make sure to copy / paste the changelog from `bin/release` so you can post it in the #releases channel.

### Deployment to a specific environment

* We use Capistrano [multi-config](https://github.com/railsware/capistrano-multiconfig) to do multi-country deploys.
* All `cap` commands are namespaced with the country name. For eg: `bundle exec india:sandbox deploy`.
* The available country names are listed under `config/deploy`. The subsequent envs, under the country directory, like
  `config/deploy/india/sandbox.rb`

Simple Server can be deployed to a specific environment of a specific country with the following command.

```bash
bundle exec cap <country_name>:<enviroment> deploy
# eg: bundle exec cap india:staging deploy
# or, bundle exec cap bangladesh:production deploy
```

Rake tasks can be run on the deployed server using Capistrano as well. For example,

```bash
bundle exec cap india:staging deploy:rake task=db:seed
```

### Deployment to a new environment

When setting up a new environment to deploy Simple Server to, follow these steps.

#### 1. Create a config file

Create a new file in `config/deploy/<env_name>.rb` for the new environment. It can be placed inside a subdirectory if
desired. Populate the new config file with relevant IP address info. Use an existing file for reference. For example,
the configuration for a deployment with two EC2 instances may look like:
```
server "ec2-12-111-34-45.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron whitelist_phone_numbers seed_data]
server "ec2-12-222-67-89.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
```

The first server runs the web application and cron tasks, the second server runs Sidekiq to process background jobs.

#### 2. Install Sidekiq

A one-time installation of Sidekiq is required in new environments. Run the following command:

```bash
bundle exec cap <environment> sidekiq:install
```

#### 2. Deploy

You can now run a regular Capistrano deployment:

```bash
bundle exec cap <environment> deploy
```

This may take a long time for the first deployment, since several dependencies (like Ruby) need to be installed.
Subsequent deployments will be much faster.

### Deployment Resources

The infrastructure setup including the ansible and terraform scripts are documented in the [deployment repository](https://github.com/simpledotorg/deployment).

## Contributing

If you're working on a project that will affect any of the indicators listed in [this document](https://docs.simple.org/), please contact the product / design team.
