require 'nil/file'

class LineInformation
  attr_reader :lineIndex, :firstIndex, :lastIndex

  def initialize(lineIndex, firstIndex, lastIndex)
    @lineIndex = lineIndex
    @firstIndex = firstIndex
    @lastIndex = lastIndex
  end
end

class NFOTemplate
  DelimiterLeft = '['
  DelimiterRight = ']'

  def initialize(path)
    contents = Nil.readFile(path)
    @lines = contents.split("\n")
    loadFields
  end

  def loadFields
    @fields = {}
    activeField = nil
    lineIndex = 0
    @lines.each do |line|
      lineNumber = lineIndex + 1
      firstIndex = line.index(DelimiterLeft)
      if firstIndex == nil
        next
      end
      lastIndex = line.index(DelimiterRight)
      if lastIndex == nil
        raise "Encountered an improperly terminated field on line #{lineNumber}"
      end
      fieldName = line[firstIndex + 1..lastIndex - 1].strip
      if !fieldName.empty?
        activeField = @fields[fieldName]
        if activeField == nil
          activeField = []
          @fields[fieldName] = activeField
        end
      end
      if activeField == nil
        raise "Encountered an unnamed field on line #{lineNumber}"
      end
      information = LineInformation.new(lineIndex, firstIndex, lastIndex)
      activeField << information
      lineIndex += 1
    end
  end

  def writeNFO(outputPath, fieldValues)
    modifiedLines = lines
    @fields.each do |name, lineInformationArray|
      value = fieldValues[name]
      if value == nil
        raise "Unable to find a value for the NFO field #{name.inspect}"
      end
      
    end
  end
end
