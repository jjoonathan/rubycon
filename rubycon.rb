#
#  rubycon.rb
#  RubyCon
#
#  Created by Jonathan deWerd on 10/4/08.
#  Copyright (c) 2008 Jonathan deWerd.
#  Released under a 3-clause BSD license.
begin
	NSString
	framework 'Cocoa'
	RubyConBundle = NSBundle.bundleForClass(RubyConLoader)
	$:<<(RubyConBundle.resourcePath())
	rescue NameError=>e
	require 'osx/cocoa'
	include OSX
	end

if !(NSApplication.sharedApplication.mainMenu) then
	puts "RubyCon not loading into #{NSBundle.mainBundle.bundleIdentifier.to_s} because it has no main menu (RubyCon assumes its headless)."
	else
	
	begin
		load 'console.rb'
		rescue Exception=>e
		#lf=File.open('/l/de/lf','a')
		#lf.puts e
		#lf.puts e.backtrace
		puts "Could not initialize rubycon: #{$!}"
		end
	
	end