Pod::Spec.new do |s|
s.name             = 'Extensions'
s.version          = '9.2.1'
s.summary          = 'SenseTime effect plugin for声网 RTE extensions.'
s.description      = 'project.description'
s.homepage         = 'https://github.com/JamieLiu67/AgoraMarketPlace_ST_Flutter'
s.author           = { 'Agora' => ';liushiqin@agora.io, liuming02@agora.io' }
s.source           = { :path => '.' }
s.vendored_frameworks = 'AgoraSenseTimeExtension.framework'
s.platform = :ios, '12.0'
end