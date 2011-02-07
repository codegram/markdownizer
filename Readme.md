#Markdownizer

A simple gem for Rails 3 to render some ActiveRecord text field as Markdown!

It mixes CodeRay and RDiscount to give you awesome code highlighting :)

You can check the generated Rocco documentation on the [project
page](http://codegram.github.com/markdownizer).

##Install

In your Gemfile:

    gem 'markdownizer'

If you want code highlighting, you should run this generator too:

    rails generate markdownizer:install

This will place a markdownizer.css file in your `public/stylesheets` folder.
You will have to require it manually in your layouts, or through `jammit`, or
whatever.

## Usage

In your model, let's say, Post:

    class Post < ActiveRecord::Base
      markdownize! :body
      # In this case we want to treat :body as markdown.
      # You can pass an options hash to the code renderer, such as:
      #
      #   markdownize! :body, :line_numbers => :table
      #
    end

Markdownizer needs an additional field (`:rendered_body`), which you should
generate in a migration. (If the attribute was `:some_other_field`, it would need
`:rendered_some_other_field`!) All these fields should have the type `:text`.

You save your posts with markdown text like this:

    Post.create body: """
      # My H1 title
      Markdown is awesome!
      ## Some H2 title...

      {% caption 'This caption will become an h5 and also a property of the enclosing div' %}
      {% code ruby %}

        # All this code will be highlighted properly! :)
        def my_method(*my_args)
          something do
            . . .
          end
        end

      {% endcode %}
    """

And then, in your view you just have to call `@post.rendered_body` :)

##Contribute!

* Fork the project.
* Make your feature addition or bug fix.
* Add specs for it. This is important so I don't break it in a future
  version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  If you want to have your own version, that is fine but bump version
  in a commit by itself I can ignore when I pull.
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Codegram. See LICENSE for details.
