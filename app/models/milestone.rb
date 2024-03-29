class Milestone < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :dependent => :nullify

  def percent_complete
    p = 0.0

    complete = self.completed_tasks * 1.0
    total =  self.total_tasks * 1.0
    return 0.0 if total == 0
    p = (complete / total) * 100.0
  end

  def complete?
    (self.completed_tasks == self.total_tasks) || (!self.completed_at.nil?)
  end

  def to_tip(options = { })
    res = "<table cellpadding=0 cellspacing=0>"
    res << "<tr><th>#{_('Name')}</th><td> #{self.name}</td></tr>"
    res << "<tr><th>#{_('Due Date')}</th><td> #{options[:user].tz.utc_to_local(due_at).strftime_localized("%A, %d %B %Y")}</td></tr>" unless self.due_at.nil?
    res << "<tr><th>#{_('Owner')}</th><td> #{self.user.name}</td></tr>" unless self.user.nil?
    res << "<tr><th>#{_('Progress')}</th><td> #{self.completed_tasks.to_i} / #{self.total_tasks.to_i} #{_('Complete')}</td></tr>"
    res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description.gsub(/\n/, '</td></tr>').gsub(/\"/,'&quot;')}</td></tr>" if( self.description && self.description.strip.length > 0)
    res << "</table>"
    res.gsub(/\"/,'&quot;')
  end

  def due_date
    unless @due_date
      if due_at.nil?
        last = self.tasks.collect{ |t| t.due_at.to_time.to_f if t.due_at }.compact.sort.last
        @due_date = Time.at(last).to_datetime if last
      else
        @due_date = due_at
      end
    end
    @due_date
  end

  def scheduled_date
    (self.scheduled? ? self.scheduled_at : self.due_at)
  end 
  
  def worked_minutes
    if @minutes.nil?
      @minutes = WorkLog.sum('work_logs.duration', :joins => "INNER JOIN tasks ON tasks.milestone_id = #{self.id}", :conditions => ["work_logs.task_id = tasks.id AND tasks.completed_at IS NULL"] ) || 0
      @minutes /= 60
    end 
    @minutes
  end

  def duration
    if @duration.nil?
      @duration = Task.sum(:duration, :conditions => ["tasks.milestone_id = ? AND tasks.completed_at IS NULL AND tasks.scheduled = 0", self.id]) || 0
      @duration += Task.sum(:scheduled_duration, :conditions => ["tasks.milestone_id = ? AND tasks.completed_at IS NULL AND tasks.scheduled = 1", self.id]) || 0
    end 
    @duration
  end

end
