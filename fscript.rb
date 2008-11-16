class ConsoleWindowFactory < NSObject
	def patch_fscript(fs_menu)
		if fs_menu
			fs_mitem_console = fs_menu.itemArray.find{|x| x.title.to_s=~/console/i}
			fs_mitem_browser = fs_menu.itemArray.find{|x| x.title.to_s=~/browser/i}
			if fs_mitem_console
				fs_mitem_console.keyEquivalent= 'F'
				fs_mitem_console.keyEquivalentModifierMask= NSCommandKeyMask+NSAlternateKeyMask
				end
			if fs_mitem_browser
				fs_mitem_browser.keyEquivalent= 'B'
				fs_mitem_browser.keyEquivalentModifierMask= NSCommandKeyMask+NSAlternateKeyMask
				end
			end
		end
	end

#Allows bidirectional communication with FScript
module FScript
	def self.autobridges
		@autobridges
	end
	
	def self.autobridges=(nval)
		@autobridges=nval
	end
	
	def self.autobridge_locals(local_hash)
		local_hash.each_pair {|k,v| self[k]=v} unless !@autobridges
	end
	
	def self.[](varname)
		$FScript_menu.interpreterView.interpreter.objectForIdentifier_found_(varname,nil)
	end

	def self.[]=(var,val)
		$FScript_menu.interpreterView.interpreter.setObject_forIdentifier_(val,var)
	end

	def self.vars
		RubyConUtilities.arrayByCallingSelector_onObject_('identifiers', $FScript_menu.interpreterView.interpreter)
	end
end

FScript.autobridges= true