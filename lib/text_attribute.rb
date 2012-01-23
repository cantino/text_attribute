require "text_attribute/version"
require 'digest/md5'
require 'fileutils'
require 'zlib'

module TextAttribute
  module TestMemoryStorage
    def write_text_file(attribute_name, data)
      $text_memory_store ||= {}
      $text_memory_store[File.join(text_cache_path, attribute_name.to_s)] = data
    end

    def read_text_file(attribute_name)
      $text_memory_store ||= {}
      $text_memory_store[File.join(text_cache_path, attribute_name.to_s)]
    end

    def text_file_exists?(attribute_name)
      !!$text_memory_store[File.join(text_cache_path, attribute_name.to_s)]
    end

    def remove_text_file(attribute_name)
      $text_memory_store ||= {}
      $text_memory_store.delete(File.join(text_cache_path, attribute_name.to_s))
    end
  end

  module FileSystemStorage
    def write_text_file(attribute_name, data)
      path = text_cache_path
      FileUtils.mkdir_p path, :verbose => false
      File.open(File.join(path, attribute_name.to_s), 'wb') do |file|
        file.print data
      end
    end

    def read_text_file(attribute_name)
      path = File.join(text_cache_path, attribute_name.to_s)
      File.exists?(path) && File.read(path)
    end

    def text_file_exists?(attribute_name)
      path = File.join(text_cache_path, attribute_name.to_s)
      File.exists?(path)
    end

    def remove_text_file(attribute_name)
      path = File.join(text_cache_path, attribute_name.to_s)
      File.exists?(path) && FileUtils.rm(path)#, options[:verbose] => false)

      dir = path
      while (dir = File.dirname(dir)) && File.exists?(dir) && (Dir.entries(dir) - [".", ".."]).empty?
        FileUtils.rmdir dir
      end
    end
  end

  module CompressedStorage
    def self.included(klass)
      klass.class_eval do
        alias_method :uncompressed_write_text_file, :write_text_file
        alias_method :uncompressed_read_text_file,  :read_text_file

        def write_text_file(attribute_name, data)
          uncompressed_write_text_file(attribute_name, [data.encoding.to_s, Zlib::Deflate.deflate(data.to_s)].join("|"))
        end

        def read_text_file(attribute_name)
          data = uncompressed_read_text_file(attribute_name)
          if data
            encoding, _sep, compressed_data = data.partition("|")
            Zlib::Inflate.inflate(compressed_data).force_encoding(encoding)
          end
        end
      end
    end
  end

  def text_cache_path
    identifier = self.class.to_s + "_" + id.to_s
    hash = Digest::MD5.hexdigest(identifier).scan(/.../)[0...3].join("/")
    if defined?(Rails)
      File.join(Rails.root, "text_cache", Rails.env, hash, identifier)
    elsif defined?(text_attribute_root)
      File.join(text_attribute_root, "text_cache", hash, identifier)
    else
      File.join("text_cache", hash, identifier)
    end
  end

  module ClassMethods
    def text_attribute(text_attribute)
      class_eval do
        define_method "#{text_attribute}=" do |value|
          unless instance_variable_defined?("@#{text_attribute}_text_old_value")
            instance_variable_set("@#{text_attribute}_text_old_value", send(text_attribute))
          end
          instance_variable_set("@#{text_attribute}_text", value)
        end

        define_method text_attribute do
          if instance_variable_defined?("@#{text_attribute}_text")
            instance_variable_get("@#{text_attribute}_text")
          else
            result = id && read_text_file(text_attribute)
            if result
              instance_variable_set("@#{text_attribute}_text", result)
            else
              instance_variable_set("@#{text_attribute}_text", nil)
            end
          end
        end

        define_method "store_#{text_attribute}" do
          if send("#{text_attribute}_changed?")
            write_text_file(text_attribute, instance_variable_get("@#{text_attribute}_text"))
          end
          remove_instance_variable("@#{text_attribute}_text_old_value") if instance_variable_defined?("@#{text_attribute}_text_old_value")
          true
        end

        define_method "#{text_attribute}_path" do
          File.join(text_cache_path, text_attribute.to_s)
        end

        define_method "#{text_attribute}_changed?" do
          if instance_variable_defined?("@#{text_attribute}_text_old_value")
            instance_variable_get("@#{text_attribute}_text_old_value") != send(text_attribute)
          else
            false
          end
        end

        define_method "remove_#{text_attribute}" do
          remove_instance_variable("@#{text_attribute}_text_old_value") if instance_variable_defined?("@#{text_attribute}_text_old_value")
          remove_instance_variable("@#{text_attribute}_text") if instance_variable_defined?("@#{text_attribute}_text")
          remove_text_file(text_attribute)
        end

        define_method "#{text_attribute}_exists?" do
          instance_variable_defined?("@#{text_attribute}_text") || text_file_exists?(text_attribute)
        end

        if defined?(after_save)
          after_save "store_#{text_attribute}"
        end

        if defined?(after_destroy)
          after_destroy "remove_#{text_attribute}"
        end
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
    if defined?(Rails)
      if Rails.env.test?
        klass.send :include, TestMemoryStorage
      else
        klass.send :include, FileSystemStorage
      end
    else
      STDERR.puts "You are using TextAttribute without Rails.  You'll need to manually include TextAttribute::FileSystemStorage or TextAttribute::TestMemoryStorage on the line after you include TextAttribute."
    end
  end
end
