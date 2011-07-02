require 'mp3info'
require 'thread'
require 'fileutils'

require 'nil/file'
require 'nil/console'

require 'audio-releaser/Configuration'

class AudioReleaser
  def initialize(configuration = Configuration)
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

  def encodeMP3(track)
    #puts track.inspect
    trackNumberString = sprintf('%02d', track.trackNumber)
    mp3Filename = scenifyString("#{trackNumberString}-#{track.artist}-#{track.title}-#{@configuration::GroupInitials}.mp3", true)
    outputPath = Nil.joinPaths(@outputDirectory, mp3Filename)
    replacementMap = {
      'input' => track.wavPath,
      'output' => outputPath,
      'title' => track.title,
      'artist' => track.artist,
      'album' => @release.title,
      'year' => @release.year.to_s,
      'comment' => @configuration::GroupInitials,
      'trackNumber' => track.trackNumber.to_s,
      'genre' => @release.genre,
    }
    commandLine = @configuration::EncoderCommandLine.dup
    replacementMap.each do |target, replacement|
      actualTarget = "$#{target}$"
      commandLine.gsub!(actualTarget, replacement)
    end
    #Nil.threadPrint "Executing #{commandLine.inspect}"
    Nil.threadPrint "Processing #{track.wavPath}"
    `#{commandLine}`
  end

  def encoderThread
    while true
      track = nil
      @mutex.synchronize do
        if @jobs.empty?
          return
        end
        track = @jobs.shift
      end
      encodeMP3(track)
    end
  end

  def processRelease(release)
    beginning = Time.now
    @release = release
    baseReleaseString = scenifyString("#{release.artist}-#{release.title}-#{release.year}-#{@configuration::GroupInitials}")
    @outputDirectory = Nil.joinPaths(@configuration::ReleaseDirectory, baseReleaseString)
    puts "Creating #{@outputDirectory}"
    FileUtils.mkdir_p(@outputDirectory)
    @jobs = []
    trackNumber = 1
    release.tracks.each do |track|
      if !File.exists?(track.wavPath)
        raise "Unable to find WAV: #{track.wavPath}"
      end
      newTrack = track.dup
      newTrack.trackNumber = trackNumber
      @jobs << newTrack
      trackNumber += 1
    end
    threads = []
    @configuration::WorkerCount.times do
      thread = Thread.new do
        encoderThread
      end
      threads << thread
    end
    threads.each do |thread|
      thread.join
    end
    duration = Time.now - beginning
    printf("Duration: %.2f s\n", duration)
  end

  def getMP3Duration(path)
    Mp3Info.open(path) do |mp3|
      return mp3.length.round
    end
  end
end
