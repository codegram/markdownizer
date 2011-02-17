# **Markdownizer** is a simple solution to a simple problem.
#
# It is a lightweight Rails 3 gem which enhances any ActiveRecord model with a
# singleton `markdownize!` method, which makes any text attribute renderable as
# Markdown. It mixes CodeRay and RDiscount to give you awesome code
# highlighting, too!
#
# If you have any suggestion regarding new features, Check out the [Github repo][gh],
# fork it and submit a nice pull request :)
#

#### Install Markdownizer

# Get Markdownizer in your Rails 3 app through your Gemfile:
#
#     gem 'markdownizer'
#
# If you don't use Bundler, you can alternatively install Markdownizer with
# Rubygems:
#
#     gem install markdownizer
#
# If you want code highlighting, you should run this generator too:
#
#     rails generate markdownizer:install
#
# This will place a `markdownizer.css` file in your `public/stylesheets`
# folder. You will have to require it manually in your layouts, or through
# `jammit`, or whatever.
# 
# [gh]: http://github.com/codegram/markdownizer

#### Usage

# In your model, let's say, `Post`:
#
#     class Post < ActiveRecord::Base
#       # In this case we want to treat :body as markdown
#       # This will require `body` and `rendered_body` fields
#       # to exist previously (otherwise it will raise an error).
#       markdownize! :body
#     end
#
# Then you can create a `Post` using Markdown syntax, like this:
#
#    Post.create body: """
#       # My H1 title
#       Markdown is awesome!
#       ## Some H2 title...
# 
#       {% code ruby %}
# 
#         # All this code will be highlighted properly! :)
#         def my_method(*my_args)
#           something do
#             3 + 4
#           end
#         end
# 
#       {% endcode %}
#    """
#
# After that, in your view you just have to call `@post.rendered_body` and,
# provided you included the generated css in your layout, it will display nice
# and coloured :)

#### Show me the code!

# We'll need to include [RDiscount][rd]. This is the Markdown parsing library.
# Also, [CodeRay][cr] will provide code highlighting. We require `active_record` as
# well, since we want to extend it with our DSL.
#
# [rd]: http://github.com/rtomayko/rdiscount
# [cr]: http://github.com/rubychan/coderay
require 'rdiscount'
require 'coderay'
require 'active_record' unless defined?(ActiveRecord)

module Markdownizer

  class << self
    # Here we define two helper methods. These will be called from the model to
    # perform the corresponding conversions and parsings.
   
    # `Markdownizer.markdown` method converts plain Markdown text to formatted html.
    # To parse the markdown in a coherent hierarchical context, you must provide it
    # with the current hierarchical level of the text to be parsed.
    def markdown(text, hierarchy = 0)
      text.gsub! %r[^(\s*)(#+)(.+)$] do
        $1 << ('#' * hierarchy) << $2 << $3
      end
      text.gsub!("\\#",'#')
      RDiscount.new(text).to_html
    end

    # `Markdownizer.coderay` method parses a code block delimited from `{% code
    # ruby %}` until `{% endcode %}` and replaces it with appropriate classes for
    # code highlighting. It can take many languages aside from Ruby.
    #
    # With a hash of options you can specify `:line_numbers` (`:table` or `:inline`),
    # and the class of the enclosing div with `:enclosing_class`.
    #
    # It also parses a couple of special idioms:
    #
    #   * {% caption 'my caption' %} introduces an h5 before the code and passes
    #     the caption to the enclosing div as well.
    #
    #   * {% highlight [1,2,3] %} highlights lines 1, 2 and 3. It accepts any
    #     Enumerable, so you can also give a Range (1..3).
    #
    def coderay(text, options = {})
      text.gsub(%r[\{% code (\w+?) %\}(.+?)\{% endcode %\}]m) do
        options.delete(:highlight_lines)
        options.delete(:caption)

        enclosing_class = options[:enclosing_class] || 'markdownizer_code'

        code, language = $2.strip, $1.strip

        # Mark comments to avoid conflicts with Header parsing
        code.gsub!(/(#+)/) do
          '\\' + $1
        end

        code, options, caption = extract_caption_from(code, options)
        code, options = extract_highlights_from(code, options)

        html_caption = caption ? '<h5>' << caption << '</h5>' : nil

        "<div class=\"#{enclosing_class}#{caption ? "\" caption=\"#{caption}" : ''}\">" << 
          (html_caption || '') <<
            CodeRay.scan(code, language).div({:css => :class}.merge(options)) <<
              "</div>"
      end
    end

    private

    def extract_caption_from(code, options)
      caption = nil
      code.gsub!(%r[\{% caption '([^']+)' %\}]) do
        options.merge!({:caption => $1.strip}) if $1
        caption = $1.strip
        ''
      end
      [code.strip, options, caption]
    end

    # FIXME: Find a safer way to eval code, MY LORD
    def extract_highlights_from(code, options)
      code.gsub!(%r[\{% highlight (.+) %\}]) do
        enumerable = eval($1.strip)
        enumerable = (Enumerable === enumerable)? enumerable : nil
        options.merge!({:highlight_lines => enumerable}) if enumerable
        ''
      end
      [code.strip, options]
    end

  end

  #### Public interface
  
  # The Markdownizer DSL is the public interface of the gem, and can be called
  # from any ActiveRecord model.
  module DSL

    # Calling `markdownize! :attribute` (where `:attribute` can be any database
    # attribute with type `text`) will treat this field as Markdown.
    # You can pass an `options` hash for CodeRay. An example option would be:
    #   
    #   * `:line_numbers => :table` (or `:inline`)
    #
    # You can check other available options in CodeRay's documentation.
    def markdownize! attribute, options = {}
      # Check that both `:attribute` and `:rendered_attribute` columns exist.
      # If they don't, it raises an error indicating that the user should generate
      # a migration.
      unless self.column_names.include?(attribute.to_s) &&
               self.column_names.include?("rendered_#{attribute}")
        raise "#{self.name} doesn't have required attributes :#{attribute} and :rendered_#{attribute}\nPlease generate a migration to add these attributes -- both should have type :text."
      end

      # The `:hierarchy` option tells Markdownizer the smallest header tag that
      # precedes the Markdown text. If you have a blogpost with an H1 (title) and
      # an H2 (some kind of tagline), then your hierarchy is 2, and the biggest
      # header found the markdown text will be translated directly to an H3. This
      # allows for semantical coherence within the context where the markdown text
      # is to be introduced.
      hierarchy = options.delete(:hierarchy) || 0

      # Create a `before_save` callback which will convert plain text to
      # Markdownized html every time the model is saved.
      self.before_save :"render_#{attribute}"

      # Define the converter method, which will assign the rendered html to the
      # `:rendered_attribute` field.
      define_method :"render_#{attribute}" do
        self.send(:"rendered_#{attribute}=", Markdownizer.markdown(Markdownizer.coderay(self.send(attribute), options), hierarchy))
      end
    end
  end

end

# Finally, make our DSL available to any class inheriting from ActiveRecord::Base.
ActiveRecord::Base.send(:extend, Markdownizer::DSL)

# And that's it!
