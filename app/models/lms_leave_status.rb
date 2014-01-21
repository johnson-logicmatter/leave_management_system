class LmsLeaveStatus < ActiveRecord::Base
  unloadable
  
  PENDING = 0
  APPROVED = 1
  PROCESSED = 2
  REJECTED = 3
  CANCELLED = 4
  LEAVE_STATUSES = {PENDING =>  'Pending', APPROVED => 'Approved', PROCESSED => 'Processed', REJECTED => 'Rejected', CANCELLED => 'Cancelled'}
  
  belongs_to :lms_leave
  belongs_to :approver, :class_name => "User", :foreign_key => "approved_by"
  belongs_to :processor, :class_name => "User", :foreign_key => "processed_by"
  belongs_to :rejector, :class_name => "User", :foreign_key => "rejected_by"
  
  validate :deducted_leaves, :on => :update, :if => Proc.new {|ls| ls.status == PROCESSED}
  after_update :split_the_leave, :update_monthly_leave_history, :update_parent_leave_status, :notify
  
  def pending?
    status == PENDING
  end
  
  def approved?
    status == APPROVED
  end

  def processed?
    status == PROCESSED
  end
  
  def rejected?
    status == REJECTED
  end

  def cancelled?
    status == CANCELLED
  end
  
  private
  def deducted_leaves
    leave = self.lms_leave
    if leave.id != leave.parent_leave_id && !LmsLeaveCategory::WORK_FROM_HOME[leave.leave_category_id]
      yearly_settings = LmsYearlySetting.current_year_settings
      active_leave_types = yearly_settings.leave_types
      ded_leaves = self.lop
      ded_leaves += self.ded_carry_forward if yearly_settings.carry_forward
      active_leave_types.each do |lt|
        ded_leaves += self.send "ded_#{lt.identifier}"
      end
      self.errors.add(:base, "Deducted leaves are not matching with applied leaves. Please check the deducted leaves") if ded_leaves != leave.no_of_days
    end
  end
  
  def split_the_leave
    if status_changed? && approved?
      leave = lms_leave
      yr_leav_his = leave.lms_yearly_leave_history
      records = []
      parsed_leave_dates_objects = leave.parse_leave_dates_objects
      parsed_leave_dates_objects.count > 1 && parsed_leave_dates_objects.each do |month, dates|
        records << {
				:user_id => leave.user_id,
	  			:lms_yearly_leave_history_id => yr_leav_his.id, 
	  			:lms_monthly_leave_history_id => yr_leav_his.lms_monthly_leave_histories.find_by_month(month).id, 
	  			:leave_category_id => leave.leave_category_id,
	  			:reported_to => leave.reported_to,
	  			:from_date => dates.first,
	  			:to_date => dates.last,
	  			:leave_dates_object => dates,
	  			:no_of_days => dates.map {|date| date.match(/ :H$/) ? 0.5 : 1}.sum,
	  			:reason => leave.reason,
				:parent_leave_id => leave.id
	  		}
      end
      if records.present?
	leave.update_attribute :parent_leave_id, leave.id
	LmsLeave.create records
      end
    end
  end
  
  def update_monthly_leave_history
    if status_changed? && processed? && lms_leave.id != lms_leave.parent_leave_id
      monthly_leave_history = lms_leave.lms_monthly_leave_history
      if LmsLeaveCategory::WORK_FROM_HOME[lms_leave.leave_category_id]
        data = {:ded_wfh => monthly_leave_history.ded_wfh + ded_wfh}
      else
        active_leave_types = lms_leave.lms_yearly_setting.leave_types
        data = {:ded_carry_forward => monthly_leave_history.ded_carry_forward + ded_carry_forward}
        data[:total_leaves_taken] = monthly_leave_history.total_leaves_taken + ded_carry_forward
        data[:lop] = monthly_leave_history.lop + lop
        active_leave_types.map(&:identifier).each do |lt|
	  lt = "ded_#{lt}"
          data[lt.to_sym] = monthly_leave_history.send(lt) + send(lt)
	  data[:total_leaves_taken] += send(lt)
        end
      end
      monthly_leave_history.update_attributes data
    end
  end
  
  def update_parent_leave_status
    if status_changed? && processed?
      leave = self.lms_leave
      if leave.parent_leave_id.present? && leave.id != leave.parent_leave_id
        parent_leave = leave.parent_leave
	parent_leave.lms_leave_status.update_attributes(:status => PROCESSED, :processed_by => self.processed_by, :processed_on => self.processed_on) if parent_leave.split_leaves.not_processed.count == 0
      end
    end
  end
  
  def notify
    if status_changed? && approved?
       leave = self.lms_leave
       if leave.parent_leave_id.nil? || leave.parent_leave_id == leave.id
         Mailer.approve_leave(leave).deliver
	 Mailer.approve_leave_notification(leave).deliver
	 Mailer.notify_team(leave).deliver if leave.from_date >= Date.today || leave.to_date >= Date.today
       end
    elsif status_changed? && rejected?
      Mailer.reject_leave_notification(self.lms_leave).deliver
    elsif status_changed? && processed?
       leave = self.lms_leave
       if leave.parent_leave_id.nil? || leave.parent_leave_id == leave.id
         Mailer.process_leave_notification(leave).deliver
       end
    end
  end
end
