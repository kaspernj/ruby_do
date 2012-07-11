#This class controls the main window.
class Ruby_do::Gui::Win_main
  #Initializes various variables for the object.
  def initialize(args)
    @args = args
  end
  
  #Spawn the GUI-object.
  def spawn_gui
    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/../glade/win_main.glade")
    @gui.connect_signals{|h| method(h)}
    Knj::Gtk2.translate(@gui)
  end
  
  def reset
    @gui["txtSearch"].text = ""
    self.update_res
    self.on_txtSearch_changed_wait
  end
  
  #Spawns the GUI (if not already spawned) and focusses the window.
  def show
    self.spawn_gui if !@gui or @gui["window"].destroyed?
    self.reset
    
    @gui["window"].show_all
    @gui["window"].present
    @gui["txtSearch"].grab_focus
    
    #Update icon and text.
    self.update_res
  end
  
  def hide
    @gui["window"].hide
  end
  
  #Updates the icon, title and description to match the current result (if any).
  def update_res
    if @results and @enum
      while @results.length <= @result_i
        begin
          @results << @enum.next
        rescue StopIteration
          @result_i -= 1
        end
      end
      
      cur_res = @results[@result_i]
    end
    
    if cur_res
      @gui["labActionTitle"].markup = "<b>#{@result_i + 1}</b> - " + cur_res.title_html!
      @gui["labActionDescr"].label = cur_res.descr_html!
      @gui["imgActionIcon"].pixbuf = cur_res.icon_pixbuf!
    else
      @gui["labActionTitle"].markup = "<b>#{Knj::Web.html(_("Nothing found"))}</b>"
      @gui["labActionDescr"].label = _("Please enter something in the search text-field to do something.")
      @gui["imgActionIcon"].pixbuf = Ruby_do::Plugin::Result.search_icon
    end
  end
  
  #Starts the timeout of half a second in order to not mass-call plugins and start lagging.
  def on_txtSearch_changed
    Gtk.timeout_remove(@timeout) if @timeout
    @timeout = Gtk.timeout_add(500) do
      self.on_txtSearch_changed_wait
      @timeout = nil
      false
    end
  end
  
  #This happens when the timeout is over and the plugins should be called.
  def on_txtSearch_changed_wait
    return nil if @gui["window"].destroyed?
    
    @enum = nil
    @result_i = 0
    @results = []
    
    text = @gui["txtSearch"].text
    words = text.split(/\s+/).map{|ele| ele.downcase}
    
    if !words.empty?
      #Need to use threadded enumerator because of fiber failure otherwise.
      @enum = Threadded_enumerator.new(:enum => @args[:rdo].plugin.send(:text => text, :words => words))
    end
    
    self.update_res
  end
  
  def prev_result
    @result_i -= 1 if @result_i > 0
    self.update_res
  end
  
  def next_result
    @result_i += 1
    self.update_res
  end
  
  #This happens when <ENTER> is pressed while the search-textfield has focus.
  def on_txtSearch_activate
    #If enter was pressed before search was executed, then be sure to execute a search first and disable the timeout, so search wont be done two times.
    if @timeout and !@enum and @result_i == 0
      Gtk.timeout_remove(@timeout)
      self.on_txtSearch_changed_wait
    end
    
    cur_res = @results[@result_i]
    
    if !cur_res
      Knj::Gtk2.msgbox(_("Please search for something in order to activate."))
      return nil
    end
    
    begin
      res = cur_res.execute
      
      if res == :close_win_main
        @gui["window"].destroy
      end
    rescue => e
      Knj::Gtk2.msgbox(_("An error occurred.") + "\n\n#{e.inspect}\n\n#{e.backtrace.join("\n")}")
    end
  end
  
  #In order the register <ESCAPE>-presses.
  def on_txtSearch_key_press_event(entry, eventkey)
    name = Gdk::Keyval.to_name(eventkey.keyval).to_s.downcase
    
    if name == "escape"
      @gui["window"].destroy
    elsif name == "down"
      self.next_result
      return true
    elsif name == "up"
      self.prev_result
      return true
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