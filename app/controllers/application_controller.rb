class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_server_error

  private

  def not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))
    
    render json: { 
      error: 'Internal server error' 
    }, status: :internal_server_error
  end
end