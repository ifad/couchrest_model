require 'spec_helper'

describe "Model attachments" do
  
  describe "#has_attachment?" do
    before(:each) do
      reset_test_db!
      @obj = Basic.new
      @obj.save.should be_true
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
    end
  
    it 'should return false if there is no attachment' do
      @obj.has_attachment?('bogus').should be_false
    end
  
    it 'should return true if there is an attachment' do
      @obj.has_attachment?(@attachment_name).should be_true
    end
  
    it 'should return true if an object with an attachment is reloaded' do
      @obj.save.should be_true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj.has_attachment?(@attachment_name).should be_true
    end
  
    it 'should return false if an attachment has been removed' do
      @obj.delete_attachment(@attachment_name)
      @obj.has_attachment?(@attachment_name).should be_false
    end
    
    it 'should return false if an attachment has been removed and reloaded' do
      @obj.delete_attachment(@attachment_name)
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj.has_attachment?(@attachment_name).should be_false
    end
    
  end

  describe "creating an attachment" do
    before(:each) do
      @obj = Basic.new
      @obj.save.should be_true
      @file_ext = File.open(FIXTURE_PATH + '/attachments/test.html')
      @file_no_ext = File.open(FIXTURE_PATH + '/attachments/README')
      @attachment_name = 'my_attachment'
      @content_type = 'media/mp3'
    end
  
    it "should create an attachment from file with an extension" do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name)
      @obj.save.should be_true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj.attachments[@attachment_name].should_not be_nil
    end
  
    it "should create an attachment from file without an extension" do
      @obj.create_attachment(:file => @file_no_ext, :name => @attachment_name)
      @obj.save.should be_true
      reloaded_obj = Basic.get(@obj.id)
      reloaded_obj.attachments[@attachment_name].should_not be_nil
    end
  
    it 'should raise ArgumentError if :file is missing' do
      lambda{ @obj.create_attachment(:name => @attachment_name) }.should raise_error
    end
  
    it 'should raise ArgumentError if :name is missing' do
      lambda{ @obj.create_attachment(:file => @file_ext) }.should raise_error
    end
  
    it 'should set the content-type if passed' do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name, :content_type => @content_type)
      @obj.attachments[@attachment_name]['content_type'].should == @content_type
    end

    it "should detect the content-type automatically" do
      @obj.create_attachment(:file => File.open(FIXTURE_PATH + '/attachments/couchdb.png'), :name => "couchdb.png")
      @obj.attachments['couchdb.png']['content_type'].should == "image/png" 
    end

    it "should use name to detect the content-type automatically if no file" do
      file = File.open(FIXTURE_PATH + '/attachments/couchdb.png')
      file.stub!(:path).and_return("badfilname")
      @obj.create_attachment(:file => File.open(FIXTURE_PATH + '/attachments/couchdb.png'), :name => "couchdb.png")
      @obj.attachments['couchdb.png']['content_type'].should == "image/png" 
    end

  end

  describe 'reading, updating, and deleting an attachment' do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      @obj.save.should be_true
      @file.rewind
      @content_type = 'media/mp3'
    end
  
    it 'should read an attachment that exists' do
      @obj.read_attachment(@attachment_name).should == @file.read
    end
  
    it 'should update an attachment that exists' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      @file.should_not == file
      @obj.update_attachment(:file => file, :name => @attachment_name)
      @obj.save
      reloaded_obj = Basic.get(@obj.id)
      file.rewind
      reloaded_obj.read_attachment(@attachment_name).should_not == @file.read
      reloaded_obj.read_attachment(@attachment_name).should == file.read
    end
  
    it 'should set the content-type if passed' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      @file.should_not == file
      @obj.update_attachment(:file => file, :name => @attachment_name, :content_type => @content_type)
      @obj.attachments[@attachment_name]['content_type'].should == @content_type
    end
  
    it 'should delete an attachment that exists' do
      @obj.delete_attachment(@attachment_name)
      @obj.save
      lambda{Basic.get(@obj.id).read_attachment(@attachment_name)}.should raise_error
    end
  end

  describe "#attachment_url" do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      @obj.save.should be_true
    end
  
    it 'should return nil if attachment does not exist' do
      @obj.attachment_url('bogus').should be_nil
    end
  
    it 'should return the attachment URL as specified by CouchDB HttpDocumentApi' do
      @obj.attachment_url(@attachment_name).should == "#{Basic.database}/#{@obj.id}/#{@attachment_name}"
    end
    
    it 'should return the attachment URI' do
      @obj.attachment_uri(@attachment_name).should == "#{Basic.database.uri}/#{@obj.id}/#{@attachment_name}"
    end
  end

  describe "#attachments" do
    it 'should return an empty Hash when document does not have any attachment' do
      new_obj = Basic.new
      new_obj.save.should be_true
      new_obj.attachments.should == {}
    end

    it 'should not re-encode already saved attachments' do
      i = Basic.create(:title => "A buggy model")

      i.create_attachment(:name => "ch1", :file => StringIO.new("First Chapter"), :content_type => "text/plain")
      i.save!
      i.read_attachment("ch1").should == "First Chapter"

      i.create_attachment(:name => "ch2", :file => StringIO.new("Second Chapter"), :content_type => "text/plain")
      i.save!
      i.read_attachment("ch1").should == "First Chapter"
      i.read_attachment("ch2").should == "Second Chapter"

      i.create_attachment(:name => "ch3", :file => StringIO.new("Third Chapter"), :content_type => "text/plain")
      i.save!
      i.read_attachment("ch1").should == "First Chapter"
      i.read_attachment("ch2").should == "Second Chapter"
      i.read_attachment("ch3").should == "Third Chapter"
    end

    context 'on an object' do
      before(:each) do
        @obj = Basic.new
        @file = File.open(FIXTURE_PATH + '/attachments/test.html')
        @attachment_name = 'my_attachment'
        @obj.create_attachment(:file => @file, :name => @attachment_name)
        @file.rewind
        @obj.save.should be_true
      end

      context 'newly saved' do
        it 'should return a Hash with all attachments without data' do
          @obj.attachments.should == { @attachment_name =>{ "stub" => true, "content_type" => "text/html"} }
        end
      end

      context 'already persisted' do
        before(:each) do
          @obj = Basic.find(@obj.id)
        end

        it 'should return an Hash without data and with a digest' do
          attach = @obj.attachments.fetch(@attachment_name)

          attach['stub'].should == true
          attach['length'].should == 121
          attach['content_type'].should == 'text/html'
          attach['digest'].should == 'md5-eJGYWSlZJkRAupndVYf+dg=='
        end
      end
    end
  
  end
end
