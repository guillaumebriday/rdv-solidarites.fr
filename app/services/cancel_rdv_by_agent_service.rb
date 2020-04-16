class CancelRdvByAgentService
  attr_reader :rdv

  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    @rdv.update(status: :excused, cancelled_at: Time.now)
    @rdv.users.map(&:user_to_notify).uniq.each do |user|
      RdvMailer.cancellation(@rdv, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_cancelled, @rdv, user) if user.formated_phone
    end
  end
end
