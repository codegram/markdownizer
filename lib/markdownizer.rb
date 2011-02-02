require 'rdiscount'
require 'coderay'
require 'active_record' unless defined?(ActiveRecord)

module Markdownizer

  class << self
    def markdown(text)
      RDiscount.new(text).to_html
    end

    def coderay(text)
      text.gsub(%r[\{% highlight (\w+?) %\}(.+?)\{% endhighlight %\}]m) do
        CodeRay.scan($2, $1).div(:css => :class)
      end
    end
  end

  module DSL
    def markdownize! attribute
      unless self.column_names.include?(attribute.to_s) &&
               self.column_names.include?("rendered_#{attribute}")
        raise "#{self.name} doesn't have required attributes :#{attribute} and :rendered_#{attribute}\nPlease generate a migration to add these attributes -- both should have type :text."
      end
      self.before_save :"render_#{attribute}"

      define_method :"render_#{attribute}" do
        self.send(:"rendered_#{attribute}=", Markdownizer.markdown(Markdownizer.coderay(self.send(attribute))))
      end
    end
  end

end

ActiveRecord::Base.send(:extend, Markdownizer::DSL)
