# TextAttribute

A simple library for serializing large text blobs to disk instead of storing them in your database.  It's designed to work with Rails.  This is beta software.  Please fix or report bugs!

## An example

    class User < ActiveRecord::Base
      include TextAttribute

      text_attribute :novel
    end

    user = User.new
    user.novel = "Some huge string of text..."
    user.novel_changed?
    => true
    user.save!
    user.novel
    => "Some huge string of text..."
    user.novel_path
    => "your_project/text_cache/development/12a/45b/22a/User_1/novel"

## Compression

If you'd like your attribute files to be compressed, do the following:

    class User < ActiveRecord::Base
      include TextAttribute
      include TextAttribute::CompressedStorage

      text_attribute :novel
    end

Please note that once compressed storage has been enabled, you cannot turn it off without converting or wiping all of the attribute files.  The opposite is also true.  In the future it would be nice to be able to detect and translate between attributes created in compressed and uncompressed modes.

## Rails Testing

When testing in Rails, TextAttribute will use a temporary memory store.  You should clear this between tests or expect strange results.

    RSpec.configure do |c|
      config.before(:each) do
        $text_memory_store = {}
      end
    end
