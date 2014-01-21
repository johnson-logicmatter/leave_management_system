module LeaveManagementSystem
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        return stylesheet_link_tag(:admin_settings, :plugin => 'leave_management_system')
      end
    end
  end
end