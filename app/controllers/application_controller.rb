class ApplicationController < ActionController::API
  include Pagy::Backend

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found(exception)
    render json: { error: "#{exception.model} not found" }, status: :not_found
  end

  def pagy_output(pagy)
    {
      page: pagy.page,
      per_page: pagy.limit,
      count: pagy.count,
      pages: pagy.pages,
    }.compact
  end
end
