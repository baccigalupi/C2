class ProposalsController < ApplicationController
  include TokenAuth

  before_filter :authenticate_user!, except: :approve
  before_filter ->{authorize self.proposal}, only: [:show, :cancel]
  before_filter :needs_token_on_get, only: :approve
  before_filter :validate_access, only: :approve
  helper_method :display_status
  add_template_helper ProposalsHelper
  rescue_from Pundit::NotAuthorizedError, with: :auth_errors

  def show
    @proposal = self.proposal.decorate
    @show_comments = true
    @include_comments_files = true
  end

  def index
    @proposals = self.chronological_proposals
    @CLOSED_PROPOSAL_LIMIT = 10
  end

  def archive
    @proposals = self.chronological_proposals.closed
  end

  def cancel_form
    @proposal = self.proposal.decorate

    if @proposal.cancelled?
     redirect_to proposal_path, id:@proposal.id, alert: "This request has already been cancelled."
    end

  end

  def cancel
    if params[:reason_input].present?
      proposal = Proposal.find params[:id]
      comments = "Request cancelled with comments: " + params[:reason_input]
      proposal.cancel!
      proposal.comments.create!(comment_text: comments, user_id: current_user.id)

      flash[:success] = "Your request has been cancelled"
      redirect_to proposal_path, id: proposal.id
      Dispatcher.new.deliver_cancellation_emails(proposal)
    else
      redirect_to cancel_form_proposal_path, id: params[:id],
                                             alert: "A reason for cancellation is required.
                                                     Please indicate why this request needs
                                                     to be cancelled."
    end
  end

  def approve
    approval = self.proposal.approval_for(current_user)
    if approval.user.delegates_to?(current_user)
      # assign them to the approval
      approval.update_attributes!(user: current_user)
    end

    if approval.proposal.cancelled?
      flash[:error] = "You are unable to approve this request because it has been cancelled."
      return redirect_to proposal
    end

    approval.approve!
    flash[:success] = "You have approved #{proposal.public_identifier}."
    redirect_to proposal
  end

  # @todo - this is acting more like an index; rename existing #index to #mine
  # or similar, then rename #query to #index
  def query
    @proposals = self.proposals
    @start_date = self.param_date(:start_date)
    @end_date = self.param_date(:end_date)
    @text = params[:text]

    if @start_date
      @proposals = @proposals.where('created_at >= ?', @start_date)
    end
    if @end_date
      @proposals = @proposals.where('created_at < ?', @end_date)
    end
    if @text
      @proposals = ProposalSearch.new(@proposals).execute(@text)
    else
      @proposals = @proposals.order('created_at DESC')
    end
    # TODO limit/paginate results
  end

  protected

  def proposal
    @cached_proposal ||= Proposal.find params[:id]
  end

  def proposals
    policy_scope(Proposal)
  end

  def chronological_proposals
    self.proposals.order('created_at DESC')
  end

  def auth_errors(exception)
    redirect_to proposals_path, :alert => "Your do not have permissions or this request has already been cancelled."
  end
end
