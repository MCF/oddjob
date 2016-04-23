# oddjob #

[![Gem Version](https://badge.fury.io/rb/oddjob.svg)](https://badge.fury.io/rb/oddjob)

oddjob is a lightweight, command line controlled web server.  Built for
development and testing purposes, it can be used to serve static content for
local web development and has basic file upload capabilities.  It was initially
created when web browsers  become more restrictive about displaying local files
directly (*i.e.* file:// URLs).

oddjob's file upload endpoint can be used directly via forms or ajax request you
build yourself with a POST to the `/oj_upload` URL.  A basic file upload form
is also available via a GET request to that same URL.  Upon upload the default
behaviour is for the server to dump the entire upload POST request (header and
body), followed by the contents of each uploaded file to STDOUT.  This is
useful for small tests uploading text files, but if you need to upload larger
or binary format files tell oddjob to save the files to a directory instead. If
you upload and save the same file twice oddjob will not overwrite existing
saved files, instead a unique name is generated by adding a number to the end
of the file's name.

It is easy to hack the oddjob script to build quick test jigs for web
development. Sometimes using a simple test web server is easier than working
with a full fledged development or production environment.  To hack the code
download from the [github repo](https://github.com/MCF/oddjob) and run oddjob
out of the included `bin` directory.

## Installation ##

oddjob is available as a ruby gem.  To install it for general command line
use gem install:

```sh
gem install oddjob
```

In the unlikely event you would like it tied to a project add the following
line to the project's Gemfile:

```ruby
gem 'oddjob'
```

And then execute:

```sh
bundle install
```

You can also run oddjob directly from the git repo.  Clone the git repo and run
oddjob directly from the repo's bin directory.  For example:

```sh
git clone https://github.com/MCF/oddjob.git
./oddjob/bin/oddjob
```

## Usage ##

Command line usage is:

```
oddjob [OPTIONS] [server_root]
```

Where the optional server_root argument will be the served root directory.  The
default server root is the current working directory.

The default file upload behaviour will print the contents of the HTTP POST
request, and the contents of any uploaded files, to the server's STDOUT.  It is
recommended that you only upload text files in this case.  If an output
directory is specified all uploaded files are saved under their own names in
this directory.  Pre-existing files are not overwritten, instead a number is
added to the end of the new file names when saving.

If a simulated network delay is specified the server will pause that many
seconds before returning a response for file(s) uploaded to the file upload
path: `/oj_upload`.

The server will only respond to clients on localhost unless the `--allhosts`
option is specified.  Be aware of the security implications of allowing any
other host on your network to connect to the server if you use this option.

An informational page is available at the `/oj_info` path that includes the
command line usage.

The default server port is 4400.

Command line options:

    -d, --delay=value                File upload simulated network delay
    -a, --allhosts                   Allow connections from all hosts
    -o, --output=value               Directory to save uploaded files
    -p, --port=value                 Web server port to use
        --version                    Display the version number and exit

    -h, --help                       Display the usage message

To stop oddjob use the normal interrupt key combination (usually Ctrl-C).

## Examples ##

```sh
oddjob
```

Serves the files and directories in your current working directory at
`http://localhost:4400/`.  File upload is available at
`http://localhost:4400/oj_upload`

```sh
oddjob -p 2222 -o ./uploads ./my-site
```

Serves the contents of the `./my-site` directory at the
`http://localhost:2222/` URL, file upload is available at
`http://localhost:2222/oj_upload` files are saved to the
`./uploads` directory.

## Environment ##

oddjob is written in ruby and its only required dependency is a standard ruby
install.  oddjob makes use of ruby's built in
[webrick](http://ruby-doc.org/stdlib-2.0.0/libdoc/webrick/rdoc/WEBrick.html)
web server library.  No gems are required for running oddjob.  oddjob has been
tested with ruby 1.8.7 and up.

## Security ##

By default oddjob serves to clients on localhost only (that is: browsers
running on the same computer as oddjob).  If the `-a` option is used connections
from any client on your network are allowed.  If you do not trust the users on
your local network the `-a` option could be a security concern.  Anyone who can
connect to your IP address can browse and download the files served by oddjob.

oddjob will serve the contents of the directory specified on the command line,
or the current working directory if no directory is specified. It does no
filtering on the contents of the directory served, and the entire directory
tree below the top level directory is available for browsing.

## License ##

oddjob is released under an [MIT style license](MIT-LICENSE).

## Development ##

After checking out the repo, run `bundle install` to install dependencies. Then, run
`rake spec` to run the tests.  Oddjob can be run directly from the repo's bin
directory for easy testing.

## Contributing ##

Bug reports and pull requests are welcome on GitHub at
https://github.com/MCF/oddjob.
