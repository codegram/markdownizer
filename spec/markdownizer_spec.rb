require 'spec_helper'

describe Markdownizer do
  describe ".markdown(text)" do
    let(:text) { "#My markdown text"}
    context 'when the hierarchy is 0' do
      it 'calls RDiscount to markdownize the text' do
        rdiscount, html_markdown = double(:rdiscount), double(:html_markdown)

        RDiscount.should_receive(:new).with(text).and_return rdiscount
        rdiscount.should_receive(:to_html).and_return html_markdown
        
        subject.markdown(text).should == html_markdown
      end
    end
    context 'when the hierarchy is 2' do
      it "converts all headers into 2 levels deeper" do
        my_text = """
        #This is an H1
        ##This is an H2
        ###This is an H3
        """
        result = double :result, :to_html => true
        RDiscount.should_receive(:new).with do |t|
          t.should =~ /###This is an H1/
          t.should =~ /####This is an H2/
          t.should =~ /#####This is an H3/
        end.and_return result
        subject.markdown(my_text, 2)
      end
      it 'still does not convert anything that is not a header' do
        my_text = """
        #This is an H1
        I am talking about my #method
        {% code ruby %}
          \\#My comment
        {% endcode %}
        ###This is an H3
        """
        result = double :result, :to_html => true
        RDiscount.should_receive(:new).with do |t|
          t.should =~ /###This is an H1/
          t.should =~ /#method/
          t.should_not =~ /###method/
          t.should =~ /#My comment/
          t.should_not =~ /###My comment/
          t.should_not =~ /\\#My comment/
          t.should =~ /#####This is an H3/
        end.and_return result
        subject.markdown(my_text, 2)
      end
    end
  end
  describe ".coderay(text)" do
    let(:text) { """
      #My markdown text

      {% code ruby %}
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }
    let(:text_with_caption) { """
      #My markdown text

      {% code ruby %}
      {% caption 'This will become an h5' %}
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }
    let(:text_with_weird_caption) { """
      #My markdown text

      {% code ruby %}
      {% caption 'This will become an h5, with some/strange.characters\yo' %}
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }
    let(:text_with_array_highlights) { """
      #My markdown text

      {% code ruby %}
      {% highlight [1,2,3] %}
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }
    let(:text_with_range_highlights) { """
      #My markdown text

      {% code ruby %}
      {% highlight (1..3) %}
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }
    let(:text_with_comments) { """
      #My markdown text

      {% code ruby %}
        #My comment
        # My other comment
        def function(*args)
          puts 'result'
        end
      {% endcode %}

    """
    }

    it 'calls CodeRay to parse the code inside {% code ruby %} blocks' do
      scanned_code, html_code = double(:scanned_code), double(:html_code)

      CodeRay.should_receive(:scan).with("""def function(*args)
          puts 'result'
        end""", 'ruby').and_return scanned_code

      scanned_code.should_receive(:div).with(:css => :class, :my => :option).and_return 'parsed code'

      subject.coderay(text, :my => :option).should match('parsed code')
    end
    it 'accepts a caption option inside the code' do
      subject.coderay(text_with_caption).should match('<h5>This will become an h5</h5>')
    end
    it 'accepts a caption with weird chars inside the code' do
      subject.coderay(text_with_weird_caption).should match('<h5>This will become an h5, with some/strange.characters\yo</h5>')
    end
    it 'marks ruby comments to avoid conflicts with Markdown headers' do
      code = ''
      code.stub(:div).and_return ''
      CodeRay.should_receive(:scan).with do |string|
        string.should match(/\\#My comment/)
        string.should match(/\\# My other comment/)
      end.and_return code
      subject.coderay(text_with_comments)
    end
    it 'passes the caption to the div' do
      parsed = double :parsed
      CodeRay.should_receive(:scan).and_return parsed
      parsed.should_receive(:div).with(:css => :class, :caption => 'This will become an h5').and_return 'result'

      subject.coderay(text_with_caption)
    end
    it 'accepts highlighted lines with an array' do
      parsed = double :parsed
      CodeRay.should_receive(:scan).and_return parsed
      parsed.should_receive(:div).with(:css => :class, :highlight_lines => [1,2,3]).and_return 'result'

      subject.coderay(text_with_array_highlights)
    end
    it 'accepts highlighted lines with a range' do
      parsed = double :parsed
      CodeRay.should_receive(:scan).and_return parsed
      parsed.should_receive(:div).with(:css => :class, :highlight_lines => (1..3)).and_return 'result'

      subject.coderay(text_with_range_highlights)
    end
    it 'encloses everything in a nice class' do
      subject.coderay(text_with_caption).should match(/div class=\"markdownizer_code\" caption=\"This will become an h5\"/)
    end
  end

  describe Markdownizer::DSL do
    it 'integrates with ActiveRecord::Base' do
      (class << ActiveRecord::Base; self; end).ancestors.should include(Markdownizer::DSL)
    end

    before do
      ActiveRecord::Base.stub(:send)
      @klass = Class.new(ActiveRecord::Base)
      @klass.stub(:column_names) { %{body rendered_body} }
    end

    describe "#markdownize!(attribute)" do
      context "when either of attribute or rendered_attribute does not exist" do
        it 'raises' do
          expect {
            @klass.markdownize! :some_attribute             
          }.to raise_error
        end
      end
      context "otherwise" do
        it 'creates a before_save callback for render_attribute' do
          @klass.should_receive(:before_save).with(:render_body)
          @klass.markdownize! :body
        end
        it 'defines this render_attribute method' do
          klass = Class.new do
            extend Markdownizer::DSL
            def self.column_names
              %{body rendered_body}
            end
          end

          klass.stub(:before_save)
          klass.markdownize! :body

          raw_body, raw_body_with_code, final_code = double(:raw_body),
                                                      double(:raw_body_with_code),
                                                        double(:final_code)

          instance = klass.new
          instance.should_receive(:send).with(:body).and_return raw_body
          Markdownizer.should_receive(:coderay).with(raw_body, {}).and_return raw_body_with_code
          Markdownizer.should_receive(:markdown).with(raw_body_with_code, 0).and_return final_code

          instance.should_receive(:send).with(:rendered_body=, final_code)
          instance.render_body
        end
      end
    end
  end
end
