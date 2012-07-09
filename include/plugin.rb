class Ruby_do::Plugin
  def self.const_missing(name)
    
  end
  
  attr_reader :plugins
  
  def register_plugins
    paths = [
      File.realpath("#{File.dirname(__FILE__)}/../../") #To enable developing of plugins in parent directory without having to do Gem-installs all the time.
    ]
    
    Gem.path.each do |gem_path|
      paths << "#{gem_path}/gems"
    end
    
    paths.each do |path|
      Dir.foreach(path) do |gem_dir|
        next if gem_dir == "." or gem_dir == ".." or gem_dir[0, 15] != "ruby_do_plugin_"
        
        match = gem_dir.match(/^([A-z_\d]+)(|-([\d\.]*))$/)
        next if !match
        next if @plugins.key?(match[1])
        classname = "#{match[1][0].upcase}#{match[1][1, match[1].length]}"
        
        begin
          require "#{path}/#{gem_dir}/lib/#{match[1]}"
          plugin = Kernel.const_get(classname).new(:rdo => @args[:rdo], :classname => match[1])
          @plugins[match[1]] = plugin
          
          model = @args[:rdo].ob.get_by(:Plugin, {
            "classname" => plugin.classname
          })
          
          if !model
            model = @args[:rdo].ob.add(:Plugin, {
              :classname => plugin.classname,
              :name => plugin.name
            })
          end
          
          plugin.model = model
          model.plugin = plugin
        rescue NameError => e
          $stderr.puts "Cant loading plugin '#{match[1]}' because of the following."
          $stderr.puts e.inspect
          $stderr.puts e.backtrace
        end
      end
    end
  end
  
  def initialize(args)
    @args = args
    @plugins = {}
  end
  
  def send(args)
    return Enumerator.new do |yielder|
      @plugins.each do |name, plugin_instance|
        plugin_model = @args[:rdo].ob.get_by(:Plugin, "classname" => plugin_instance.classname)
        next if !plugin_model or plugin_model[:active].to_i != 1
        
        begin
          enum = plugin_instance.on_search(args)
          enum.each do |res|
            yielder << res
          end
        rescue => e
          $stderr.puts e.inspect
          $stderr.puts e.backtrace
        end
      end
    end
  end
  
  class Base
    attr_accessor :model
    
    attr_reader :rdo_plugin_args
    
    def initialize(args)
      @rdo_plugin_args = args
    end
    
    def classname
      return @rdo_plugin_args[:classname]
    end
    
    def name
      return @rdo_plugin_args[:name]
    end
    
    #Returns a default name based on the plugin-name. This method can be over-written on the plugin itself.
    def title
      name = Knj::Php.ucwords(self.class.name.to_s[15, 999].gsub("_", " "))
    end
  end
  
  class Result
    attr_reader :args
    
    @@search_icon = Gdk::Pixbuf.new("#{File.dirname(__FILE__)}/../gfx/search.png")
    def self.search_icon
      return @@search_icon
    end
    
    def initialize(args)
      @args = args
    end
    
    def icon_pixbuf!
      if @args[:icon]
        if File.exists?(@args[:icon])
          return Gdk::Pixbuf.new(@args[:icon])
        else
          $stderr.puts "Icon does not exist: '#{@args[:icon]}'."
        end
      end
      
      return @@search_icon
    end
    
    def title!
      if !@args[:title].to_s.empty?
        return @args[:title]
      else
        return "[#{_("no title")}]"
      end
    end
    
    def title_html!
      if !@args[:title_html].to_s.empty?
        return @args[:title_html]
      elsif !@args[:title].to_s.empty?
        return "<b>#{Knj::Web.html(@args[:title])}</b>"
      else
        return "<b>[#{_("no title")}]</b>"
      end
    end
    
    def descr!
      if !@args[:descr].to_s.empty?
        return @args[:descr]
      else
        return "[#{_("no description")}]"
      end
    end
    
    def descr_html!
      if !@args[:descr_html].to_s.empty?
        return @args[:descr_html]
      elsif !@args[:descr].to_s.empty?
        return Knj::Web.html(@args[:descr])
      else
        return "[#{_("no description")}]"
      end
    end
  end
end