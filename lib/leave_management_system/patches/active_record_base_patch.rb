module LeaveManagementSystem
  module Patches
    module BasePatch
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end
      
      module ClassMethods
        def column_names_excluding_id
          columns = self.column_names.dup
          columns.delete("id")
          return columns
        end
        
        def select_column_names_excluding_id
          columns = self.column_names_excluding_id
          return columns.map {|c| "#{self.table_name}."<< c}.join(', ')
        end
      end
    end
  end
end

unless ActiveRecord::Base.included_modules.include?(LeaveManagementSystem::Patches::BasePatch)
  ActiveRecord::Base.send :include, LeaveManagementSystem::Patches::BasePatch
end