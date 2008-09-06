#Paths computed exactly as in rubycon
global_rc_path = OSX::NSBundle.bundleForClass(OSX::RubyConLoader).pathForResource_ofType_('rubyconrc','rb')
usr_rc_path = File.expand_path('~/.rubyconrc.rb')
app_rc_path = OSX::NSBundle.mainBundle.pathForResource_ofType_('rubyconrc','rb')

puts "Loading global rubycon RC script @ #{global_rc_path}"
puts "Which would be overridden by RC script @ #{usr_rc_path}"
puts "Which would be overridden by RC script @ #{OSX::NSBundle.mainBundle.resourcePath+'/rubyconrc.rb'}"
puts "Local variables are bridged between FScript and RubyCon."