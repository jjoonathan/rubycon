require 'info_window_controller'

class FocusWindowController < InfoWindowController
	def initialize(view=nil)
		super()
		@box_view = OSX::RubyConFocusView.alloc.initWithFrame([0,0,400,100])
		@box_view.autoresizingMask=(OSX::NSViewWidthSizable + OSX::NSViewHeightSizable)
		@info_window.contentView=@box_view
		
		self.view= view
		@info_window.ignoresMouseEvents= true
		@info_window.backgroundColor= OSX::NSColor.colorWithCalibratedWhite_alpha_(0,0.4)
	end
	
	def string
		''
	end
	
	attr_reader :view
	def view=(new_view)
		resize_window_to_fit_view(new_view)
		parent_to_window_of(new_view)
		hide() unless new_view
		@view = new_view
		@box_view.targetView=(new_view)
	end
	
	def close
		parent_to_window_of(nil)
		super
	end
end
