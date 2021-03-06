#--
# Copyright (c) Mike Fellows
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#++

require 'ostruct'
require 'webrick'
require 'oddjob/version'

module OddJob

  UPLOAD_PATH = '/oj_upload'
  INFO_PATH = '/oj_info'
  DEFAULT_PORT = 4400

  ##
  # Start the oddjob server.
  #
  # +opts+ is a hash.  Allowed keys are:
  #
  # * +:serverroot+ - directory to serve (default CWD)
  # * +:savedirectory+ - where to save uploads (default dump to STDOUT)
  # * +:usagemessage+ - the command line usage message to dispaly on info page
  # * +:allowall+ - serve to clients other than on localhost? (default false)
  # * +:networkdelay+ - simulated network delay (default no delay).
  # * +:port+ - port to use. (default is in DEFAULT_PORT module constant)
  #
  # Runs the server until a TERM or INT signal is received (e.g. ctrl-c from
  # the command line).
  def OddJob.server(opts)
    defaults = {
      :serverroot     => ".",
      :savedirectory  => nil,
      :usagemessage   => nil,
      :allowall       => false,
      :networkdelay   => 0,
      :port           => DEFAULT_PORT
    }

    options = defaults.merge(opts)

    # Add any missing MIME types (http://bugs.ruby-lang.org/issues/5365)
    m_types = WEBrick::HTTPUtils::DefaultMimeTypes.dup
    m_types['js']  = 'application/javascript' unless m_types.has_key?('js')
    m_types['svg'] = 'image/svg+xml'          unless m_types.has_key?('svg')

    server = WEBrick::HTTPServer.new(
      :Port          =>  options[:port],
      :BindAddress   =>  options[:allowall] ? '0.0.0.0' : '127.0.0.1',
      :MimeTypes     =>  m_types,
      :DocumentRoot  =>  options[:serverroot]
    )

    server.mount(
      INFO_PATH,
      Info,
      options[:usagemessage]
    )

    server.mount(
      UPLOAD_PATH,
      FileUpload,
      options[:networkdelay],
      options[:savedirectory]
    )

    ['TERM', 'INT'].each { |signal| trap(signal){ server.shutdown } }

    server.start
  end

  ##
  # A very basic utility for rendering OddJob specific pages.

  module HtmlRender

    ##
    # Wrap +content+ in the standard page layout.  +title+ is set as the HTML
    # page's title.
    def page(content, title)
      [
        "<!DOCTYPE html>",
        "<head>",
        "  <title>OJ #{title}</title>",
        "  <style>",
        "  body {font:100% arial,sans-serif; margin:1.5em 5em 4em 5em;}",
        "  a {text-decoration:none; color:rgb(248,157,30)}",
        "  a:hover {color:rgb(239,131,0);}",
        "  .header {font-size:0.75em; float:right; margin-bottom: 2.0em;}",
        "  .fineprint {font-size:0.85em;}",
        "  li {margin-bottom:0.4em;}",
        "  </style>",
        "</head>",
        "<html><body>",
        "  <div class=\"header\">",
        "    <em>v#{VERSION}</em>",
        "    <a href=\"https://github.com/MCF/oddjob\">OddJob on github</a>",
        "  </div>",
        "  <div style=\"clear:both;\"></div>",
           content.kind_of?(Array) ? content.join("\n") : content,
        "</body></html>",
      ].join("\n")
    end
  end

  ##
  # Webrick servlet for creating the information page.

  class Info < WEBrick::HTTPServlet::AbstractServlet
    include HtmlRender

    ##
    # Standard servlet initialization function with an additional
    # +cmd_usage+ argument for specifying the command line usage
    # of the OddJob module's calling entity.
    def initialize(server, cmd_usage, *options)
      @usage = cmd_usage
      super(server, options)
    end

    ##
    # Respond to get request, returns informational page.
    def do_GET(request, response)
      response.status = 200
      response['Content-Type'] = "text/html"
      response.body = info_page
    end

    protected

    ##
    # Render the HTML for the informational page.
    def info_page
      html = [
        "  <h2>#{File.basename($0)}</h2>",
        "  <p>Version: <strong>#{VERSION}</strong></p>"
      ]
      html << "  <pre>#{@usage}</pre>" unless @usage.nil?
      page(html, "Info")
    end

  end

  ##
  # Webrick servlet for upload pages.

  class FileUpload < WEBrick::HTTPServlet::AbstractServlet
    include HtmlRender

    ##
    # Standard servlet initialization function with additional arguments.
    #
    # +delay+ is the seconds of simulated network delay to wait before
    # responding after an upload request.
    #
    # +save_directory+ is where uploaded files are saved.  If +save_directory+
    # is not set, or set to nil, uploaded files are not saved.  Instead the
    # entire http request is printed on STDOUT, followed by the name and
    # contents of each file.  Generally only useful for small text files.
    def initialize(server, delay, save_directory, *options)
      @simulated_delay = delay
      @save_directory = save_directory
      super(server, options)
    end

    ##
    # Handles webrick post request when uploading one or more files via a
    # standard HTML form submission.  The form should include an input of type
    # 'file'. See the page produced by the do_GET method for an example form.
    def do_POST(request, response)

      if @save_directory.nil?   # Request to server STDOUT.
        puts "-- BEGIN File Upload POST Request --"
        puts request
        puts "-- END File Upload POST Request --"
      end

      all_uploads = Array.new
      ['file', 'file[]'].each do |name|
        if request.query[name]
          request.query[name].each_data do |data|
            upload = OpenStruct.new
            upload.name = data.filename

            if @save_directory.nil? # File contents to server STDOUT.
              puts "== BEGIN #{data.filename} Contents =="
              puts data.to_s
              puts "== END #{data.filename} Contents =="
            else
              output_name = unique_name(data.filename, @save_directory)
              File.open(output_name, "w"){|f| f.print(data.to_s)}
              puts "#{data.filename} uploaded, saved to #{output_name}"
              upload.output_name = File.expand_path(output_name)
            end

            all_uploads.push(upload)
          end
        end
      end

      response.status = 200
      response['Content-type'] = 'text/html'
      response.body = uploaded_page(all_uploads)

      sleep(@simulated_delay)
    end

    ##
    # Serves a simple file upload form.  Uploads submitted are handled by this
    # class' +do_Post+ method.
    def do_GET(request, response)
      response.status = 200
      response['Content-type'] = 'text/html'
      response.body = uploader_page
    end

    protected

    ##
    # Finds a unique name in the same directory for the given file.
    #
    # The uploaded file will be renamed if a file by that name already exists.
    # An index number is added to the file's base name to make it unique.  For
    # example if test.txt already existed then test_1.txt would be checked,
    # followed by test_2.txt, and so on.
    def unique_name(desired_name, save_directory)
      ext = File.extname(desired_name)
      base = File.basename(desired_name, ext)

      final_base = full_base = File.join(save_directory, base)
      i = 1
      while File.exist?(final_base + ext)
        final_base = "#{full_base}_#{i}"
        i += 1
      end

      final_base + ext
    end

    ##
    # Returns a string holding the full HTML page with the file upload form.
    def uploader_page
      html = [
        "<h2>Oddjob File Uploader</h2>",
        "<form action='' method='POST' enctype='multipart/form-data'>",
        "    <label for='file'>Select one or more files to upload:</label>",
        "    <br><br>",
        "    <input type='file' name='file' multiple='true'>",
        "    <br><br>",
        "    <input type='submit' value='Upload'>",
        "</form>",
        "<br>",
      ]

      if @save_directory.nil?
        html += [
          "<p class=\"fineprint\">",
          "Currently file uploads will <strong>not</strong> be saved, instead",
          "their contents will be printed to oddjob's standard output.",
          "In this configuration it is recommended that you only upload",
          "text files.",
          "</p>",
          "<p class=\"fineprint\">",
          "To upload any kind of file (binary or text) specify an output",
          "directory where files will be saved instead.  To see how visit the",
          "<a href=\"#{INFO_PATH}\">info page</a>.",
          "</p>",
        ]
      else
        html += [
          "<p class=\"fineprint\">",
          "Uploaded files will be saved in the",
          "<strong>#{File.expand_path(@save_directory)}</strong> directory.",
          "New files do not overwrite existing ones, instead they are given",
          "a unique numbered suffix.",
          "</p>",
        ]
      end

      page(html, "Uploader")
    end

    ##
    # Returns a string holding the result of the upload page submission.
    #
    # +names+ is an array of the uploaded file names.  These are names
    # as submitted.  Saved names may be different to avoid overwritting.
    def uploaded_page(uploads)
      html = [
        "<h2>Results</h2>",
        "<p>Uploaded:</p>",
        "<ul>",
      ]

      uploads.each do |upload|
        html += [
          "<li>",
          "<strong>#{upload.name}</strong>",
          upload.output_name ? " - saved to: #{upload.output_name}" : "",
          "</li>",
        ]
      end

      html += [
        "</ul>",
        "<p><a href=''>Return to upload page</a></p>",
      ]

      page(html, "Upload Results")
    end
  end

end
