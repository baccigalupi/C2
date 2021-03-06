class ProposalDecorator < Draper::Decorator
  delegate_all

  def number_approved
    object.individual_steps.approved.count
  end

  def total_approvers
    object.individual_steps.count
  end

  def approvals_by_status
    # Override default scope
    object.individual_steps.with_users.reorder(
      # http://stackoverflow.com/a/6332081/358804
      <<-SQL
        CASE steps.status
        WHEN 'approved' THEN 1
        WHEN 'actionable' THEN 2
        ELSE 3
        END
      SQL
    )
  end

  def approvals_in_list_order
    if object.flow == 'linear'
      object.individual_steps.with_users
    else
      self.approvals_by_status
    end
  end

  def display_status
    if object.pending?
      'pending approval'
    else
      object.status
    end
  end

  def generate_status_message
    if object.steps.non_pending.empty?
      progress_status_message
    else
      completed_status_message
    end
  end

  def completed_status_message
    "All #{number_approved} of #{total_approvers} approvals have been received. Please move forward with the purchase of ##{object.public_id}."
  end

  def progress_status_message
    "#{number_approved} of #{total_approvers} approved."
  end

  def step_text_for_user(key, user)
    step = existing_approval_for(user)
    klass = step.class.name.demodulize.downcase.to_sym
    scope = [:decorators, :steps, klass]
    I18n.t(key, scope: scope)
  end
end
