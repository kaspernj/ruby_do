class Ruby_do::Gui::Win_main
  def initialize(args)
    @args = args
  end
  
  def spawn_gui
    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/../glade/win_main.glade")
    @gui.connect_signals{|h| method(h)}
    Knj::Gtk2.translate(@gui)
  end
  
  def show
    self.spawn_gui if !@gui or @gui["window"].destroyed?
    
    @gui["window"].show_all
    @gui["window"].present
    @gui["txtSearch"].grab_focus
  end
  
  def hide
    @gui["window"].hide
  end
  
  def on_txtSearch_changed
    Gtk.timeout_remove(@timeout) if @timeout
    @timeout = Gtk.timeout_add(500) do
      self.on_txtSearch_changed_wait
      false
    end
  end
  
  def on_txtSearch_changed_wait
    @enum = @args[:rdo].plugin.send(:text => @gui["txtSearch"].text)
    
    begin
      @cur_res = @enum.next
    rescue StopIteration
      @cur_res = nil
    end
    
    self.update_res
  end
  
  def update_res
    if @cur_res
      @gui["labActionTitle"].markup = @cur_res.title_html!
      @gui["labActionDescr"].label = @cur_res.descr_html!
      @gui["imgActionIcon"].pixbuf = @cur_res.icon_pixbuf!
    else
      @gui["labActionTitle"].markup = _("Nothing found")
      @gui["labActionDescr"].label = _("Please enter something in the search text-field to do something.")
      @gui["imgActionIcon"].pixbuf = Ruby_do::Plugin::Result.search_icon
    end
  end
  
  def on_txtSearch_activate
    if !@cur_res
      Knj::Gtk2.msgbox(_("Please search for something in order to activate."))
      return nil
    end
    
    begin
      res = @cur_res.args[:plugin].execute_result(@cur_res)
      
      if res == :close_win_main
        @gui["window"].destroy
      end
    rescue => e
      Knj::Gtk2.msgbox(_("An error occurred.") + "\n\n#{e.inspect}\n\n#{e.backtrace.join("\n")}")
    end
  end
  
  def on_btnProperties_clicked
    @args[:rdo].show_win_properties
    @gui["window"].destroy
  end
  
  def on_window_focus_out_event
    @gui["window"].destroy
  end
end