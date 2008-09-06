class <<self
	alias_method(:method_missing_before_rubycon, :method_missing)
	def method_missing(id, *params)
		if params.empty?
			fs_val = FScript[id.to_s]
			return fs_val if fs_val
		end
		method_missing_before_rubycon(id, *params)
	end
end

class ConsoleWindowFactory < OSX::NSObject
	def patch_fscript(fs_menu)
		if fs_menu
			fs_mitem_console = fs_menu.itemArray.find{|x| x.title.to_s=~/console/i}
			fs_mitem_browser = fs_menu.itemArray.find{|x| x.title.to_s=~/browser/i}
			if fs_mitem_console
				fs_mitem_console.keyEquivalent= 'F'
				fs_mitem_console.keyEquivalentModifierMask= OSX::NSCommandKeyMask+OSX::NSAlternateKeyMask
				end
			if fs_mitem_browser
				fs_mitem_browser.keyEquivalent= 'B'
				fs_mitem_browser.keyEquivalentModifierMask= OSX::NSCommandKeyMask+OSX::NSAlternateKeyMask
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
		OSX::RubyConUtilities.arrayByCallingSelector_onObject_('identifiers', $FScript_menu.interpreterView.interpreter)
	end
end

FScript.autobridges= true