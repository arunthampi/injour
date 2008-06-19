$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "dnssd"
require "set"
require "socket"
require "webrick"

require "injour/version"

Thread.abort_on_exception = true

module Injour
  Server  = Struct.new(:name, :host, :port)
  PORT    = 43215
  SERVICE = "_injour._tcp"
  INJOUR_STATUS = File.join(ENV['HOME'], '.injour')

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

show user
  Lists the last three updates from the 'user'

    HELP
  end

  def self.get(name)
    hosts = find(name)

    if hosts.empty?
      STDERR.puts "ERROR: Unable to find #{name}"
    elsif hosts.size > 1
      STDERR.puts "ERROR: Multiple possibles found:"
      hosts.each do |host|
        STDERR.puts "  #{host.name} (#{host.host}:#{host.port})"
      end
    else
      # Set is weird. There is no #[] or #at
      hosts.each do |host|
        sock = TCPSocket.open host.host, host.port
        puts sock.read
      end
    end
  end

  def self.list(name = nil)
    return get(name) if name
    hosts = []

    service = DNSSD.browse(SERVICE) do |reply|
      DNSSD.resolve(reply.name, reply.type, reply.domain) do |rr|
        host = Server.new(reply.name, rr.target, rr.port)
        unless hosts.include? host
          puts "#{host.name} (#{host.host}:#{host.port})"
          hosts << host
        end
      end
    end

    sleep 5
    service.stop
  end

  def self.set_status(message)
    File.open(INJOUR_STATUS, 'a') { |file| file.puts("[#{Time.now.strftime("%d-%b-%Y %I:%M %p")}] #{message}") }
    if message !~ /\S/
      puts 'Your status has been cleared.'
    else
      puts "Your status has been set to '#{message}'."
    end
  end

  def self.find(name, first=true)
    hosts = Set.new

    waiting = Thread.current

    service = DNSSD.browse(SERVICE) do |reply|
      if name === reply.name
        DNSSD.resolve(reply.name, reply.type, reply.domain) do |rr|
          hosts << Server.new(reply.name, rr.target, rr.port)
          waiting.run if first
        end
      end
    end

    sleep 5
    service.stop

    hosts
  end

  def self.get_status(limit = 3)
    File.read(INJOUR_STATUS).split("\n").reverse.slice(0, limit).join("\n")
  end

  def self.serve(name="", port=PORT)
    name = ENV['USER'] if name.empty?

    tr = DNSSD::TextRecord.new
    tr['description'] = "#{name}'s In/Out"
    
    DNSSD.register(name, SERVICE, "local", port.to_i, tr.encode) do |reply|
      puts "#{name}'s In/Out Records..."
    end
    
    log = WEBrick::Log.new(true) # true fools it
    def log.log(*anything); end # send it to the abyss
    
    # Open webrick babeh
    server = WEBrick::GenericServer.new(:Port => port.to_i, :Logger => log)
    # Get the latest status
    %w(INT TERM).each do |signal|
      trap signal do
        server.shutdown
        exit!
      end
    end
    # Get the latest status
    server.start { |socket| socket.print(get_status) }
  end

end