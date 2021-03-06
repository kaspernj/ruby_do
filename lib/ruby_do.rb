class Ruby_do
  #Autoloader for subclasses.
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../include/#{name.to_s.downcase}.rb"
    return self.const_get(name)
  end
  
  attr_reader :args, :db, :ob, :plugin
  
  def initialize(args = {})
    #Require various used libs.
    require "rubygems"
    
    
    #Enable local dev-mode.
    if !Kernel.const_defined?(:Knj)
      if File.exists?("#{File.dirname(__FILE__)}/../../knjrbfw")
        require "#{File.dirname(__FILE__)}/../../knjrbfw/lib/knjrbfw.rb"
      else
        require "knjrbfw"
      end
    end
    
    if !Kernel.const_defined?(:Threadded_enumerator)
      if File.exists?("#{File.dirname(__FILE__)}/../../threadded_enumerator")
        require "#{File.dirname(__FILE__)}/../../threadded_enumerator/lib/threadded_enumerator.rb"
      else
        require "threadded_enumerator"
      end
    end
    
    
    #Set arguments (config).
    homedir = Knj::Os.homedir
    path = "#{homedir}/.ruby_do"
    Dir.mkdir(path) if !File.exists?(path)
    
    @args = {
      :sock_path => "#{path}/sock",
      :db_path => "#{path}/database.sqlite3",
      :run_path => "#{path}/run"
    }.merge(args)
    
    
    #Checks if the run-file exists and creates it if not.
    if File.exists?(@args[:run_path])
      pid = File.read(@args[:run_path]).to_i
      procs = Knj::Unix_proc.list("pids" => [pid])
      if !procs.empty?
        Knj.p procs
        puts "Ruby-Do is already running. Trying to show main window..."
        require "socket"
        UNIXSocket.open(@args[:sock_path]) do |sock|
          sock.puts "show_win_main"
        end
        
        exit
        #raise sprintf(_("Ruby-Do is already running with PID '%s'."), pid)
      end
    end
    
    #Create run-file with PID.
    File.open(@args[:run_path], "w") do |fp|
      fp.write(Process.pid)
    end
    
    #Remove run-file when application exits.
    Kernel.at_exit do
      File.unlink(@args[:run_path])
    end
    
    
    #Require the rest of the heavy libs.
    require "gtk2"
    require "gettext"
    require "sqlite3"
    
    
    #Load database.
    @db = Knj::Db.new(
      :type => "sqlite3",
      :path => @args[:db_path],
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    
    
    #Update database structure.
    Knj::Db::Revision.new.init_db("db" => @db, "schema" => Ruby_do::Database::SCHEMA)
    
    
    #Object framework.
    @ob = Knj::Objects.new(
      :datarow => true,
      :class_path => "#{File.dirname(__FILE__)}/../models",
      :class_pre => "",
      :db => @db,
      :module => Ruby_do::Models
    )
    
    
    
    #Start options-module.
    Knj::Opts.init("knjdb" => @db, "table" => "Option")
    
    
    #Start unix-socket to enable custom shortcuts.
    @unix_socket = Ruby_do::Unix_socket.new(:rdo => self)
    
    
    #Start plugins-engine.
    @plugin = Ruby_do::Plugin.new(:rdo => self)
    @plugin.register_plugins
    
    
    #Show main window if it is not set to be skipped.
    val = Knj::Opts.get("skip_main_on_startup").to_i
    if val != 1
      self.show_win_main
    end
  end
  
  #Shows the main window. If already shown then tries to give it focus.
  def show_win_main
    if !@win_main
      @win_main = Ruby_do::Gui::Win_main.new(:rdo => self)
    end
    
    @win_main.show
  end
  
  #Opens the properties-window or focuses it if it is already open.
  def show_win_properties
    Knj::Gtk2::Window.unique!("preferences") do
      Ruby_do::Gui::Win_properties.new(:rdo => self)
    end
  end
  
  #Joins the Gtk-main-loop.
  def join
    Gtk.main
  end
end