# frozen_string_literal: true

class Admin::Ics::Absence
  include Admin::Ics

  def self.create_payload(absence)
    payload(absence).merge(action: :create)
  end

  def self.update_payload(absence)
    payload(absence).merge(action: :update)
  end

  def self.destroy_payload(absence)
    payload(absence).merge(action: :destroy)
  end

  def self.payload(absence)
    {
      name: "absence-#{absence.title.parameterize}-#{absence.starts_at.to_s.parameterize}.ics",
      agent_email: absence.agent.email,
      starts_at: absence.starts_at,
      recurrence: rrule(absence),
      ical_uid: absence.ical_uid,
      title: absence.title,
      first_occurrence_ends_at: absence.first_occurrence_ends_at
    }
  end

  def self.to_ical(payload)
    cal = Icalendar::Calendar.new

    tz = TZInfo::Timezone.get Admin::Ics::TZID
    timezone = tz.ical_timezone payload[:starts_at]
    cal.add_timezone timezone
    cal.prodid = BRAND
    cal.event { populate_event(_1, payload) }
    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def self.populate_event(event, payload)
    event.uid = payload[:ical_uid]
    event.dtstart = Icalendar::Values::DateTime.new(payload[:starts_at], "tzid" => TZID)
    event.dtend = Icalendar::Values::DateTime.new(payload[:first_occurrence_ends_at], "tzid" => TZID)
    event.summary = "#{BRAND} #{payload[:title]}"
    event.location = payload[:address]
    event.ip_class = "PUBLIC"
    event.rrule = payload[:recurrence]
    event.status = Admin::Ics.status_from_action(payload[:action])
    event.attendee = "mailto:#{payload[:agent_email]}"
    event.organizer = "mailto:secretariat-auto@rdv-solidarites.fr"
  end

  def self.rrule(absence)
    return if absence.recurrence.blank?

    recurrence_hash = absence.recurrence.to_hash

    case recurrence_hash[:every]
    when :week
      freq = "FREQ=WEEKLY;"
      by_day = "BYDAY=#{by_week_day(recurrence_hash[:on])};" if recurrence_hash[:on]
    when :month
      freq = "FREQ=MONTHLY;"
      by_day = "BYDAY=#{by_month_day(recurrence_hash[:day])};" if recurrence_hash[:day]
    end

    interval = interval_from_hash(recurrence_hash)

    until_date = until_from_hash(recurrence_hash)

    "#{freq}#{interval}#{by_day}#{until_date}"
  end

  def self.by_month_day(day)
    "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
  end

  def self.interval_from_hash(recurrence_hash)
    "INTERVAL=#{recurrence_hash[:interval]};" if recurrence_hash[:interval]
  end

  def self.until_from_hash(recurrence_hash)
    "UNTIL=#{Icalendar::Values::DateTime.new(recurrence_hash[:until], 'tzid' => TZID).value_ical};" if recurrence_hash[:until]
  end

  def self.by_week_day(on)
    if on.is_a?(String)
      on[0, 2].upcase
    else
      on.map { |d| d[0, 2].upcase }.join(",")
    end
  end
end