module ProjectsHelper
  def discussion_context_tag(field_name, format = :html)
    Differ.format = format
    changed_context = @discussions.of_field(field_name).first
    if changed_context
      Differ.diff_by_char(changed_context.context, @project.send(field_name)||'').to_s.html_safe
    else
      @project.send(field_name)
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
end
