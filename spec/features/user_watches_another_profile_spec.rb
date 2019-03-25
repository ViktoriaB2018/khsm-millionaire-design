require 'rails_helper'

RSpec.feature 'USER watches profile another user', type: :feature do
  let(:user1) { FactoryBot.create(:user, id: 1) }
  let(:user2) { FactoryBot.create(:user, id: 2, name: 'Vasya') }

  let!(:games) {[
      FactoryBot.create(:game, id: 2, user: user2, finished_at: "2019-03-25 18:01:09",
                        current_level: 4, is_failed: true, prize: 0, created_at: "2019-03-25 18:00:40",
                        updated_at: "2019-03-25 18:01:09", fifty_fifty_used: false,
                        audience_help_used: true, friend_call_used: true),
      FactoryBot.create(:game,id: 1, user: user2, finished_at: "2019-03-24 17:09:15",
                        current_level: 6, is_failed: true, prize: 1000, created_at: "2019-03-24 17:08:11",
                        updated_at: "2019-03-24 17:09:15", fifty_fifty_used: false,
                        audience_help_used: true, friend_call_used: true)
  ]}

  before(:each) do
    login_as user2
    login_as user1
  end

  scenario 'successfully' do
    visit '/'
    click_link('Vasya')

    expect(page).to have_current_path('/users/2')
    expect(page).to have_content('Vasya')
    expect(page).to have_no_content('Сменить имя и пароль')
    expect(page).to have_content('2 проигрыш 25 марта, 18:00 4 0 ₽ 50/50')
    expect(page).to have_content('1 проигрыш 24 марта, 17:08 6 1 000 ₽ 50/50')
  end
end
