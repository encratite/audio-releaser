require 'nil/symbol'

class Release
  include SymbolicAssignment

  Members = [
    :artist,
    :title,
    :genre,
    :label,
    :retailDate,
    :releaseDate,
    :encoder,
    :notes,
    :tracks,
  ]

  attr_reader *Members

  def initialize(*arguments)
    arguments.each do |key, value|
      if !Members.include?(key)
        raise "Unknown release key: #{key.inspect}"
      end
      setMember(key, value)
    end
    Members.each do |key|
      if getMember(key) == nil
        raise "Unspecified required member: #{key.inspect}"
      end
    end
  end

  def year
    return @releaseDate.year
  end
end
