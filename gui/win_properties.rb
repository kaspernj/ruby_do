#This class controls the properties window.
class Ruby_do::Gui::Win_properties
  attr_reader :gui
  
  def initialize(args)
    @args = args
    
    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/../glade/win_properties.glade")
    @gui.connect_signals{|h| method(h)}
    Knj::Gtk2.translate(@gui)
    
    
    #Initialize plugins-treeview.
    Knj::Gtk2::Tv.init(@gui["tvPlugins"], [
      _("Name"),
      _("Title")
    ])
    @gui["tvPlugins"].columns[0].visible = false
    @gui["tvPlugins"].selection.signal_connect_after("changed", &self.method(:on_tvPlugins_changed))
    self.reload_plugins
    @gui["tvPlugins"].selection.select_iter(@gui["tvPlugins"].model.iter_first)
    
    
    #Show the properties window.
    @gui["window"].show
    
    
    #Hides checkbutton until a plugin is chosen.
    self.load_widget
    
    
    #Set the value of main-window-show checkbutton.
    if Knj::Opts.get("skip_main_on_startup").to_i == 1
      @gui["cbShowWindowOnStartup"].active = false
    else
      @gui["cbShowWindowOnStartup"].active = true
    end
  end
  
  def reload_plugins
    @gui["tvPlugins"].model.clear
    
    @args[:rdo].plugin.plugins.each do |name, plugin_obj|
      Knj::Gtk2::Tv.append(@gui["tvPlugins"], [
        plugin_obj.classname,
        plugin_obj.title
      ])
    end
  end
  
  def on_tvPlugins_changed(*args)
    sel = Knj::Gtk2::Tv.sel(@gui["tvPlugins"])
    model = @args[:rdo].ob.get_by(:Plugin, {"classname" => sel[0]}) if sel
    
    if model and model[:active].to_i == 1
      @gui["cbPluginActivate"].active = true
    else
      @gui["cbPluginActivate"].active = false
    end
    
    self.load_widget
    
    @gui["boxPluginOptions"].show_all
  end
  
  def load_widget
    #Remove plugin-widgets.
    @gui["boxPluginOptions"].children.each do |child|
      @gui["boxPluginOptions"].remove(child)
      child.destroy
    end
    
    sel = Knj::Gtk2::Tv.sel(@gui["tvPlugins"])
    model = @args[:rdo].ob.get_by(:Plugin, {"classname" => sel[0]}) if sel
    
    #If a plugin is selected and that plugin has a option-widget, then show that widget. Else show a label describing what is going on.
    if sel and model and plugin = @args[:rdo].plugin.plugins[sel[0]]
      if model[:active].to_i == 1
        @gui["cbPluginActivate"].active = true
        
        opt_res = plugin.on_options and opt_res[:widget]
        if opt_res and opt_res[:widget]
          @gui["boxPluginOptions"].pack_start(opt_res[:widget])
          opt_res[:widget].show
        else
          label = Gtk::Label.new(_("This plugin doesnt have any options."))
          @gui["boxPluginOptions"].pack_start(label)
          label.show
        end
      else
        @gui["cbPluginActivate"].active = false
        label = Gtk::Label.new(_("Activate the plugin to see available options."))
        @gui["boxPluginOptions"].pack_start(label)
        label.show
      end
      
      @gui["cbPluginActivate"].show
    else
      label = Gtk::Label.new(_("Please choose a plugin."))
      @gui["boxPluginOptions"].pack_start(label)
      label.show
      @gui["cbPluginActivate"].hide
    end
  end
  
  def on_cbPluginActivate_toggled
    sel = Knj::Gtk2::Tv.sel(@gui["tvPlugins"])
    model = @args[:rdo].ob.get_by(:Plugin, {"classname" => sel[0]}) if sel
    
    if model
      if @gui["cbPluginActivate"].active?
        model[:active] = 1
      else
        model[:active] = 0
      end
    end
    
    self.load_widget
  end
  
  def on_cbShowWindowOnStartup_toggled
    val = @gui["cbShowWindowOnStartup"].active?
    
    if val
      Knj::Opts.set("skip_main_on_startup", 0)
    else
      Knj::Opts.set("skip_main_on_startup", 1)
    end
  end
end