require 'info_window_controller'
require 'view_description'

class LabelWindowController < InfoWindowController
	TextSize = 10
	TextFont = NSFont.boldSystemFontOfSize(TextSize)
	TextColor = NSColor.orangeColor
		
	def initialize(view,number)
		super()
		#@info_view.alignCenter(self)
		@info_view.font= TextFont
		@info_view.textColor= TextColor
		@info_view.textContainerInset= [0,0]
		@info_window.backgroundColor= NSColor.colorWithCalibratedWhite_alpha_(0,0.6)
		self.number= number
		self.view= view
	end
	
	attr_reader :number
	def number=(newnum)
		self.string= "v#{newnum}"
		@number = newnum
	end
	
	attr_reader :view
	def view=(new_view)
		parent_to_window_of(new_view)
		if new_view
			resize_window_to_fit_view(new_view)
			show()
		else
			hide()
		end
		@view = new_view
	end
	
	def close
		super
	end
end