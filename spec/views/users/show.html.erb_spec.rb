# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) do
    FactoryBot.create(:user, name: 'Вова')
  end

  let(:games) { [FactoryBot.create(:game, user: user)] }

  # Пользователь не залогинился
  context 'Anon' do
    before(:each) do
      assign(:user, user)

      render
    end

    # Анон видит имя пользователя
    it 'sees user name' do
      expect(rendered).to match 'Вова'
    end

    # Анон не видит кнопку смены пароля
    it 'does not see the password change button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end

  # Пользователь залогинился
  context 'User' do
    before(:each) do
      sign_in(user)
      assign(:user, user)
      assign(:games, games)

      stub_template 'users/_game.html.erb' => 'Игры пользователя здесь'
    end
    # Игры отрисовываются
    it 'games are displayed' do
      render
      expect(rendered).to have_content 'Игры пользователя здесь'
    end

    # Пользователь видит кнопку смены пароля в своём профиле
    it 'sees a password change button' do
      render
      expect(rendered).to match 'Сменить имя и пароль'
    end

    # Пользователь не видит кнопку смены пароля другого пользователя
    it 'does not see the password change button another user' do
      assign(:user, FactoryBot.create(:user, name: 'Another'))
      render

      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
