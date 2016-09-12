module ProjectsHelper
  def config_project
    @project.tap do |p|
      p.section_details.build(title: 'First Section Details') if current_user.is_admin_for?(@project) && p.section_details.blank?
    end
  end

  def discussion_context_tag(section_detail, field_name, format = :html)
    Differ.format = format
    changed_context = section_detail.discussions.of_field(field_name).first
    if changed_context
      Differ.diff_by_char(changed_context.context, section_detail.send(field_name).to_s).to_s.html_safe
    else
      section_detail.send(field_name).to_s.html_safe
    end
  end

  def discussion_change_tag(context1, context2)
    Differ.format = Differ::Format::Custom
    html = ""
    Differ.diff_by_char(context1, context2).send(:raw_array).each do |item|
      html << item.to_s.html_safe if item.is_a?(Differ::Change) && (item.insert? || item.delete?)
    end
    html.html_safe
  end

  def section_details_content_tag(parent = nil)
    content_tag :ul do
      html_ul = ActiveSupport::SafeBuffer.new
      SectionDetail.completed.of_parent(parent).ordered.each do |child|
        html_ul << content_tag(:li) do
          html_li = link_to(child.title, "#section-detail-#{child.id}")
          html_li << section_details_content_tag(child) if child.childs.exists?
          html_li
        end
      end
      html_ul
    end

  end
end
