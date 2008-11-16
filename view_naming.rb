require 'info_window_controller'
require 'label_window_controller'
require 'focus_window_controller'

class ConsoleWindowFactory < NSObject
	def nameView(sender)
		crosshair_cursor = NSCursor.crosshairCursor
		future = NSDate.distantFuture
		
		focusWindow = FocusWindowController.new()
		
		viewLabelArray = [] #One corresponds to each selection. The 'temporary' info window is not in the array.
		temporaryInfoWindow = InfoWindowController.new()
		hit_view = nil
		pos = nil
		i=0
		old_pos = 
		loop do
			crosshair_cursor.push
			event = NSApplication.sharedApplication.nextEventMatchingMask_untilDate_inMode_dequeue_(0x7FFFFFFF, NSDate.dateWithTimeIntervalSinceNow(0.5), NSEventTrackingRunLoopMode, true)
			crosshair_cursor.pop
			new_hit_view = nil
			new_hit_view = hit_view if pos == NSEvent.mouseLocation
			pos = NSEvent.mouseLocation
			
			#Deal with movement
			if !new_hit_view then
				#See which view we are over
				NSWindow.listOfAllAppWindows
				ignore_winds = viewLabelArray.map{|x| x.info_window}
				ignore_views = viewLabelArray.map{|x| x.info_view}
				winds = NSWindow.listOfAllAppWindows.reject {|x| x==focusWindow.info_window || ignore_winds.include?(x)}
				winds.each {|x|
					new_hit_view = x.contentView.superview.hitTest(x.convertScreenToBase(pos))
					new_hit_view = nil if new_hit_view and ignore_winds.include?(new_hit_view.window)
					#new_hit_view = nil if ignore_views.include?(new_hit_view)
					break if new_hit_view
				}

				#Deal with view changes
				temporaryInfoWindow.snap_to_cursor()
				if new_hit_view!=hit_view then
					hit_view = new_hit_view
					focusWindow.view= hit_view
					temporaryInfoWindow.view= hit_view
					hit_view ? temporaryInfoWindow.show() : temporaryInfoWindow.hide()
				end
			end
			
			next unless event
			
			#Deal with clicks
			if event.oc_type==NSLeftMouseDown then
				break if (hit_view==nil || viewLabelArray.find {|x| x.view==hit_view})
				iw = LabelWindowController.new(hit_view, viewLabelArray.size)
				viewLabelArray<<iw
				iw.show
				break if (event.modifierFlags | NSCommandKeyMask)==0
			end
			
			#Deal with keys (any keydown will finish the selection)
			break if event.oc_type==NSKeyDown
		end
		temporaryInfoWindow.close
		focusWindow.close
		viewLabelArray.each_index{|i|
			x = viewLabelArray[i]
			FScript["v#{i}"]=x.view
			x.close
		}
	end
end