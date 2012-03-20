require 'ostruct'
require 'optparse'
require 'paint'

# Customized version of ruby's OptionParser.
class Iopts < OptionParser

  attr_accessor :funnel

  def self.section_title title
    Paint[title, :bold]
  end

  def self.section_title_ref ref
    Paint[ref, :underline]
  end

  def initialize *args
    options = args.last.kind_of?(Hash) ? args.pop : {}

    @funnel = options[:funnel] || OpenStruct.new
    @footer = options[:footer]
    @examples = options[:examples]

    width = options[:width] || 32
    indent = options[:indent] || (' ' * 2)
    super nil, width, indent

    @banner = options[:banner].kind_of?(Hash) ? summary_banner_section(options[:banner]) : options[:banner]
  end

  def on *args
    if block_given?
      super(*args)
    else
      sw = make_switch(args)
      return super(*args) if !sw || sw.empty? || !sw.first.respond_to?(:long)
      name = sw.first.long.first || sw.first.short.first
      return super(*args) unless name
      name = name.sub /^\-+/, ''
      block = lambda{ |val| fill_funnel name, val }
      super(*args, &block)
    end
  end

  def program_name
    @program_name || File.basename($0)
  end

  def to_s
    "#{super}#{summary_examples_section}#{@footer}"
  end

  def help!
    self.on('-h', '--help', 'show this help and exit'){ puts self; exit 0 }
  end

  def usage!
    self.on('-u', '--usage', 'show this help and exit'){ puts self; exit 0 }
  end

  private

  def fill_funnel name, value
    if @funnel.kind_of? OpenStruct
      @funnel.send "#{name}=", value
    elsif @funnel.kind_of? Hash
      @funnel[name] = value
    end
  end

  def summary_program_name
    Paint[program_name, :bold]
  end

  def summary_banner_section *args
    options = args.extract_options!
    %|#{summary_program_name} #{options[:description]}

#{self.class.section_title :USAGE}
#{@summary_indent}#{summary_program_name} #{options[:usage]}

#{self.class.section_title :OPTIONS}
|
  end

  def summary_examples_section
    return nil unless @examples
    String.new("\n#{self.class.section_title :EXAMPLES}").tap do |s|
      @examples.each do |example|
        s << "\n#{@summary_indent}#{summary_program_name} #{example}"
      end
    end
  end
end
