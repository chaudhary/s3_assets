class ::S3Assets::Model
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  mount_uploader :asset, ::S3Assets::Uploader, mount_on: :asset_filename

  field :content_type, type: String
  field :absolute_url, type: String, default: nil

  belongs_to :uploader, class_name: 'User'
  field :ip_address, type: String
  field :parent, type: ShallowDocument
  field :temp, type: Boolean

  after_save do |doc|
    doc.delay(priority: ::S3Assets.dj_priority).fetch_and_store_from_url! if doc.processable?
  end

  scope :images, ->{where(content_type: /image/i)}

  def image?
    self.content_type.to_s.downcase.include? "image" unless self.content_type.nil?
  end

  def download
    ::S3Assets::Utility.download(self.asset.url)
  end

  def original_filename
    return nil if filename.blank?
    URI.unescape(filename)
  end

  def processable?
    self.absolute_url.present? && self.asset.blank?
  end

  def processed?
    !(processable?)
  end

  def filename
    return nil if self.asset.url.blank?
    file_name = self.asset.url.split("?").first
    file_name = file_name.split("/").last
    file_name
  end

  def dj_priority
  end

  def self.from_s3_params(bucket, key)
    return nil if bucket.blank? || key.blank?

    key = URI.encode(key, "!@#$%^&*()+=[]{} ")
    url = "https://s3.amazonaws.com/#{bucket}/#{key}"
    self.new(absolute_url: url)
  end

  def fetch_and_store_from_url!
    return unless self.processable?

    begin
      self.remote_asset_url = self.absolute_url
      self.save!
    rescue CarrierWave::DownloadError => ex
      if ex.message.include?("Invalid Location URI")
        # "http://www.hiretale.com/files/resize_logo/13126logo original.png"
        # is not working without doing this due to redirect URL not encoded properly
        page = Mechanize.new.head(self.absolute_url)
        self.remote_asset_url = page.uri.to_s
        self.save!
      else
        raise ex
      end
    end
  end
end
