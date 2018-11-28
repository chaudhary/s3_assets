module S3Assets::Utility
  extend self

  def json(doc, default_asset_path: nil, processing: nil)
    file_url = url(doc, default_asset_path: default_asset_path, processing: processing)
    return if file_url.blank?

    if doc.present? && doc.processed?
      filepath = doc.asset.path
      content_type = doc.content_type
    end
    {
      id: doc.try(:_id),
      url: file_url,
      filepath: filepath,
      content_type: content_type,
      name: doc.try(:original_filename)
    }
  end

  def url(doc, default_asset_path: nil, processing: nil)
    if doc.blank?
      if default_asset_path.present?
        return ActionController::Base.helpers.asset_path(default_asset_path)
      end
      return
    end
    return "https://#{::S3Assets.cloudfront_host}/#{doc.asset.path}" unless ::S3Assets.processing_enabled
    return doc.asset.url if !(doc.processed?)

    raw_url = "https://#{::S3Assets.cloudfront_host}/raw/#{doc.asset.path}"
    return raw_url if !(doc.image?)
    return raw_url if doc.content_type.include?("gif") && !(processing)

    processing ||= {}
    processing[:size] ||= "1500x1500"
    processing[:type] ||= "cover"
    processing_str = "/size:#{processing[:size]}"
    processing_str += "/extend:#{processing[:extend]}" if processing[:extend].present?
    processing_str += "/blur:#{processing[:blur].to_i}" if processing[:blur].present?
    processing_str += "/type:#{processing[:type]}"


    return "https://#{::S3Assets.cloudfront_host}/images#{processing_str}/#{doc.asset.path}"
  end

  def download(url)
    temp_doc = ::S3Assets::Model.new
    temp_doc.asset.download!(url)
    return temp_doc.asset.file.file
  end

  def create!(filepath, parent: nil)
    doc = nil
    File.open(filepath) do |file|
      doc = ::S3Assets::Model.new(parent: parent)
      doc.asset = file
      doc.save!
    end
    return doc
  end

end
