# oddjob #

oddjob is a small lightweight webserver built for development and testing purposes.  It can be used to serve static content to make webpage development easier.  This is especially useful now that many modern browsers have limits on loading and displaying files directly from your file system.

oddjob also has basic file upload capabilities built in.  You can POST directly to the */upload* URL and oddjob will accept the uploaded files.  By default oddjob simply prints out the entire upload POST request and then the contents off each uploaded file.  This is useful for small tests.  But if you need to upload large and/or non-text files you can tell oddjob to save the files to a directory instead.  If you upload the same file twice oddjob will not overwrite existing saved files, instead a number is added to the end of the uploaded file's name to make it unique before saving.

It is fairly easy to hack the oddjob script to build quick test jigs for web development.  Sometimes using a simple test webserver is easier than working with a full fledged development or production environment.

## Usage ##

Run oddjob with the `-h` or `--help` options to see a full description of the command usage.  oddjob also serves a short information page at the */info* URL that includes the command usage.

## Examples ##

    oddjob

Serves the contents of the current working directory at `http://localhost:2345/` and file upload is available at `http://localhost:2345/upload`

    oddjob -p 2222 -o ./uploaded_files ./myproject

Serves the contents of the `./myproject` directory at `http://localhost:2222/`, file upload is available at `http://localhost:2222/upload` and any uploaded files are saved in the `./uploaded_files` directory.

## Environment ##

oddjob is written in ruby and its only required dependency is a standard ruby install.  No extra gems are required, oddjob makes use of the built in ruby webserver library [webrick](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/webrick/rdoc/).  Currently oddjob has only been tested with ruby 1.8.7.

## Security ##

Currently oddjob serves to any client and does **not** limit connection to localhost.  If you are not behind a firewall this could present a serious security problem as anyone who can connect to your IP address can also browse the content served by oddjob.

oddjob will serve the contents of the directory specified on the command line, or the current working directory if no other directory is specified.  It does no filtering on the contents of the directory served, and the entire directory tree is available.

oddjob will bind to port 2345 by default.  A different port can be specified with the `-p` option.

## License ##

oddjob is available for public use and is supplied as is, with no implied warranty or fitness for any purpose whatsoever.
