$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "dnssd"
require "set"
require "socket"
require "webrick"
require 'net/http'
require 'uri'

require "injour/version"

Thread.abort_on_exception = true

module Injour
  InjourServer  = Struct.new(:name, :host, :port)
  PORT    = 43215
  SERVICE = "_injour._tcp"
  INJOUR_STATUS = File.join(ENV['HOME'], '.injour')

  class Done < RuntimeError; end

  def self.usage
    puts <<-HELP
Usage:

serve [<name>] [<port>]
  Start up your injour server as <name> on <port>. <name> is your username
  by default, and <port> is 43215. If you want to use the default <name>,
  pass it as "".

status/st [<message>]
  Publishes your [<message>] on Injour.

list/ls
  List all people who are publishing statuses on Injour

show user [<number_of_statuses_to_show>]
  Lists the last five updates from the 'user' by default. If you specify number_of_statuses_to_show, it will limit to that number.

help
  Displays this message.

    HELP
  end

  def self.retrieve_status_using_http(host, port, limit)
    Net::HTTP.get_response(URI.parse("http://#{host}:#{port}/?number=#{limit}")).body
  end  

  def self.get(name, limit = 10)
    host = find(name)

    if host.nil?
      STDERR.puts "ERROR: Unable to find #{name}"
    else
      puts retrieve_status_using_http(host.host, host.port, limit)
    end
  end

  def self.list(name = nil)
    service_list.each do |service|
      puts "=== #{service.name} on #{service.host}:#{service.port} ==="
      puts "* #{retrieve_status_using_http(service.host, service.port, 1)}"
    end
  end

  def self.discover(timeout=5)
    waiting_thread = Thread.current

    dns = DNSSD.browse SERVICE do |reply|
      DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
        service = InjourServer.new(reply.name, resolve_reply.target, resolve_reply.port)
        begin
          yield service
        rescue Done
          waiting_thread.run
        end
      end
    end

    puts "Gathering for up to #{timeout} seconds..."
    sleep timeout
    dns.stop
  end

  def self.service_list
    list = Set.new
    discover { |obj| list << obj }
    
    return list
  end

  def self.set_status(message)
    File.open(INJOUR_STATUS, 'a') { |file| file.puts("[#{Time.now.strftime("%d-%b-%Y %I:%M %p")}] #{message}") }
    if message !~ /\S/
      puts 'Your status has been cleared.'
    else
      puts "Your status has been set to '#{message}'."
    end
  end

  def self.find(name)
    found = nil

    discover do |obj|
      if obj.name == name
        found = obj
        raise Done
      end
    end

    return found
  end

  def self.get_status(limit = 5)
    File.read(INJOUR_STATUS).split("\n").reverse.slice(0, limit).join("\n")
  rescue # If file is not present, show an empty string
    ""  
  end

  def self.get_limit(query_string)
    (query_string.match(/number=(\d+)/)[1]).to_i || 5
  rescue
    5
  end

  def self.serve(name="", port=PORT)
    name = ENV['USER'] if name.empty?

    tr = DNSSD::TextRecord.new
    tr['description'] = "#{name}'s In/Out"
    
    DNSSD.register(name, SERVICE, "local", port.to_i, tr.encode) do |reply|
      puts "\nStarting #{name}'s Injour..."
    end
    
    # Don't log anything, everything goes in an abyss
    no_log = WEBrick::Log.new('/dev/null', WEBrick::Log::DEBUG)
    server = WEBrick::HTTPServer.new(:Port => port.to_i, :Logger => no_log, :AccessLog => no_log)

    # Open up a servlet, so that status can be viewed in a browser
    server.mount_proc("/") do |req, res|
      limit = get_limit(req.query_string)
      res.body = get_status(limit)
      res['Content-Type'] = "text/plain"
    end
    # Ctrl+C must quit it
    %w(INT TERM).each do |signal|
      trap signal do
        server.shutdown
        exit!
      end
    end
    # Start the server
    server.start
  end

end