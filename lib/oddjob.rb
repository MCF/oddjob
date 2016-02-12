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

require 'webrick'
require 'oddjob/version'

module OddJob

  UPLOAD_PATH = '/oj_upload'
  INFO_PATH = '/oj_info'
  DEFAULT_PORT = 4400

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

  module HtmlRender
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
        "  </style>",
        "</head>",
        "<html><body>",
        "  <div class=\"header\">",
        "    <a href=\"https://github.com/MCF/oddjob\">OddJob on github</a>",
        "  </div>",
        "  <div style=\"clear:both;\"></div>",
           content.kind_of?(Array) ? content.join("\n") : content,
        "</body></html>",
      ].join("\n")
    end
  end

  class Info < WEBrick::HTTPServlet::AbstractServlet
    include HtmlRender

    def initialize(server, cmd_usage, *options)
      @usage = cmd_usage
      super(server, options)
    end

    def do_GET(request, response)
      response.status = 200
      response['Content-Type'] = "text/html"
      response.body = info_page
    end

    protected

    def info_page
      html = [
        "  <h1>#{File.basename($0)}</h1>",
        "  <p>Version: <strong>#{VERSION}</strong></p>"
      ]
      html << "  <pre>#{@usage}</pre>" unless @usage.nil?
      page(html, "Info")
    end

  end

  class FileUpload < WEBrick::HTTPServlet::AbstractServlet
    include HtmlRender

    def initialize(server, delay, save_directory, *options)
      @simulated_delay = delay
      @save_directory = save_directory
      super(server, options)
    end

    def do_POST(request, response)

      if @save_directory.nil?   # Request to server STDOUT.
        puts "-- BEGIN File Upload POST Request --"
        puts request
        puts "-- END File Upload POST Request --"
      end

      all_files = Array.new
      ['file', 'file[]'].each do |name|
        if request.query[name]
          request.query[name].each_data do |data|

            all_files.push(data.filename)

            if @save_directory.nil? # File contents to server STDOUT.
              puts "== BEGIN #{data.filename} Contents =="
              puts data.to_s
              puts "== END #{data.filename} Contents =="
            else
              output_name = unique_name(data.filename, @save_directory)
              File.open(output_name, "w"){|f| f.print(data.to_s)}
              puts "#{data.filename} uploaded, saved to #{output_name}"
            end
          end
        end
      end

      response.status = 200
      response['Content-type'] = 'text/html'
      response.body = uploaded_page(all_files)

      sleep(@simulated_delay)
    end

    def do_GET(request, response)
      response.status = 200
      response['Content-type'] = 'text/html'
      response.body = uploader_page
    end

    protected

    # Find a unique name in the same directory for the given file.
    #
    # If the desired name is in usenot add an index to the base name of the
    # file and increment the index until an unused name is found.  For example
    # if test.txt already existed then test_1.txt would be checked, followed
    # by test_2.txt, and so on.
    def unique_name(desired_name, save_directory)
      ext = File.extname(desired_name)
      base = File.basename(desired_name, ext)

      final_base = full_base = File.join(save_directory, base)
      i = 1
      while(File.exist?(final_base + ext))
        final_base = "#{full_base}_#{i}"
        i += 1
      end

      final_base + ext
    end

    def uploader_page
      html = [
        "<h1>Uploader</h1>",
        "<form action='' method='POST' enctype='multipart/form-data'>",
        "  <p>",
        "    Select file(s) to upload:",
        "    <br><br>",
        "    <input type='file' name='file' multiple='true'>",
        "    <br><br>",
        "    <input type='submit'>",
        "  </p>",
        "</form>",
      ]

      page(html, "Uploader")
    end

    def uploaded_page(names)
      html = [
        "<h1>Results</h1>",
        "<p>Uploaded:",
        "  <strong>#{names.join("</strong>, <strong>")}</strong>",
        "</p>",
        "<p><a href=''>Return to upload page</a></p>",
      ]

      page(html, "Upload Results")
    end
  end

end
