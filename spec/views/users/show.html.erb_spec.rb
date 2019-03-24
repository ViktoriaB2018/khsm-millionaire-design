require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    user = FactoryBot.create(:user, name: 'Vika')
    @games = [FactoryBot.build_stubbed(:game, id: 1, created_at: Time.now, current_level: 6)]
    sign_in user
    #allow(controller).to receive(:current_user).and_return(:user)
    assign(:user, user)
    assign(:games, @games)
    render
  end

  it 'renders user name' do
    expect(rendered).to match 'Vika'
  end

  it 'renders change name and password button for current user only' do
    expect(rendered).to match 'Сменить имя и пароль'
  end

  it 'renders partial with users game' do
  assert_template partial: 'users/_game', count: @games.count
  end
end
