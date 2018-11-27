module ::S3Assets::Relations
  extend ActiveSupport::Concern

  module Helpers
    def self.proper_asset_id(asset_id, parent)
      return if asset_id.blank?
      return asset_id if BSON::ObjectId.legal?(asset_id)

      asset_id = "http:#{asset_id}" if asset_id.starts_with?("//")

      if asset_id.starts_with?("http")
        return ::S3Assets::Model.create!(absolute_url: asset_id, uploader: RequestStore.store[:current_user],
          ip_address: RequestStore.store[:ip_address], parent: parent).id
      else
        return ::S3Assets::Utility.create!(asset_id, parent: parent).id
      end
    end
  end

  module ClassMethods
    def asset_belongs_to(relation_name, options = {})
      options[:class_name] = ::S3Assets::Model.to_s
      related_doc_klass = options[:class_name].constantize
      field_name = "#{relation_name}_id".to_sym

      self.instance_eval do
        self.belongs_to(relation_name, options)

        self.send(:define_method, "#{field_name}=".to_sym) do |asset_id|
          asset_id = ::S3Assets::Relations::Helpers.proper_asset_id(asset_id, self)
          super(asset_id)
        end

        after_save do |doc|
          if doc.send("#{field_name}_changed?")
            old_related_doc_id = doc.send("#{field_name}_was")
            if old_related_doc_id.present? && old_related_doc_id.to_s != doc.send(field_name).to_s
              related_doc_klass.where(:_id => old_related_doc_id).destroy_all
            end
          end
        end

        after_destroy do |doc|
          related_doc_id = doc.send(field_name)
          related_doc_klass.where(:_id => related_doc_id).destroy_all if related_doc_id.present?
        end
      end
    end

    def asset_has_and_belongs_to_many(relation_name, options = {})
      options[:class_name] = ::S3Assets::Model.to_s
      related_doc_klass = options[:class_name].constantize
      field_name = "#{relation_name.to_s.singularize}_ids".to_sym

      self.instance_eval do
        self.has_and_belongs_to_many(relation_name, options)

        self.send(:define_method, "#{field_name}=".to_sym) do |asset_ids|
          if asset_ids.present?
            asset_ids = asset_ids.reject(&:blank?).map do |asset_id|
              ::S3Assets::Relations::Helpers.proper_asset_id(asset_id, self)
            end
          end
          super(asset_ids)
        end

        after_save do |doc|
          if doc.send("#{field_name}_changed?")
            old_related_doc_ids = [doc.send("#{field_name}_was")].flatten.compact.map(&:to_s)
            new_related_doc_ids = [doc.send(field_name)].flatten.compact.map(&:to_s)
            removed_ids = old_related_doc_ids - new_related_doc_ids
            related_doc_klass.where(:_id.in => removed_ids).destroy_all if removed_ids.present?
          end
        end

        after_destroy do |doc|
          related_doc_ids = doc.send(field_name)
          related_doc_klass.where(:_id.in => related_doc_ids).destroy_all if related_doc_ids.present?
        end
      end
    end

  end
end
