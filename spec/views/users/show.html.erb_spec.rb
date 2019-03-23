require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.create(:user, name: 'Вика') }

  before(:each) do
    sign_in user
    stub_template 'users/_game.html.erb' => 'User game goes here'
    render
  end

  it 'renders user name' do
    expect(rendered).to match 'Вика'
  end

  it 'renders change name and password button for current user only' do
    expect(rendered).to match 'Сменить имя и пароль'
  end

  it 'renders partial with users game' do
  expect(rendered).to have_content 'User game goes here'
  end
end
