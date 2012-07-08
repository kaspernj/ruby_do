class Ruby_do
  class Gui
    def self.const_missing(name)
      require "#{File.dirname(__FILE__)}/../gui/#{name.to_s.downcase}.rb"
      return self.const_get(name)
    end
  end
  
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../include/#{name.to_s.downcase}.rb"
    return self.const_get(name)
  end
  
  attr_reader :args
  
  def initialize(args = {})
    require "rubygems"
    require "gtk2"
    require "knjrbfw"
    require "gettext"
    
    homedir = Knj::Os.homedir
    path = "#{homedir}/.ruby_do"
    Dir.mkdir(path) if !File.exists?(path)
    
    @args = {
      :sock_path => "#{path}/sock"
    }.merge(args)
    
    @unix_socket = Ruby_do::Unix_socket.new(:rdo => self)
  end
  
  def show_win_main
    if !@win_main
      @win_main = Ruby_do::Gui::Win_main.new(:rdo => self)
    end
    
    @win_main.show
  end
  
  def join
    Gtk.main
  end
end