class RubyConViewDescriber
	def self.describe(v)
		return "" unless v
		
		#Objective-C Description
		str = v.to_s
		
		#Generic View Description
		str+="\nFrame: #{v.frame.to_a.inspect}"
		str+="\nBounds: #{v.bounds.to_a.inspect}"
		
		#NSControl Description
		if v.is_a?(OSX::NSControl) then
		str+="\nTarget: #{v.target.to_s}"
		str+="\nAction: #{v.action.to_s}"
		end
		
		#Tag
		if v.respondsToSelector('tag')
			str+="\nTag: #{v.tag}"
		end
		
		#Key-equiv Controls
		if v.respondsToSelector('keyEquivalent') && v.respondsToSelector('keyEquivalentModifierMask') && v.keyEquivalent && !v.keyEquivalent.empty?
			mask=v.keyEquivalentModifierMask
			equiv=OSX::NSString.stringWithString("")
			equiv=equiv.stringByAppendingFormat("%C",0x21E7) if (mask|OSX::NSShiftKeyMask)!=0
			equiv=equiv.stringByAppendingFormat("%C",0x2325) if (mask|OSX::NSOptionKeyMask)!=0
			equiv=equiv.stringByAppendingFormat("%C",0x2303) if (mask|OSX::NSControlKeyMask)!=0
			equiv=equiv.stringByAppendingFormat("%C",0x2318) if (mask|OSX::NSCommandKeyMask)!=0
			equiv=equiv.stringByAppendingString(v.keyEquivalent)
			str+=equiv
		end
		
		str
	end
end