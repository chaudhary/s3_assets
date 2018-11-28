class ::S3Assets::Uploader < CarrierWave::Uploader::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  UPLOAD_EXPIRATION = 2.hours
  MAX_FILE_SIZE = 20.megabytes

  storage :fog

  process :set_model_content_type

  def original_filename
    name = super
    return URI.decode(name) if name.present?
  end

  def sanitize_regexp
    /[^[:word:]\.\-\+]/
  end

  def fog_public
    true
  end

  def fog_credentials
    {
        :provider => 'AWS',
        :aws_access_key_id => ::S3Assets.aws_access_key_id,
        :aws_secret_access_key => ::S3Assets.aws_secret_access_key,
        :region => ::S3Assets.aws_region,
        :host => ::S3Assets.fog_host,
    }
  end

  def fog_directory
    ::S3Assets.fog_permanent_bucket
  end

  def asset_host
    "https://#{::S3Assets.fog_permanent_bucket}.s3.amazonaws.com"
  end

  def fog_authenticated_url_expiration
    10.hours
  end

  def ignore_integrity_errors
    false
  end

  def ignore_processing_errors
    false
  end

  def ignore_download_errors
    false
  end

  def upload_url
    "https://#{::S3Assets.fog_temp_bucket}.s3.amazonaws.com"
  end

  def fog_attributes
    # cached for 1 year
    {'Cache-Control' => "public, max-age=#{60*60*24*365}"}
  end

  def store_dir
    return "prod/#{model.id.to_s}" if Rails.env.production?
    return "dev/#{model.id.to_s}"
  end

  def temp_store_dir
    return "prod/#{model.id.to_s}" if Rails.env.production?
    return "dev/#{model.id.to_s}"
  end

  # override the url to return absolute url if available and
  # revert back to standard functionality if it is not available
  def url
    if model.processable?
      model.absolute_url
    else
      super
    end
  end

  def acl
    'public-read'
  end

  def policy_doc(options={})
    options[:expiration] ||= UPLOAD_EXPIRATION
    options[:max_file_size] ||= MAX_FILE_SIZE
    success_action_status = options[:success_action_status]
    store_dir = self.temp_store_dir

    doc = {
        'expiration' => Time.now.utc + options[:expiration],
        'conditions' => [
            ["starts-with", "$key", store_dir],
            {"bucket" => ::S3Assets.fog_temp_bucket},
            {"acl" => acl},
            ["content-length-range", 1, options[:max_file_size]]
        ]
    }
    doc['conditions'] << {"success_action_status" => success_action_status.to_s} unless success_action_status.blank?
    doc['conditions'] << ["starts-with", "$Content-type", ""]
    doc
  end

  def policy(options={})
    Base64.encode64(policy_doc(options).to_json).gsub("\n", "")
  end

  def signature policy=nil
    policy = self.policy unless policy
    Base64.encode64(
        OpenSSL::HMAC.digest(
            OpenSSL::Digest.new('sha1'),
            AWS_SECRET_ACCESS_KEY, policy
        )
    ).gsub("\n", "")
  end

  def set_model_content_type
    return if file.blank?

    type = File.magic_number_type(file.path.to_s) rescue nil
    content_types = MIME::Types.type_for(type.to_s)

    type = File.extname(file.path)
    content_types |= MIME::Types.type_for(type.to_s)

    model.content_type = content_types.first.to_s
  end

  protected
  def image?(new_file)
    model.content_type.nil? ? false : model.content_type.include?('image')
  end

end
