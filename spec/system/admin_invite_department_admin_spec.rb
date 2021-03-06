# frozen_string_literal: true

require 'spec_helper'

describe 'Admin invite user as department admin', type: :system do
  let!(:area) { create(:area) }

  let(:organization) { create(:organization) }

  let!(:admin) { create(:user, :admin, :confirmed, organization: organization) }
  let(:user_manager) { create(:user, :user_manager, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as admin, scope: :user
    visit decidim_admin.new_user_path
  end

  it 'admin is successfully created' do
    fill_the_form('Cabello Loco', 'my@email.net')
    submit_form
    check_succeess
    check_is_department_admin('my@email.net')
    check_assigned_area(@user, area)
  end

  it 'admin is able to add department_admin to existing user' do
    fill_the_form(user_manager.name, user_manager.email)
    submit_form
    check_succeess
    check_is_department_admin(user_manager.email)
    check_assigned_area(user_manager, area)
  end

  context 'when departments are reorganized' do
    let(:department_admin) do
      user= create(:user, :confirmed, organization: organization)
      user.roles << 'department_admin'
      user.areas << area
      user.save!
      user
    end
    let!(:new_area) { create(:area) }

    before { visit decidim_admin.new_user_path }

    it "admin is able to change department_admin's area/department" do
      fill_the_form(department_admin.name, department_admin.email, new_area)
      submit_form
      check_succeess
      check_is_department_admin(department_admin.email)
      check_assigned_area(department_admin, new_area)
    end
  end

  def fill_the_form(name, email, selected_area = area)
    within 'form.new_user' do
      fill_in :user_name, with: name
      fill_in :user_email, with: email
      find('#user_role').find("option[value='department_admin']").select_option
      find('#user_area_id').find("option[value='#{selected_area.id}']").select_option
    end
  end

  def submit_form
    find('*[name=commit][type=submit]').click
  end

  def check_succeess
    expect(page).to have_content('Participant successfully invited.')
    expect(page).to have_current_path '/admin/users'
  end

  def check_is_department_admin(email)
    @user= Decidim::User.find_by_email(email)
    expect(@user.roles).to include('department_admin')
  end

  def check_assigned_area(user, area)
    expect(user.areas.last).to eq(area)
  end
end
