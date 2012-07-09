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
    require "gtk2"
    require "knjrbfw"
    require "gettext"
    require "sqlite3"
    
    
    #Set arguments (config).
    homedir = Knj::Os.homedir
    path = "#{homedir}/.ruby_do"
    Dir.mkdir(path) if !File.exists?(path)
    
    @args = {
      :sock_path => "#{path}/sock",
      :db_path => "#{path}/database.sqlite3"
    }.merge(args)
    
    
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
    
    
    #Start unix-socket to enable custom shortcuts.
    @unix_socket = Ruby_do::Unix_socket.new(:rdo => self)
    
    
    #Start plugins-engine.
    @plugin = Ruby_do::Plugin.new(:rdo => self)
    @plugin.register_plugins
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