# frozen_string_literal: true

class User::RdvPolicy < ApplicationPolicy
  alias current_user pundit_user

  def rdv_belongs_to_user_or_relatives?
    (record.user_ids & current_user.available_users_for_rdv.pluck(:id)).any?
  end

  def index?
    !current_user.only_invited?
  end

  def new?
    return false if record.revoked?

    (record.collectif? && record.reservable_online?) || rdv_belongs_to_user_or_relatives?
  end

  def create?
    return false if record.collectif?

    rdv_belongs_to_user_or_relatives?
  end

  def show?
    return true if record.collectif? && record.reservable_online? && rdv_belongs_to_user_or_relatives?

    rdv_belongs_to_user_or_relatives? && (!current_user.only_invited? || current_user.invited_for_rdv?(record))
  end

  def cancel?
    show? && record.cancellable_by_user?
  end

  def edit?
    show? && record.editable_by_user?
  end

  def can_change_participants?
    !current_user.only_invited? && current_user.participation_for(record).not_cancelled? && !record.in_the_past?
  end

  alias creneaux? edit?
  alias update? edit?

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      my_rdvs_ids = scope
        .joins(:users)
        .where(users: { id: current_user.id })
        .or(
          User
          .joins(:users)
          .where(users: { responsible_id: current_user.id })
        )
        .visible
        .ids

      scope.where(id: my_rdvs_ids).or(Rdv.where(id: scope.collectif.reservable_online)).distinct
    end
  end
end
