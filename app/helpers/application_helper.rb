module ApplicationHelper
  def show_flash
    [:notice, :error, :warning].collect do |key|
      content_tag(:div, flash[key], :id => key, :class => "flash") unless flash[key].blank?
    end.join.html_safe
  end
end
