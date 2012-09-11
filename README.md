# souffle

An orchestrator for describing and building entire systems with chef.

Supports AWS currently, Vagrant and Rackspace coming soon.

## A note on tests

In order to avoid painfully silly charges and costs, all of the AWS tests
that require you to pay (spinning up machines, etc), will only run if you
have the environment variable `AWS_LIVE` set to `true`.

Ex:

    AWS_LIVE=true rake

## Setup

Example configuration file (/etc/souffle/souffle.rb):

    rack_environment "production"
    aws_access_key "160147B34F7DCE679A6B"
    aws_access_secret "e01a4cb196b092ca8e93a5e66837bb194e86a9b1"
    aws_region "us-west-2"
    aws_image_id "ami-1d75574f"
    aws_instance_type "c1.medium"
    aws_key_name "josh"

## CLI

    Usage: ./bin/souffle (options)
        -c, --config CONFIG              The configuration file to use
        -d, --daemonize                  Run the application as a daemon (forces `-s`)
        -E, --environment                The environment profile to use
        -g, --group GROUP                Group to set privilege to
        -j, --json JSON                  The json for a single provision (negates `-s`)
        -l, --log_level LEVEL            Set the log level (debug, info, warn, error, fatal)
        -L, --logfile LOG_LOCATION       Set the log file location, defaults to STDOUT
        -f, --pid PID_FILE               Set the PID file location, defaults to /tmp/souffle.pid
        -p, --provider PROVIDER          The provider to use (overrides config)
        -H, --hostname HOSTNAME          Hostname to listen on (default: 0.0.0.0)
        -P, --port PORT                  Port to listen on (default: 8080)
        -s, --server                     Start the application as a server
        -u, --user USER                  User to set privilege to
        -V, --vagrant_dir VAGRANT_DIR    The path to the base vagrant vm directory
        -v, --version                    Show souffle version
        -h, --help                       Show this message

## Contributing to souffle

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Josh Toft. See LICENSE.txt for
further details.
