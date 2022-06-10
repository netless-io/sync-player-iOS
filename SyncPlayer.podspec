Pod::Spec.new do |s|
  s.name             = 'SyncPlayer'
  s.version          = '0.1.0'
  s.summary          = 'Sync play multiple media sources'

  s.description      = <<-DESC
Synchronize playback status across multiple different media sources
                       DESC

  s.homepage         = 'https://github.com/netless-io/sync-player-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xuyunshi' => 'zjxuyunshi@gmail.com' }
  s.source           = { :git => 'https://github.com/netless-io/sync-player-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'SyncPlayer/Classes/**/*'
  s.frameworks = 'AVFoundation'
  
end
