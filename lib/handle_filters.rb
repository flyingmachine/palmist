module HandleFilters
  def conditions_from_filters(filters, *exclude)
    condition_text = ["site = ?"]
    condition_values = [$current_palmist_site["name"]]
    
    filters.each do |filter_name, value|
      next if exclude.include?(filter_name.to_s) || value.nil? || value.blank?
      condition_text << "#{filter_name.to_s.sub('_id', 's.id')} = ?"
      condition_values << value
    end
    
    unless condition_text.empty?
      conditions = [condition_text.join(" AND ")] + condition_values 
    else
      conditions = "TRUE"
    end
    conditions
  end
end

class <<ActiveRecord::Base
  include HandleFilters
end