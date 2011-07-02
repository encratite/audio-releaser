require 'AudioReleaser'
require 'Configuration'

if ARGV.size != 1
  puts 'Usage:'
  puts "ruby #{File.basename(__FILE__)} <release configuration file>"
  exit
end

require_relative ARGV.first

releaser = AudioRelease.new(Configuration)
releaser.processRelease(Release)
