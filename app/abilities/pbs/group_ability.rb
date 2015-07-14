# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Pbs::GroupAbility
  extend ActiveSupport::Concern

  included do
    on(Group) do
      permission(:layer_and_below_full).may(:modify_superior).if_mitarbeiter_gs

      permission(:any).may(:evaluate_census).if_member

      permission(:layer_and_below_full).
        may(:show_population, :create_member_counts).
        in_same_layer_or_below

      permission(:layer_and_below_full).
        may(:remind_census, :update_member_counts, :delete_member_counts).
        in_same_layer_or_below_if_leader

      permission(:approve_applications).may(:pending_approvals).if_layer_and_approver_in_group
    end
  end

  def in_same_layer_or_below_if_leader
    in_same_layer_or_below &&
    user.roles.any? do |r|
      r.kind_of?(Group::Bund::MitarbeiterGs) ||
      r.kind_of?(Group::Bund::Sekretariat) ||
      r.kind_of?(Group::Kantonalverband::Kantonsleitung) ||
      r.kind_of?(Group::Kantonalverband::Sekretariat) ||
      r.kind_of?(Group::Region::Regionalleitung) ||
      r.kind_of?(Group::Region::Sekretariat)
    end
  end

  def if_mitarbeiter_gs
    user.roles.any? do |r|
      r.is_a?(Group::Bund::MitarbeiterGs)
    end
  end

  def if_layer_and_approver_in_group
    user_roles = user.roles.collect(&:class)
    approving_group_roles = group.role_types.select { |type| type.permissions.include?(:approve_applications) }
    group.layer? && contains_any?(user_roles, approving_group_roles)
  end
end
