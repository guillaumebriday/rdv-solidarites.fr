module User::ImprovedUnicityErrorConcern
  extend ActiveSupport::Concern

  included do
    after_validation do
      email_taken_error = errors.details[:email]&.select { _1[:error] == :taken }&.first
      next unless email_taken_error.present?

      email_taken_error["id"] = User.where.not(id: id).where(email: email).first.id
    end
  end
end