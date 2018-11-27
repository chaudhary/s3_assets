require "s3_assets/version"

module S3Assets
  class << self
    attr_accessor :dj_priority, :upload_expiration, :max_file_size, :fog_temp_bucket, :aws_access_key_id,
      :aws_secret_access_key, :aws_region, :fog_host, :fog_permanent_bucket
    attr_accessor :cloudfront_host
    attr_accessor :processing_enabled
  end

  class Error < StandardError; end
  # Your code goes here...
end
