# Copyright (c) 2007 The RubyCocoa Project.
# Copyright (c) 2006 Tim Burks, Neon Design Technology, Inc.
#  
# Find more information about this file online at:
#    http://www.rubycocoa.com/mastering-cocoa-with-ruby
# Extensively modified for reuse with permission by Jonathan deWerd (jjoonathan@gmail.com).
# Changes (c) 2008 Jonathan deWerd, released under a 3-clause BSD license.

require 'irb'
require 'set'
require 'thread'
require 'info_window_controller'
require 'view_naming'
require 'fscript'
require 'monitor'
$RubyConConsoles = Set.new

def with(x)
	yield x if block_given?; x
	end if not defined? with

def scrollableView(content)
	scrollview = OSX::NSScrollView.alloc.initWithFrame(content.frame)
	clipview = OSX::NSClipView.alloc.initWithFrame(scrollview.frame)
	scrollview.contentView = clipview
	scrollview.documentView = clipview.documentView = content
	content.frame = clipview.frame
	scrollview.hasVerticalScroller = scrollview.hasHorizontalScroller = 
    scrollview.autohidesScrollers = true
	resizingMask = OSX::NSViewWidthSizable + OSX::NSViewHeightSizable
	content.autoresizingMask = clipview.autoresizingMask = 
    scrollview.autoresizingMask = resizingMask
	scrollview
	end

class RubyCocoaInputMethod < IRB::StdioInputMethod
	attr_reader :line_no, :history_index
	def initialize(console)
		super() # superclass method has no arguments
		@console = console
		@continued_from_line = nil
		@line = [nil] #Lines can be indexed by their line numbers
		@history_index = 1
		@line_no = 1
		end
	
	def gets
		m = @prompt.match(/(\d+)[>*]/)
		level = m ? m[1].to_i : 0
		if level > 0
			@continued_from_line ||= @line_no
			elsif @continued_from_line
			mergeLastNLines(@line_no - @continued_from_line + 1)
			@continued_from_line = nil
			end
		@console.write @prompt+"  "*level
		string = @console.command_queue.deq
		@line[@line_no] = string
		@line_no += 1
		@history_index = @line_no
		string
		end
	
	def mergeLastNLines(i)
		return unless i > 1
		range = -i..-1
		@line[range] = @line[range].map {|l| l.chomp}.join("\n")
		@line_no -= (i-1)
		@history_index -= (i-1)
		end
	
	def prevCmd
		@line[@line_no] = @console.currentLine if @history_index==@line_no #Store off the current line if need be
		@history_index -= 1 unless @history_index <= 1
		@line[@history_index]
		end
	
	def nextCmd
		@line[@line_no] = @console.currentLine if @history_index==@line_no #Store off the current line if need be
		@history_index += 1 unless @history_index == @line_no
		@line[@history_index]
		end
	end

class RubyConsoleBouncer
	def initialize(target,iserr)
		@iserr=iserr
		@target=target
		end
	
	def write(str)
		@target.write(str,@iserr)
		end
	end


# this is an output handler for IRB 
# and a delegate and controller for an NSTextView
class RubyConsole < OSX::NSObject
	attr_accessor :textview, :inputMethod, :command_queue, :old_stdout, :old_stderr, :irb
	
	def initWithTextView(textview)
		init
		@command_queue = Queue.new
		@textview = textview
		@textview.delegate = self
		@textview.richText = false
		@textview.continuousSpellCheckingEnabled = false
		@textview.font = @font = OSX::NSFont.fontWithName_size('Monaco', 12.0)
		@inputMethod = RubyCocoaInputMethod.new(self)
		@context = Kernel::binding
		@startOfInput = 0
		@tv_mutex = Monitor.new
		IRB.startInConsole(self)
		$RubyConConsoles.add self
		self
		end
	
	def windowDidBecomeMain(wind)
		console_did_become_main
		end
	
	def console_did_become_main
		IRB.conf[:MAIN_CONTEXT] = irb.context  
		@old_stdout= $stdout
		@old_stderr= $stderr
		@stdout ||= RubyConsoleBouncer.new(self,false)
		@stderr ||= RubyConsoleBouncer.new(self,true)
		$stdout = @stdout
		$stderr = @stderr
		end
	
	def windowShouldClose(wind)
		close(true)
		true
		end
	
	def close(already_closing=false)
		command_queue.enq "exit" if already_closing #Was closed by a user click, need to close IRB separately
		$stdout = old_stdout
		$stderr = old_stderr
		IRB.conf[:MAIN_CONTEXT] = nil
		textview.window.close unless already_closing
		textview.window.release
		$RubyConConsoles.delete self
		end
	
	def attString(string,red=false)
		color=(red)?(OSX::NSColor.redColor):(OSX::NSColor.blackColor)
		OSX::NSAttributedString.alloc.initWithString_attributes(string, { OSX::NSFontAttributeName, @font, OSX::NSForegroundColorAttributeName, color })
		end
	
	def write(object,red=false)
		@tv_mutex.synchronize {
			string = object.to_s
			@textview.textStorage.appendAttributedString(attString(string,red))
			@startOfInput = lengthOfTextView
			@textview.scrollRangeToVisible([lengthOfTextView, 0])
			local_hash={}
			local_names=irb.context.evaluate('local_variables',0)-["_"]
			local_names.each {|i| local_hash[i]=irb.context.evaluate("#{i}",0) }
			FScript.autobridge_locals(local_hash)
		}
		end
	
	def moveAndScrollToIndex(index)
		range = OSX::NSRange.new(index, 0)
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
		text.substringWithRange(OSX::NSRange.new(@startOfInput, text.length - @startOfInput)).to_s
		end
	
	def replaceLineWithHistory(s)
		range = OSX::NSRange.new(@startOfInput, lengthOfTextView - @startOfInput)
		@tv_mutex.synchronize {
			@textview.textStorage.replaceCharactersInRange_withAttributedString(range, attString(s.chomp))
			@textview.scrollRangeToVisible([lengthOfTextView, 0])
		}
		true
		end
	
	def run_command(comm)
		command_queue.enq comm
		end
	
	def textView_shouldChangeTextInRange_replacementString(
														   textview, range, replacement)
		@tv_mutex.synchronize {
			if range.location < @startOfInput
				moveAndScrollToIndex(@startOfInput)
				@textview.textStorage.replaceCharactersInRange_withString_(OSX::NSRange.new(@startOfInput,0),replacement)
				return false
				end
			replacement = replacement.to_s.gsub("\r","\n")
			cl = currentLine
			if replacement.length > 0 and replacement[-1].chr == "\n"
				return true if replacement.length!=1 && range.location!=lengthOfTextView #Allow newline pasting
				inline_newline = replacement.length==1 && range.location!=lengthOfTextView
				@textview.textStorage.replaceCharactersInRange_withString_(range, replacement) unless inline_newline
				if inline_newline
					end_of_tv = OSX::NSRange.new(lengthOfTextView,0)
					@textview.setSelectedRange(end_of_tv)
					@textview.textStorage.replaceCharactersInRange_withString_(end_of_tv,"\n")
					end
				cl=currentLine
				@startOfInput = lengthOfTextView
				run_command cl
				return false
				end
		}
		true
		end
	
	def keyDown(evt)
		puts evt.description
		end
	
	def textView_willChangeSelectionFromCharacterRange_toCharacterRange(
																		textview, oldRange, newRange)
		if (newRange.length == 0) and (newRange.location < @startOfInput)
			return oldRange if (oldRange.location>=@startOfInput)
			rng = 0
			@tv_mutex.synchronize {
				rng = OSX::NSMakeRange(@textview.textStorage.length, 0)
			}
			rng
			end
		newRange
		end
	
	def textView_doCommandBySelector(textview, selector)
		case selector
			when "moveUp:"
			replaceLineWithHistory(@inputMethod.prevCmd)
			moveAndScrollToIndex(lengthOfTextView)
			when "moveDown:"
			replaceLineWithHistory(@inputMethod.nextCmd)
			moveAndScrollToIndex(lengthOfTextView)
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

module IRB
	def IRB.rc_scripts()
		return @rc_script_paths if @rc_script_paths
		global_rc_path = 
		@rc_script_paths = {
			"Global" => OSX::NSBundle.bundleForClass(OSX::RubyConLoader).pathForResource_ofType_('rubyconrc','rb'),
			"User"   => File.expand_path('~/Library/Rubycon/rubyconrc.rb'),
			"Application" => File.expand_path("~/Library/Rubycon/#{OSX::NSBundle.mainBundle.bundleIdentifier}.rb")
			#"Application" => OSX::NSBundle.mainBundle.pathForResource_ofType_('rubyconrc','rb')
		}
		end
	
	def IRB.startInConsole(console)
		if not $IRB_has_been_setup
			IRB.setup(nil)
			@CONF[:PROMPT_MODE] = :SIMPLE
			@CONF[:VERBOSE] = false
			@CONF[:ECHO] = true
			$IRB_has_been_setup = true
			end
		irb = Irb.new(nil, console.inputMethod, console)
		@CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
		@CONF[:MAIN_CONTEXT] = irb.context
		console.irb= irb
		
		console.console_did_become_main #Get stdout set right
		self.rc_scripts.each_value {|p|
			next unless p && File.exists?(p)
			irb.context.evaluate("load #{'"'+p+'"'}", 0)
		}
		irb.context.evaluate('include OSX',0)
		
		Thread.new {
			catch(:IRB_EXIT) do
				loop do
					begin
						irb.eval_input
						rescue Exception
						errstr = "#{$!}"
						console.close if errstr=="exit" || errstr=="SIGTERM"
						puts "Error: #{$!}"
						end
					end
				end
			console.close
		}
		end
	
	class Context
		def prompting?
			true
			end
		end
	end

#More a menu responder than a window factory now
class ConsoleWindowFactory < OSX::NSObject
	def spawn(sender)
		frame = [50,50,1200,600]
		styleMask = OSX::NSTitledWindowMask + OSX::NSClosableWindowMask + 
		OSX::NSMiniaturizableWindowMask + OSX::NSResizableWindowMask
		window = OSX::NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
																				 frame, styleMask, OSX::NSBackingStoreBuffered, false)
		window.retain
		textview = OSX::NSTextView.alloc.initWithFrame(frame)
		console = RubyConsole.alloc.initWithTextView textview
		with window do |w|
			w.contentView = scrollableView(textview)
			w.title = "RubyCocoa Console"
			w.delegate = console
			w.center
			w.makeKeyAndOrderFront(self)
			end
		end
	
	def defaultsView(sender)
		if !@user_defualts_editor
			@user_defualts_editor= OSX::RubyConDefaultsController.alloc.init
			OSX::NSBundle.loadNibNamed_owner_("DefaultsEditor", @user_defualts_editor)
			end
		@user_defualts_editor.show
		end
	
	def editrc(sender)
		path=sender.representedObject.to_s
		if !File.exists?(path)
			`mkdir -p #{File.dirname(path)}`
			STDERR.puts "Insufficent privelages to mkdir -p to #{File.dirname(path)}" unless $?.success?
			`touch #{path}`
			STDERR.puts "Insufficent privelages to touch #{path}" unless $?.success?
			end
		OSX::NSWorkspace.sharedWorkspace().openFile(path)
		end
	end

#Add the ruby menu
top_menu= OSX::NSMenu.alloc.initWithTitle ''

begin
  top_menu_item= OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent_('', :jump, '')
  icon_path = OSX::NSBundle.bundleForClass(OSX::RubyConLoader).pathForResource_ofType_('rubycon_icon','icns')
  ruby_icon = OSX::NSImage.alloc.initWithContentsOfFile(icon_path)
  ruby_icon.size= [16,16]
  top_menu_item.image= ruby_icon
  top_menu_item.submenu= top_menu
  top_menu_item.target= OSX::RubyConLoader
  top_menu_item.action= 'doNothing:'
  top_menu_item.enabled= true
  main_menu = OSX::NSApplication.sharedApplication.mainMenu
  main_menu.addItem top_menu_item
rescue Exception
  $RubyConOldStdout.puts "Could not create rubycon menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
  spawn_item= OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent_('New Ruby Console', 'spawn:', 'R')
  spawn_item.keyEquivalentModifierMask= OSX::NSCommandKeyMask+OSX::NSAlternateKeyMask
  cfac = ConsoleWindowFactory.new
  spawn_item.target= cfac
  top_menu.addItem spawn_item
  
  name_view_item= OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent_('Name Views', 'nameView:', 'V')
  name_view_item.keyEquivalentModifierMask= OSX::NSCommandKeyMask+OSX::NSAlternateKeyMask
  name_view_item.target= cfac
  top_menu.addItem name_view_item
  
  user_defaults_item= OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent_('User Defaults', 'defaultsView:', '')
  user_defaults_item.target= cfac
  top_menu.addItem user_defaults_item
  
  top_menu.addItem OSX::NSMenuItem.separatorItem()
  
  IRB.rc_scripts.each {|name,path|
  	item= OSX::NSMenuItem.alloc.initWithTitle_action_keyEquivalent_("Edit #{name} RC Script", 'editrc:', '')
  	item.representedObject=(path)
  	item.target=(cfac)
  	top_menu.addItem item
  }
rescue Exception
  $RubyConOldStdout.puts "Could not populate rubycon menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
  framework_search_paths = ["/System/Library/Frameworks/", "/Library/Frameworks/", "~/Library/Frameworks/"]
  bn = nil
  framework_search_paths.each {|s|
  	bn = OSX::NSBundle.bundleWithPath(s+"FScript.framework") unless bn
  }
  if bn && bn.load
  	fs_menu_item = OSX::FScriptMenuItem.alloc.init
  	cfac.patch_fscript(fs_menu_item.submenu)
  	fs_menu_item.title= 'a'
  	fs_menu_item.submenu.title= 'b'
  	fs_icon_path = OSX::NSBundle.bundleForClass(OSX::RubyConLoader).pathForResource_ofType_('fscript_menu_icon','icns')
  	fs_icon = OSX::NSImage.alloc.initWithContentsOfFile(fs_icon_path)
  	fs_icon.size= [16,16]
  	fs_menu_item.image= fs_icon
  	main_menu.addItem fs_menu_item
  	$FScript_menu = fs_menu_item
  	end
rescue Exception
  $RubyConOldStdout.puts "Could not create fscript menu: #{$!}. \n#{$!.backtrace.join('\n')}"
end

class RubyConTopBouncer < IO
	def self.stdout
		@stdout||=RubyConTopBouncer.new(false)
	end
	def self.stderr
		@stderr||=RubyConTopBouncer.new(true)
	end
	def initialize(is_err)
		@is_err= is_err
		super(0)
		end
	def puts(str) write(str.to_s.chomp+"\n") end
	def write(str)
		((@is_err)?$stderr:$stdout).write(str)
		end
	def self.flush() nil end
	def self.processStderrData(dat)
		self.stderr.write(dat.rubyString)
	end
	def self.processStdoutData(dat)
		self.stdout.write(dat.rubyString)
	end
end

begin
  $:<<OSX::NSBundle.mainBundle.resourcePath
  $program_name = OSX::NSBundle.mainBundle.executablePath.to_s
  alias $0 $program_name
  $rubycon_top_stdout_bouncer = RubyConTopBouncer.stdout
  $rubycon_top_stderr_bouncer = RubyConTopBouncer.stderr
rescue
  $RubyConOldStdout.puts "Could not capture $0 and STDOUT, STDERR variables: #{$!}. \n#{$!.backtrace.join('\n')}"
end

begin
	OSX::O3PipeControl.delegate= RubyConTopBouncer
	OSX::O3PipeControl.capturingEnabled= true
rescue
  $RubyConOldStdout.puts "Could not capture stdout and stderr FDs: #{$!}"
end