# frozen_string_literal: true

require 'spec_helper'

module Decidim
  module DepartmentAdmin
    describe Permissions do
      let(:area) { create(:area) }
      let!(:user) do
        create(:department_admin, :confirmed, organization: area.organization, area: area)
      end

      def should_allow_action(scope, action, subject)
        action= PermissionAction.new(scope: scope, action: action, subject: subject)
        permissions= DepartmentAdmin::Permissions.new(user, action)
        expect(permissions.permissions).to be_allowed
      end

      def should_allow_action_with_ctx(scope, action, subject, ctx)
        action= PermissionAction.new(scope: scope, action: action, subject: subject)
        permissions= DepartmentAdmin::Permissions.new(user, action, ctx)
        expect(permissions.permissions).to be_allowed
      end

      context 'when user role is department_admin' do
        context 'with simple permission actions' do
          it 'should allow accepted actions' do
            should_allow_action(:admin, :read, :admin_dashboard)
            should_allow_action(:admin, :read, :process_list)
            should_allow_action(:admin, :create, :process)
            should_allow_action(:admin, :read, :process_step)
            should_allow_action(:admin, :create, :process_step)
            should_allow_action(:admin, :read, :assembly_list)
            should_allow_action(:admin, :create, :assembly)
            should_allow_action(:admin, :index, :newsletter)
            should_allow_action(:admin, :create, :newsletter)
          end
          it 'should NOT allow non accepted actions' do
            action= PermissionAction.new(scope: :admin, action: :write, subject: :admin_dashboard)
            permissions= DepartmentAdmin::Permissions.new(user, action)
            expect { permissions.permissions.allowed? }.to raise_error(Decidim::PermissionAction::PermissionNotSetError)
          end
        end

        context 'with permission actions with context' do
          context 'when acction is allowed and context is space_name' do
            it 'should allow accepted actions with expected context' do
              should_allow_action_with_ctx(:admin, :enter, :space_area, space_name: :processes)
              should_allow_action_with_ctx(:admin, :enter, :space_area, space_name: :assemblies)
            end
            it 'should NOT allow accepted actions with unexpected context' do
              action= PermissionAction.new(scope: :admin, action: :enter, subject: :space_area)
              permissions= DepartmentAdmin::Permissions.new(user, action, space_name: :conferences)
              expect { permissions.permissions.allowed? }.to raise_error(Decidim::PermissionAction::PermissionNotSetError)
            end
          end
          context 'when acction is allowed and context is process' do
            context 'when process has same area as department_admin' do
              let(:process) { create(:participatory_process, organization: area.organization, area: area) }
              let(:assembly) { create(:assembly, organization: area.organization, area: area) }

              it 'should allow accepted actions with expected context' do
                should_allow_action_with_ctx(:admin, :read, :participatory_space, current_participatory_space: process)
                should_allow_action_with_ctx(:admin, :update, :process, process: process)
                pps= ParticipatoryProcessStep.new(participatory_process: process)
                should_allow_action_with_ctx(:admin, :update, :process_step, process_step: pps)
                should_allow_action_with_ctx(:admin, :destroy, :process_step, process_step: pps)
                should_allow_action_with_ctx(:admin, :update, :assembly, assembly: assembly)
                # -> {permission_for?(requested_action, :admin, :read, :newsletter, restricted_rsrc: context[:newsletter])},
              end
            end
            context 'when process has different area as department_admin' do
              let(:process) { create(:participatory_process, organization: area.organization) }

              it 'should NOT allow accepted actions with unexpected context' do
                action= PermissionAction.new(scope: :admin, action: :update, subject: :process)
                permissions= DepartmentAdmin::Permissions.new(user, action, process: process)
                expect { permissions.permissions.allowed? }.to raise_error(Decidim::PermissionAction::PermissionNotSetError)
              end
            end
          end
        end
      end
    end
  end
end