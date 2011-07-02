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
    if contents == nil
      raise "Unable to read NFO template #{path.inspect}"
    end
    @lines = contents.split("\n")
    loadFields
  end

  def loadFields
    @fields = {}
    activeField = nil
    lineIndex = nil
    @lines.each do |line|
      if lineIndex == nil
        lineIndex = 0
      else
        lineIndex += 1
      end
      lineNumber = lineIndex + 1
      firstIndex = line.index(DelimiterLeft)
      if firstIndex == nil
        next
      end
      lastIndex = line.index(DelimiterRight, firstIndex + 1)
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
    end
  end

  def writeNFO(outputPath, fieldValues)
    modifiedLines = @lines.dup
    @fields.each do |name, lineInformationArray|
      value = fieldValues[name]
      if value == nil
        raise "Unable to find a value for the NFO field #{name.inspect}"
      end
      if name == 'tracks'
        #requires different handling due to white-space preservation and the table format
      else
        words = value.split(' ')
        lineInformationArray.each do |lineInformation|
          currentIndex = lineInformation.firstIndex
          currentLine = modifiedLines[lineInformation.lineIndex]
          currentLine[lineInformation.firstIndex..lineInformation.lastIndex] = ' ' * (lineInformation.lastIndex - lineInformation.firstIndex + 1)
          first = true
          while !words.empty?
            remainingSpace = lineInformation.lastIndex - currentIndex
            currentWord = words.first
            if currentWord.size > remainingSpace
              break
            end
            words.shift
            if first
              first = false
            else
              currentWord = ' ' + currentWord
            end
            currentLine[currentIndex..currentIndex + currentWord.size - 1] = currentWord
            currentIndex += currentWord.size
          end
        end
        if !words.empty?
          raise "Unable to fill field #{name} - there was not enough space in the NFO"
        end
      end
    end
    output = modifiedLines.join("\n")
    Nil.writeFile(outputPath, output)
  end
end
