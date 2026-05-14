class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_server_error

  private

  def not_found(exception = nil)
    Rails.logger.error("NOT_FOUND: #{exception.class} - #{exception.message}") if exception
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    Rails.logger.error("INTERNAL_SERVER_ERROR: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    
    # For RecordNotFound, it should have been caught by the rescue_from above
    # If we get here, something is wrong with the exception handling
    if exception.is_a?(ActiveRecord::RecordNotFound)
      render json: { error: 'Resource not found' }, status: :not_found
    else
      render json: { 
        error: 'Internal server error' 
      }, status: :internal_server_error
    end
  end
end