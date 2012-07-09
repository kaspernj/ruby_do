class Ruby_do::Unix_socket
  def initialize(args)
    @args = args
    
    #Remove the sock-file if it already exists.
    File.unlink(@args[:rdo].args[:sock_path]) if File.exists?(@args[:rdo].args[:sock_path])
    
    #Start Unix-socket.
    require "socket"
    @usock = UNIXServer.new(@args[:rdo].args[:sock_path])
    
    #Remove the sock-file after this process is done.
    Kernel.at_exit do
      File.unlink(@args[:rdo].args[:sock_path]) if File.exists?(@args[:rdo].args[:sock_path])
    end
    
    #Start thread that listens for connections through the Unix-socket.
    Thread.new do
      begin
        while client = @usock.accept
          client.each_line do |line|
            line = line.strip
            
            if line.strip == "show_win_main"
              @args[:rdo].show_win_main
            else
              $stderr.puts "Unknown line: #{line}"
            end
          end
        end
      rescue => e
        $stderr.puts e.inspect
        $stderr.puts e.backtrace
      end
    end
  end
end