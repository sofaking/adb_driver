require 'rexml/document'
require 'rexml/sax2listener'
require 'rexml/parsers/sax2parser'

module SourceCleaner
  def self.call(page_source)
    p = REXML::Parsers::SAX2Parser.new(page_source)
    p.listen(MrProper.new)
    p.parse
  end

  class MrProper
    include REXML::SAX2Listener

    BORING_ATTRS = %w(class index package
                    checkable checked clickable
                    enabled focusable focused
                    scrollable long-clickable password
                    selected bounds instance)

    INDENT_WIDTH = 2
    ATTRIBUTES_INDENT = 4

    def initialize
      @indent = 0
    end

    def start_element(uri, localname, qname, attributes)
      return if localname == 'hierarchy'

      @indent += 1

      node = ' ' * INDENT_WIDTH * @indent
      node << "class_name: '#{attributes['class']}'"

      clean_attributes = attributes.delete_if { |k, v| BORING_ATTRS.include?(k) || v.empty? }

      if value = clean_attributes.delete('resource-id')
        clean_attributes[:id] = value
      end

      if value = clean_attributes.delete('content-desc')
        clean_attributes[:content_desc] = value
      end

      unless clean_attributes.empty?
        node << ' ' * ATTRIBUTES_INDENT
        node << clean_attributes.map { |k, v| "#{k}: '#{v}'" }.join(', ')
      end

      puts node
    end

    def end_element(uri, localname, qname)
      @indent -= 1
    end
  end
end

SourceCleaner.call(ARGF.read) if $PROGRAM_NAME == __FILE__
