module ApplicationHelper
        def truncate_trailing_zero decimal
	  decimal == decimal.floor ? decimal.floor : decimal
	end
end