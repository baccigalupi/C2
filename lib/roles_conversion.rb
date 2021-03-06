class RolesConversion
  def ncr_budget_approvers
    ba61_tier1_budget_approver
    ba61_tier2_budget_approver
    ba80_budget_approver
    ool_ba80_budget_approver
  end

  private

  def ba61_tier1_budget_approver
    with_email_role_slug!(
      'communicart.budget.approver+ba61@gmail.com',
      'BA61_tier1_budget_approver',
      'ncr'
    )
  end

  def ba61_tier2_budget_approver
    with_email_role_slug!(
      'communicart.ofm.approver@gmail.com',
      'BA61_tier2_budget_approver',
      'ncr'
    )
  end

  def ba80_budget_approver
    with_email_role_slug!(
      'communicart.budget.approver+ba80@gmail.com',
      'BA80_budget_approver',
      'ncr'
    )
  end

  def ool_ba80_budget_approver
    with_email_role_slug!(
      'communicart.budget.approver+ool_ba80@gmail.com',
      'OOL_BA80_budget_approver',
      'ncr'
    )
  end

  # find_or_create a User with particular email, role and slug
  # NOTE the triple is considered unique, so if a user with the role+slug
  # is found with another email address, no change is made and nil is returned.
  def with_email_role_slug!(email, role, slug)
    # unique triple -- check if any other user with role+slug already exists
    return if exists_with_role_slug?(role, slug)

    user = User.for_email(email)
    # if no change necessary, return early (idempotent)
    if user.client_slug == slug && user.has_role?(role)
      return user
    end

    user.client_slug = slug
    user.add_role(role)
    user.save!
    user
  end

  def exists_with_role_slug?(role, slug)
    the_role = role.is_a?(Role) ? role : Role.find_by_name(role)
    return false unless the_role
    the_role.users.exists?(client_slug: slug)
  end
end
