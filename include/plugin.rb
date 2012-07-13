class Ruby_do::Plugin
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
          
          plugin.start if plugin.respond_to?(:start)
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
      plugins_active = []
      @args[:rdo].ob.list(:Plugin, "active" => 1, "orderby" => "order_no") do |plugin|
        plugins_active << plugin
      end
      
      plugins_active_ids = plugins_active.clone.map{|d| d.id.to_i}
      found = []
      
      #Search for exact static results.
      @args[:rdo].ob.list(:Static_result, "plugin_id" => plugins_active_ids, "title_lower" => args[:text].to_s.strip.downcase) do |sres|
        yielder << Ruby_do::Plugin::Result.new(
          :title => sres[:title],
          :descr => sres[:descr],
          :icon => sres[:icon_path],
          :static_result => true,
          :sres => sres
        )
        
        found << sres.id
      end
      
      #Search for close static results.
      @args[:rdo].ob.list(:Static_result, "plugin_id" => plugins_active_ids, "title_lower_search" => args[:text].to_s.strip.downcase, "id_not" => found) do |sres|
        yielder << Ruby_do::Plugin::Result.new(
          :title => sres[:title],
          :descr => sres[:descr],
          :icon => sres[:icon_path],
          :static_result => true,
          :sres => sres
        )
        
        found << sres.id
      end
      
      #Call plugins to get further results.
      plugins_active.each do |plugin_model|
        plugin_instance = plugin_model.plugin
        next if !plugin_instance.respond_to?(:on_search)
        
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
    
    def static_result_exists?(id_str)
      sres = self.static_result_get(id_str)
      
      if sres
        return true
      else
        return false
      end
    end
    
    def static_result_get(id_str)
      return @rdo_plugin_args[:rdo].ob.get_by(:Static_result, "plugin_id" => self.model.id, "id_str" => id_str)
    end
    
    def register_static_result(args)
      raise "Argument was not a hash." if !args.is_a?(Hash)
      raise "':id_str' was empty." if args[:id_str].to_s.strip.empty?
      raise "':title' was empty." if args[:title].to_s.strip.empty?
      raise "':descr' was empty." if args[:descr].to_s.strip.empty?
      
      args[:data] = {} if !args[:data]
      
      sres_hash = {
        :title => args[:title],
        :title_lower => args[:title].to_s.strip.downcase,
        :id_str => args[:id_str],
        :descr => args[:descr],
        :icon_path => args[:icon_path],
        :data => Marshal.dump(args[:data])
      }
      
      if sres = self.static_result_get(args[:id_str])
        sres.update(sres_hash)
      else
        sres = @rdo_plugin_args[:rdo].ob.add(:Static_result, sres_hash.merge(
          :plugin_id => self.model.id,
        ))
      end
      
      return {:sres => sres}
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
        if File.exists?(@args[:icon]) and !File.directory?(@args[:icon])
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
    
    def execute
      if @args[:static_result]
        plugin = @args[:sres].plugin.plugin
        return plugin.execute_static_result(:sres => @args[:sres])
      else
        return @args[:plugin].execute_result(:res => self)
      end
    end
  end
end