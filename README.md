# souffle

An orchestrator for describing and building entire systems with [Chef](https://github.com/opscode/chef).

Currently we only support `AWS`, however we intend to add support for `Vagrant` and `Rackspace` quite soon.

## Setup

Example configuration file (/etc/souffle/souffle.rb):

```ruby
rack_environment "production"

aws_access_key "160147B34F7DCE679A6B"
aws_access_secret "e01a4cb196b092ca8e93a5e66837bb194e86a9b1"
aws_region "us-west-2"
aws_image_id "ami-1d75574f"
aws_instance_type "c1.medium"
key_name "josh"
```

## CLI

The `souffle` command line client can either be run standalone (with a single json provision) or as a webserver.
Running the service as a daemon automatically starts the webserver.

    Usage: souffle (options)
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

## Defining a system

As an example system we'll generate two nodes that both are provisioned with `chef-solo`, have 2 10GB `raid0` EBS drives attached and configured with `LVM`.

```json
{
  "provider": "aws",
  "user": "josh",
  "domain": "mydomain.com",
  "options": {
    "type": "chef-solo",
    "aws_ebs_size": 10,
    "volume_count": 2
  },
  "nodes": [
    {
      "name": "example_repo",
      "options": {
        "attributes": {
          "nginx": { "example_attribute": "blehk" }
        },
        "run_list": [ "role[nginx_server]" ]
      }
    },
    {
      "name": "example_srv",
      "options": {
        "attributes": {
          "gem": { "source": "http://gem.mydomain.com" }
        }
      },
      "run_list": [ "recipe[yum]", "recipe[gem]", "recipe[git]" ],
      "dependencies": [ "role[nginx_server]" ]
    }
  ]
}
```

### Attributes

Attributes work in a specific-wins merge for the json configuration. If you define a `configuration option`, it's applied unless a `system` level option overrides that, which is in tern applied unless a `node` level option overrides that.

This should be a familiar concept to those of who are using [Chef](https://github.com/opscode/chef). Similar to `environments`, `roles`, and `nodes`.

## REST Interface

You can start up the rest interface by starting `souffle` with the `-d` parameter. We do not currently have a web ui, however the webserver supports the following actions: `create`, `version`, `status`. The default path `/` returns the `version`.

<table>
  <tr>
    <th>Command</th><th>Url</th><th>Example</th>
  </tr>
  <tr>
    <td>version</td>
     <td>/, /version</td>
     <td>curl -sL http://localhost:8080/</td>
  </tr>
  <tr>
    <td>create</td>
    <td>/create</td>
    <td>curl -sL http://localhost:8080/create</td>
  </tr>
  <tr>
    <td>status (all)</td>
    <td>/status</td>
    <td>curl -sL http://localhost:8080/status</td>
  </tr>
  <tr>
    <td>status (specific)</td>
    <td>/status/<code>system</code></td>
    <td>curl -sL http://localhost:8080/status/<code>6cbb78b2925a</code></td>
  </tr>
</table>

### Creating a new system

There are two ways to create a new system, you can either create it with the `souffle` cli, or you can use the rest interface.

Both the cli and the rest interface use the standard `json` format for [defining systems](https://github.com/seryl/souffle#defining-a-system).

    # Running from the CLI
    souffle -j /path/to/system.json

    # Using cURL/HTTP
    curl -H "Content-Type: application/json" -X PUT -T /path/to/system.json http://localhost:8080/create

### Status

The `status` is returned in full `json` dump of the current system status.

## A note on tests

In order to avoid painfully silly charges and costs, all of the AWS tests
that require you to pay (spinning up machines, etc), will only run if you
have the environment variable `AWS_LIVE` set to `true`.

    AWS_LIVE=true rake

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
