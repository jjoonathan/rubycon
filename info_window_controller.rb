require 'view_description'

class InfoWindowController
	TextSize = 10
	TextFont = NSFont.controlContentFontOfSize(TextSize)
	TextColor = NSColor.whiteColor
	paragraphStyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy
	paragraphStyle.lineBreakMode= NSLineBreakByClipping
	ParagraphStyle = paragraphStyle
	
	attr_reader :info_window, :info_view
		
	def string
		 st = @info_view.string
		 return 'nil' if !st
		 st
	end
	
	def string=(newstr)
		resize_window_to_fit_string(newstr)
		@info_view.string= newstr
	end
		
	def initialize
		resizingMask = NSViewWidthSizable + NSViewHeightSizable
		infoRect = [0,0,400,100]
		infoView = NSTextView.alloc.initWithFrame(infoRect)
		infoView.editable= false
		infoView.selectable= false
		infoView.drawsBackground= false
		infoView.textColor= TextColor
		infoView.font= TextFont
		infoView.defaultParagraphStyle= ParagraphStyle
		@info_view = infoView
		
		infoWindow = NSPanel.alloc.initWithContentRect_styleMask_backing_defer_(infoRect, NSBorderlessWindowMask, NSBackingStoreBuffered, false)
		infoWindow.backgroundColor=(NSColor.colorWithCalibratedWhite_alpha(0,0.8))
		infoWindow.opaque= false
		
		sv = scrollableView(infoView)
		sv.hasHorizontalScroller= true
		sv.hasVerticalScroller= true
		#sv.drawsBackground= true
		#sv.backgroundColor= NSColor.redColor
		sv.frame= [-2,-2,402,100]
		sv.drawsBackground= false
		
		container= NSView.alloc.initWithFrame([0,0,400,100])
		container.autoresizingMask= resizingMask
		container.addSubview sv
		infoWindow.contentView= container
		
		@info_window = infoWindow
	end
	
	def size_for_str(str=string)
		sz=NSString.stringWithString(str).sizeWithAttributes({NSFontAttributeName=>@info_view.font, NSParagraphStyleAttributeName=>@info_view.defaultParagraphStyle})
		sz.width += 7
		sz.height += 3
		sz
	end
	
	def snap_to_cursor()
		mousex = NSEvent.mouseLocation.x
		mousey = NSEvent.mouseLocation.y
		@info_window.frameTopLeftPoint= [mousex+20, mousey-20]
	end
	
	def resize_window_to_fit_string(str)
		extend_to = size_for_str(str).to_a
		win_frame = @info_window.frame
		win_frame.origin.y -= extend_to[1] - win_frame.size.height
		win_frame.size= extend_to
		@info_window.setFrame_display_animate_(win_frame, true, false)
	end
	
	def resize_window_to_fit_view(v)
		return unless v
		windowspace_rect = v.convertRect_toView_(v.visibleRect, nil)
		windowspace_origin = windowspace_rect.origin
		screen_origin = v.window.convertBaseToScreen(windowspace_origin)
		newframe = [screen_origin.x, screen_origin.y, windowspace_rect.size.width, windowspace_rect.size.height]
		sz = size_for_str();
		dw = sz.width - newframe[2];
		dh = sz.height - newframe[3];
		if dw>0 then
			hd = (dw/2).floor
			newframe[0] -= hd
			newframe[2] += 2*hd
			end
		if dh>0 then
			hd = (dh+1)/2
			newframe[1] -= hd
			newframe[3] += 2*hd
			end
		@info_window.setFrame_display_(newframe,true)
	end
	
	def parent_to_window_of(otherview)
		old_parent = @info_window.parentWindow
		new_parent = otherview ? otherview.window : nil
		return if old_parent==new_parent
		old_parent.removeChildWindow @info_window if old_parent
		otherview.window.addChildWindow_ordered_(@info_window,NSWindowAbove) if new_parent
	end
	
	def hide()
		@info_window.orderOut(nil)
	end
	
	def show()
		@info_window.makeKeyAndOrderFront(nil)
	end
	
	attr_reader :view
	def view=(newview)
		self.string= RubyConViewDescriber.describe(newview)
		@view = newview
	end
	
	def close()
		parent_to_window_of(nil)
		@info_window.close
		@info_window = nil
		@info_view = nil
	end
end
