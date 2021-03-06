require 'bundler/setup'
require 'celluloid/autostart'
require 'celluloid/io'

class EchoServer
  include Celluloid::IO
  finalizer :finalize

  def initialize(host, port)
    puts "*** Starting echo server on #{host}:#{port}"

    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.server_update
  end

  def finalize
    @server.close if @server
  end

  def run
    loop {
      async.handle_connection @server.accept
    }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop { socket.write socket.readpartial(4096)}
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
    socket.close
  end
end

supervisor = EchoServer.supervise('127.0.0.1', 1234)
trap("INT") { supervisor.terminate; exit }
sleep