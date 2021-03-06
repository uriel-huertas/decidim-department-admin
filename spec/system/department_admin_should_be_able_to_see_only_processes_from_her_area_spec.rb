# frozen_string_literal: true

require 'spec_helper'

describe 'Admin manages participatory processes', versioning: true, type: :system do
  let(:organization) { create(:organization) }
  let(:area) { create(:area) }
  let(:department_admin) { create(:department_admin, :confirmed, organization: organization, area: area) }

  let!(:participatory_process_w_area) do
    create(:participatory_process, organization: organization, area: area)
  end
  let!(:participatory_process_wo_area) do
    create(:participatory_process, organization: organization)
  end

  before do
    switch_to_host(organization.host)
    login_as department_admin, scope: :user
    visit decidim_admin_participatory_processes.participatory_processes_path
  end

  it 'should see only processes in the same area' do
    expect(page).to have_content(participatory_process_w_area.title['en'])
    expect(page).to_not have_content(participatory_process_wo_area.title['en'])
  end
end
