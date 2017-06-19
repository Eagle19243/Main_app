module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def common_fulltext_search(free_text, limit, aditional = [])
      aditional = [aditional] unless aditional.is_a? Array
      fields = (%i(title description short_description) + aditional).uniq
      query = fields.map { |f| "#{f} ILIKE ?" }.join(' OR ')
      params = Array.new(fields.length, "%#{free_text}%")
      where(query, *params).limit(limit)
    end
  end
end
