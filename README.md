# 500Editor

## About

This is a simple ruby app allowing full-resolution photo editing of 500px photos with Aviary's photo editor widget.

It is a sinatra rack app designed to be deployed to the heroku cedar stack.

## Quick start

  $ git clone http://github.com/cbosco/the-500-editor
  $ cd the-500-editor
  $ touch ./.env

(See Requirements for the environmental variables.  You will need API keys from Aviary and 500px.)

  $ gem install bundler
  $ bundle install
  $ bundle exec shotgun -O config.ru


## Requirements

*ruby 1.9.2*

Environmental variables (`.env` locally)

  500PX_APIKEY=XXXXX
  500PX_SECRET=XXXXX
  AVIARY_APIKEY=XXXXX
  TMPDIR=./tmp
