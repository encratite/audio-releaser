require 'mp3info'
require 'thread'
require 'fileutils'

require 'nil/file'

class AudioReleaser
  def initialize(configuration)
    @configuration = configuration
    @mutex = Mutex.new
  end

  def scenifyString(string, lowerCase = false)
    output = string.gsub(' ', '_')
    if lowerCase
      output.downcase!
    end
    return output
  end

  def encodingThread(release, outputDirectory, trackNumber, track)
    mp3Filename = scenify("#{trackNumber}-#{track.artist}-#{track.title}-#{@configuration::GroupInitials}.mp3", true)
    outputPath = Nil.joinPaths(outputDirectory, mp3Filename)
    map = {
      'input' => track.wavPath,
      'output' => outputPath,
      'title' => track.title,
      'artist' => track.artist,
      'album' => release.title,
      'year' => release.year,
    }
  end

  def processRelease(release)
    baseReleaseString = scenifyString("#{release.artist}-#{release.name}-#{release.year}-#{@configuration::GroupInitials}")
    outputDirectory = Nil.joinPaths(@configuration::ReleaseDirectory, baseReleaseString)
    puts "Creating #{outputDirectory}"
    FileUtils.mkdir_p(outputDirectory)
    release.tracks.each do |track|
      
    end
  end

  def getMP3Duration(path)
    Mp3Info.open(path) do |mp3|
      return mp3.length.round
    end
  end
end
