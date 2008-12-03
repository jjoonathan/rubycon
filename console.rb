# Copyright (c) 2007 The RubyCocoa Project.
# Copyright (c) 2006 Tim Burks, Neon Design Technology, Inc.
#  
# Find more information about this file online at:
#    http://www.rubycocoa.com/mastering-cocoa-with-ruby
# Extensively modified (more like rewritten) with permission by Jonathan deWerd (jjoonathan@gmail.com).
# Changes (c) 2008 Jonathan deWerd, released under a 3-clause BSD license.

require 'set'
require 'thread'
require 'info_window_controller'
require 'view_naming'
require 'fscript'
require 'monitor'

def with(x)
	yield x if block_given?; x
	end if not defined? with

def scrollableView(content)
	scrollview = NSScrollView.alloc.initWithFrame(content.frame)
	clipview = NSClipView.alloc.initWithFrame(scrollview.frame)
	scrollview.contentView = clipview
	scrollview.documentView = clipview.documentView = content
	content.frame = clipview.frame
	scrollview.hasVerticalScroller = scrollview.hasHorizontalScroller = 
    scrollview.autohidesScrollers = true
	resizingMask = NSViewWidthSizable + NSViewHeightSizable
	content.autoresizingMask = clipview.autoresizingMask = 
    scrollview.autoresizingMask = resizingMask
	scrollview
	end

module RubyConsoleContext
	def self.method_missing(id, *params)
		if params.empty?
			fs_val = FScript[id.to_s]
			return fs_val if fs_val
			end
		Object.send(id,*params)
		end
end

class RubyConsole < NSObject
	attr_accessor :textview, :inputMethod, :binding_context, :history, :histidx, :preprompt_place, :hist_saved_line
	
	def self.rc_scripts()
		return @rc_script_paths if @rc_script_paths
		global_rc_path = 
		@rc_script_paths = {
			"Global" => NSBundle.bundleForClass(RubyConLoader).pathForResource('rubyconrc', :ofType=>'rb'),
			"User"   => File.expand_path('~/Library/Rubycon/rubyconrc.rb'),
			"Application" => File.expand_path("~/Library/Rubycon/#{NSBundle.mainBundle.bundleIdentifier}.rb")
		}
		end
	
	def self.top_console
		$rubycon_top_console
	end
	
	def self.new_binding_context()
		RubyConsoleContext.module_eval("binding")
	end
	
	def initWithTextView(textview)
		init
		@history=[]
		@textview = textview
		@textview.delegate = self
		@textview.richText = false
		@textview.continuousSpellCheckingEnabled = false
		@textview.font = @font = NSFont.fontWithName('Monaco', :size=>12.0)
		@binding_context = RubyConsole.new_binding_context
		@startOfInput = 0
		@tv_mutex = Monitor.new
		@histidx = 0
		draw_prompt()
		self
		end
	
	def windowDidBecomeMain(wind)
		console_did_become_main
		end
	
	def console_did_become_main
		$rubycon_console_stack ||= []
		$rubycon_top_console = self
		end
	
	def windowShouldClose(wind)
		close(true)
		true
		end
	
	def close(already_closing=false)
		$rubycon_console_stack ||= []
		$rubycon_top_console = nil
		textview.window.close unless already_closing
		end
	
	def attString(string,type)
		attribs = { NSFontAttributeName => @font, NSForegroundColorAttributeName => NSColor.whiteColor }
		case type
			when (:stderr)
				attribs[NSForegroundColorAttributeName] = NSColor.redColor
			when (:stdin || :retval)
				attribs[NSUnderlineStyleAttributeName] = NSUnderlineStyleSingle
			when (:stdout) #Default			
		end
		NSAttributedString.alloc.initWithString(string, :attributes=>attribs)
		end
	
	def write(object,type=:stdin)
		@tv_mutex.synchronize {
			string = object.to_s
			idx = lengthOfTextView
			if type==:stdout or type==:stderr then
				idx=@preprompt_place
				@preprompt_place += string.length
				@startOfInput += string.length
				end
			@textview.textStorage.insertAttributedString(attString(string,type), :atIndex=>idx)
			@textview.scrollRangeToVisible([lengthOfTextView, 0])
			if type==:stdin then
				local_hash={}
				local_names=eval('local_variables',binding_context)-["_"]
				local_names.each {|i| local_hash[i]=eval("#{i}",binding_context) }
				FScript.autobridge_locals(local_hash)
				end
		}
		end
	
	def moveAndScrollToIndex(index)
		range = NSRange.new(index, 0)
		@textview.scrollRangeToVisible(range)
		@textview.setSelectedRange(range)
		end
	
	def lengthOfTextView
		len=0
		@tv_mutex.synchronize {
			len=@textview.textStorage.mutableString.length
		}
		len
		end
	
	def currentLine
		text = @textview.textStorage.mutableString
		text.substringWithRange(NSRange.new(@startOfInput, text.length - @startOfInput)).to_s
		end
	
	def replaceLineWithHistory(s)
		range = NSRange.new(@startOfInput, lengthOfTextView - @startOfInput)
		@tv_mutex.synchronize {
			@textview.textStorage.replaceCharactersInRange(range, :withAttributedString=>attString(s.chomp, :stdin))
			@textview.scrollRangeToVisible([lengthOfTextView, 0])
		}
		true
		end
	
	def draw_prompt()
		@preprompt_place = lengthOfTextView
		write(">> ", :stdin)
		@startOfInput = lengthOfTextView
		@histidx=0
	end
	
	def run_command(comm)
		@preprompt_place = lengthOfTextView
		begin
			result=eval(comm,@binding_context, "RubyCon_Console", 0)
			write("=> #{result.inspect.chomp}\n", :retval)
			rescue Exception=>e
			write("#{e.inspect}\n", :stderr)
			end
		@history<<comm
		draw_prompt()
		end
	
	def textView(textview, shouldChangeTextInRange:range, replacementString:replacement)
		@tv_mutex.synchronize {
			if range.location < @startOfInput
				moveAndScrollToIndex(@startOfInput)
				@textview.textStorage.replaceCharactersInRange(NSRange.new(@startOfInput,0), withAttributedString:attString(replacement,:stdin))
				return false
				end
			replacement = replacement.to_s.gsub("\r","\n")
			cl = currentLine
			if replacement.length > 0 and replacement[-1].chr == "\n"
				return true if replacement.length!=1 && range.location!=lengthOfTextView #Allow newline pasting
				inline_newline = replacement.length==1 && range.location!=lengthOfTextView
				@textview.textStorage.replaceCharactersInRange(range, :withAttributedString=>attString(replacement,:stdin)) unless inline_newline
				if inline_newline
					end_of_tv = NSRange.new(lengthOfTextView,0)
					@textview.setSelectedRange(end_of_tv)
					@textview.textStorage.replaceCharactersInRange(end_of_tv, :withAttributedString=>attString("\n",:stdin))
					end
				cl=currentLine
				@startOfInput = lengthOfTextView
				run_command cl
				return false
				end
			if range.location>=@startOfInput
				moveAndScrollToIndex(@startOfInput)
				@textview.textStorage.replaceCharactersInRange(NSRange.new(range.location,range.length), :withAttributedString=>attString(replacement,:stdin))
				moveAndScrollToIndex(range.location+replacement.length)
				return false
				end
		}
		true
		end
	
	def textView(textview, willChangeSelectionFromCharacterRange:oldRange, toCharacterRange:newRange)
		if (newRange.length == 0) and (newRange.location < @startOfInput)
			return oldRange if (oldRange.location>=@startOfInput)
			rng = 0
			@tv_mutex.synchronize {
				rng = NSMakeRange(@textview.textStorage.length, 0)
			}
			rng
			end
		newRange
		end
	
	def textView(textview, doCommandBySelector:selector)
		STDERR.puts "!"
		case selector
			when "moveUp:"
				@hist_saved_line=currentLine if @histidx==0
				num=@history.size
				STDERR.puts "1 #{@history} #{num.intValue}"
				STDERR.puts num.to_i
				if @histidx<@history.size
				STDERR.puts "rlwd0"
					@histidx+=1
				STDERR.puts "rlwd"
					replaceLineWithHistory(@history[-@histidx])
					end
				STDERR.puts 'fin'
			when "moveDown:"
				if @histidx==1
					@histidx=0
					replaceLineWithHistory(@hist_saved_line)
					end
				if @histidx>1
					@histidx-=1
					replaceLineWithHistory(@history[-@histidx])
					end
			when "moveToBeginningOfParagraph:"
			moveAndScrollToIndex(@startOfInput)
			when "moveToBeginningOfLine:"
			moveAndScrollToIndex(@startOfInput)
			when "moveToEndOfLine:"
			moveAndScrollToIndex(@lengthOfTextView)
			when "moveToEndOfParagraph:"
			moveAndScrollToIndex(lengthOfTextView)
			else
			false
			end
		end
	end

#More a menu responder than a window factory now
class ConsoleWindowFactory < NSObject
	def spawn(sender)
		frame = [50,50,1200,600]
		styleMask = NSTitledWindowMask + NSClosableWindowMask + NSMiniaturizableWindowMask + NSResizableWindowMask
		window = NSWindow.alloc.initWithContentRect(frame, :styleMask=>styleMask, :backing=>NSBackingStoreBuffered, :defer=>false)
		window.opaque=false
		window.backgroundColor=NSColor.clearColor
		textview = NSTextView.alloc.initWithFrame(frame)
		textview.backgroundColor=NSColor.colorWithCalibratedRed(0, :green=>0, :blue=>0, :alpha=>0.8)
		console = RubyConsole.alloc.initWithTextView textview
		with window do |w|
			w.contentView = scrollableView(textview)
			w.title = "MacRuby Console"
			w.delegate = console
			w.center
			w.makeKeyAndOrderFront(self)
			end
		end
	
	def defaultsView(sender)
		if !@user_defualts_editor
			@user_defualts_editor= RubyConDefaultsController.alloc.init
			NSBundle.loadNibNamed("DefaultsEditor", :owner=>@user_defualts_editor)
			end
		@user_defualts_editor.show
		end
	
	def editrc(sender)
		path=sender.representedObject.to_s
		if !File.exists?(path)
			`mkdir -p #{File.dirname(path)}`
			puts "Insufficent privelages to mkdir -p to #{File.dirname(path)}" unless $?.success?
			`touch #{path}`
			puts "Insufficent privelages to touch #{path}" unless $?.success?
			end
		NSWorkspace.sharedWorkspace().openFile(path)
		end
	end

#Add the ruby menu
top_menu= NSMenu.alloc.initWithTitle ''

begin
  top_menu_item= NSMenuItem.alloc.initWithTitle('', :action=>:jump, :keyEquivalent=>'')
  icon_path = NSBundle.bundleForClass(RubyConLoader).pathForResource('rubycon_icon', :ofType=>'icns')
  ruby_icon = NSImage.alloc.initWithContentsOfFile(icon_path)
  ruby_icon.size= [16,16]
  top_menu_item.image= ruby_icon
  top_menu_item.submenu= top_menu
  top_menu_item.target= RubyConLoader
  top_menu_item.action= 'doNothing:'
  top_menu_item.enabled= true
  main_menu = NSApplication.sharedApplication.mainMenu
  main_menu.addItem top_menu_item
rescue Exception
  puts "Could not create rubycon menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
  spawn_item= NSMenuItem.alloc.initWithTitle('New Ruby Console', :action=>'spawn:', :keyEquivalent=>'R')
  spawn_item.keyEquivalentModifierMask= NSCommandKeyMask+NSAlternateKeyMask
  cfac = ConsoleWindowFactory.new
  spawn_item.target= cfac
  top_menu.addItem spawn_item
  $rubycon_console_window_fac = cfac
  
  name_view_item= NSMenuItem.alloc.initWithTitle('Name Views', :action=>'nameView:', :keyEquivalent=>'V')
  name_view_item.keyEquivalentModifierMask= NSCommandKeyMask+NSAlternateKeyMask
  name_view_item.target= cfac
  top_menu.addItem name_view_item
  
  user_defaults_item= NSMenuItem.alloc.initWithTitle('User Defaults', :action=>'defaultsView:', :keyEquivalent=>'')
  user_defaults_item.target= cfac
  top_menu.addItem user_defaults_item
  
  top_menu.addItem NSMenuItem.separatorItem()

  RubyConsole.rc_scripts.each {|name,path|
  	item= NSMenuItem.alloc.initWithTitle("Edit #{name} RC Script", :action=>'editrc:', :keyEquivalent=>'')
  	item.representedObject=(path)
  	item.target=(cfac)
  	top_menu.addItem item
  }
rescue Exception
  puts "Could not populate rubycon menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
  framework_search_paths = ["/System/Library/Frameworks/", "/Library/Frameworks/", "~/Library/Frameworks/"]
  bn = nil
  framework_search_paths.each {|s|
  	bn = NSBundle.bundleWithPath(s+"FScript.framework") unless bn
  }
  if bn && bn.load
  	fs_menu_item = FScriptMenuItem.alloc.init
  	cfac.patch_fscript(fs_menu_item.submenu)
  	fs_menu_item.title= 'a'
  	fs_menu_item.submenu.title= 'b'
  	fs_icon_path = NSBundle.bundleForClass(RubyConLoader).pathForResource('fscript_menu_icon', :ofType=>'icns')
  	fs_icon = NSImage.alloc.initWithContentsOfFile(fs_icon_path)
  	fs_icon.size= [16,16]
  	fs_menu_item.image= fs_icon
  	main_menu.addItem fs_menu_item
  	$FScript_menu = fs_menu_item
  	end
rescue Exception
  puts "Could not create fscript menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

class RubyConTopBouncer
	def processStderrData(dat)
		if $rubycon_top_console then
			$rubycon_top_console.write(dat.rubyString, :stderr)
			dat.rubyString
			else
			dat.rubyString
			end
	end
	def processStdoutData(dat)
		if $rubycon_top_console then
			$rubycon_top_console.write(dat.rubyString, :stdout)
			dat.rubyString
			else
			dat.rubyString
			end
	end
end

begin
  $:<<NSBundle.mainBundle.resourcePath
  $program_name = NSBundle.mainBundle.executablePath.to_s
  alias $0 $program_name
rescue
  puts "Could not capture $0 and STDOUT, STDERR variables: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
	$rubycon_top_bouncer = RubyConTopBouncer.new
	O3PipeControl.delegate= $rubycon_top_bouncer
	O3PipeControl.manualFlush= false
	O3PipeControl.capturingEnabled= true
rescue
  puts "Could not capture stdout and stderr FDs: #{$!}"
end

class RubyConPipeFlusher
	def flush
		O3PipeControl.flush
		end
	end

NSTimer.scheduledTimerWithTimeInterval(0.05, :target=>RubyConPipeFlusher.new, :selector=>:flush, :userInfo=>nil, :repeats=>true)