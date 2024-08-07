class ApplicationController < ActionController::API
  include Pagy::Backend

  private

  def pagy_output(pagy)
    {
      page: pagy.page,
      per_page: pagy.limit,
      count: pagy.count,
      pages: pagy.pages,
    }.compact
  end
end
