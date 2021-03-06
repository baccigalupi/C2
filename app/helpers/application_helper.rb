module ApplicationHelper
  def controller_name
    params[:controller].gsub(/\W/, '-')
  end

  def display_return_to_proposal
    controller.is_a?(ProposalsController) && params[:action] == 'history'
  end

  def display_return_to_proposals
    controller.is_a?(UseCaseController) ||
      (controller.is_a?(ProposalsController) && params[:action] != 'index')
  end

  def auth_path
    '/auth/myusa'
  end
end
