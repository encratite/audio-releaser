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

  def getTrackNumberString(track)
    return sprintf('%02d', track.trackNumber)
  end

  def getMP3Filename(track)
    trackNumberString = getTrackNumberString(track)
    mp3Filename = scenifyString("#{trackNumberString}-#{track.artist}-#{track.title}-#{@configuration::GroupInitials}.mp3", true)
    return mp3Filename
  end

  def encodeMP3(track)
    mp3Filename = getMP3Filename(track)
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

  def getZeroBasePath(extension)
    fileName = "00-#{@baseReleaseString.downcase}.#{extension}"
    return Nil.joinPaths(@outputDirectory, fileName)
  end

  def processRelease(release)
    beginning = Time.now
    @release = release
    @baseReleaseString = scenifyString("#{release.artist}-#{release.title}-#{release.year}-#{@configuration::GroupInitials}")
    @outputDirectory = Nil.joinPaths(@configuration::ReleaseDirectory, @baseReleaseString)
    puts "Creating #{@outputDirectory}"
    FileUtils.mkdir_p(@outputDirectory)
    copyCover
    createJobs
    createM3U
    #createMP3s
    duration = Time.now - beginning
    printf("Duration: %.2f s\n", duration)
  end

  def createJobs
    @jobs = []
    trackNumber = 1
    @release.tracks.each do |track|
      if !File.exists?(track.wavPath)
        raise "Unable to find WAV: #{track.wavPath}"
      end
      newTrack = track.dup
      newTrack.trackNumber = trackNumber
      @jobs << newTrack
      trackNumber += 1
    end
  end

  def createMP3s
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
  end

  def copyCover
    FileUtils.cp(@release.coverPath, getZeroBasePath('jpg'))
  end

  def createM3U
    output = ";#{@baseReleaseString}\r\n"
    @jobs.each do |track|
      output += "#{getMP3Filename(track)}\r\n"
    end
    m3uPath = getZeroBasePath('m3u')
    Nil.writeFile(m3uPath, output)
  end

  def getMP3Duration(path)
    Mp3Info.open(path) do |mp3|
      return mp3.length.round
    end
  end
end
