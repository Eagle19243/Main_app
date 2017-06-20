module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def common_fulltext_search(fields, free_text, limit)
      if fields.blank?
        none
      else
        query = fields.map { |f| "#{f} ILIKE ?" }.join(' OR ')
        params = Array.new(fields.length, "%#{free_text}%")
        where(query, *params).limit(limit)
      end
    end
  end
end
