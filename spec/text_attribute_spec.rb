# encoding: UTF-8
require 'spec_helper'

describe TextAttribute do
  class TestModel
    include TextAttribute

    text_attribute :foo

    attr_accessor :id
  end

  describe "text_cache_path" do
    it "should use the classname and id" do
      model = TestModel.new
      model.text_cache_path.should =~ /text_cache/
    end

    it "should generate consistent hashes for objects with the same ids" do
      model1 = TestModel.new
      model1.id = 2
      model2 = TestModel.new
      model2.id = 2
      model1.text_cache_path.should == model2.text_cache_path

      model2.id = 3
      model1.text_cache_path.should_not == model2.text_cache_path
    end
  end

  describe "reader" do
    it "should try to read from disk if id is defined" do
      model = TestModel.new
      model.id = 1
      mock(model).read_text_file(:foo) { "hi" }
      model.foo.should == "hi"
    end

    it "should not try to read from disk if id is not defined" do
      model = TestModel.new
      model.id = nil
      do_not_allow(model).text_cache_path
      do_not_allow(model).read_text_file
      model.foo.should be_nil
    end

    it "should not try to read from disk a second time" do
      model = TestModel.new
      model.id = 1
      mock(model).read_text_file(:foo) { "hi" }.once
      model.foo.should == "hi"
      model.foo.should == "hi"
      model.foo.should == "hi"
    end

    it "should not try to read from disk a second time, even when it gets false" do
      model = TestModel.new
      model.id = 1
      mock(model).read_text_file(:foo) { false }.once
      model.foo.should be_nil
      model.foo.should be_nil
      model.foo.should be_nil
      model.foo.should be_nil
    end

    it "should not try to read from disk a second time, even after saving" do
      model = TestModel.new
      model.id = 1
      mock(model).read_text_file(:foo) { false }.once
      model.foo.should be_nil
      model.foo = "hi!"
      model.foo.should == "hi!"
      model.foo_changed?.should be_true
      model.store_foo
      model.foo.should == "hi!"
      model.foo_changed?.should be_false
    end
  end

  describe "setter" do
    it "should set the value in memory and show as changed" do
      model = TestModel.new
      model.foo.should be_nil
      model.foo_changed?.should be_false
      model.foo = "hello world!"
      model.foo.should == "hello world!"
      model.foo_changed?.should be_true
    end

    it "should store to disk when store_<attribute name> is called" do
      model = TestModel.new
      model.foo = "hello world!"
      mock(model).write_text_file(:foo, "hello world!")
      model.store_foo
    end
  end

  describe "<attribute name>_exists?" do
    it "should check for file existence without loading data" do
      model = TestModel.new
      do_not_allow(model).read_text_file(:foo)
      mock(model).text_file_exists?(:foo) { true }
      model.foo_exists?.should be_true
    end

    it "should defer to member of the data is loaded" do
      model = TestModel.new
      model.foo = "hello world!"
      do_not_allow(model).text_file_exists?
      do_not_allow(model).read_text_file(:foo)
      model.foo_exists?.should be_true
    end
  end

  describe "<attribute name>_path" do
    it "should return a path" do
      model = TestModel.new
      model.id = 5
      model.foo = "hello world!"
      model.foo_path.should =~ /text_cache\/...\/...\/...\/TextModel_5\/foo/
    end
  end

  describe "remove_<attribute name>" do
    it "should remove the attribute data" do
      model = TestModel.new
      model.id = 5
      model.foo = "hello world!"
      model.store_foo

      model2 = TestModel.new
      model2.id = 5
      model2.foo.should == "hello world!"
      model2.remove_foo

      model3 = TestModel.new
      model3.id = 5
      model3.foo.should be_nil
    end
  end

  describe "<attribute name>_changed?" do
    it "should be true when the value has changed" do
      model = TestModel.new
      model.id = 5
      model.foo_changed?.should be_false
      model.foo = "hi"
      model.foo_changed?.should be_true
      model.store_foo # called on saves
      model.foo.should == "hi"
      model.foo_changed?.should be_false
      model.foo = "hi"
      model.foo_changed?.should be_false
      model.foo = "hi2"
      model.foo_changed?.should be_true

      model2 = TestModel.new
      model2.id = 5
      model2.foo.should == "hi"
      model2.foo_changed?.should be_false
      model2.foo = "hi2"
      model2.foo_changed?.should be_true
      model2.store_foo
      model2.foo.should == "hi2"
      model2.foo_changed?.should be_false
    end
  end

  describe "in memory storage for testing" do
    before do
      do_not_allow(File).open
    end

    describe "clearing between tests" do
      it "test one" do
        model1 = TestModel.new
        model1.id = 5
        model1.foo = "hello"
        model1.store_foo

        model2 = TestModel.new
        model2.id = 5
        model2.foo.should == "hello"
      end

      it "test two" do
        model2 = TestModel.new
        model2.id = 5
        model2.foo.should be_nil
      end
    end

    describe "compression" do
      context "when turned on" do
        class CompressedTestModel < TestModel
        #  include TextAttributes::CompressedStorage
        end

        it "should be gzip compressed" do
          model = CompressedTestModel.new
          model.id = 5
          model.foo = "This is a string."
          model.store_foo
          $text_memory_store[File.join(model.text_cache_path, "foo")].should_not == "This is a string."
          result = Zlib::Inflate.inflate($text_memory_store[File.join(model.text_cache_path, "foo")].partition("|").last)
          result.should == "This is a string."
        end

        it "should handle encoding okay" do
          model = CompressedTestModel.new
          model.id = 5
          model.foo = "This is a string.".encode("UTF-8")
          model.store_foo

          model2 = CompressedTestModel.new
          model2.id = 5
          model2.foo.should == "This is a string."
          model2.foo.encoding.to_s.should == "UTF-8"
        end
      end
    end
  end
end