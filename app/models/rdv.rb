class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  belongs_to :user

  validates :user, :organisation, :motif, :start_at, :duration_in_min, presence: true

  after_commit :reload_uuid, on: :create

  after_create :send_ics_to_participants
  after_update :update_ics_to_participants, if: -> { saved_change_to_start_at? || saved_change_to_cancelled_at? }

  def end_at
    start_at + duration_in_min.minutes
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancel!
    update(cancelled_at: Time.zone.now)
  end

  def send_ics_to_participants
    RdvMailer.send_ics_to_user(self).deliver_later
  end

  def update_ics_to_participants
    increment!(:sequence)
    RdvMailer.send_ics_to_user(self).deliver_later
  end

  def to_ical
    require 'icalendar'

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = start_at
      e.dtend       = end_at
      e.summary     = "RDV #{name}"
      e.description = ""
      e.uid         = uuid
      e.sequence    = sequence
      e.status      = "CANCELLED" if cancelled?
    end

    cal.to_ical
  end

  def ics_name
    "rdv-#{name.parameterize}-#{start_at.to_s.parameterize}.ics"
  end

  def to_step_params
    {
      organisation: organisation,
      motif: motif,
      duration_in_min: duration_in_min,
      start_at: start_at,
      user: user,
    }
  end

  private

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
