class Track
  attr_reader :wavPath, :artist, :title

  attr_accessor :trackNumber

  def initialize(wavPath, artist, title)
    @wavPath = wavPath
    @artist = artist
    @title = title
  end
end
