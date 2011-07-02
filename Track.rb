class Track
  attr_reader :wavPath, :artist, :title

  def initialize(wavPath, artist, title)
    @wavPath = wavPath
    @artist = artist
    @title = title
  end
end
