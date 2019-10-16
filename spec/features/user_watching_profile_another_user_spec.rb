# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'USER watching profile another user', type: :feature do
  let(:user) { FactoryBot.create :user }
  let(:another_user) { FactoryBot.create :user, id: 5 }

  before(:each) do
    FactoryBot.create(:game,
                      user: another_user,
                      created_at: Time.parse('2019.10.19, 13:00'),
                      current_level: 10,
                      prize: 1000)

    FactoryBot.create(:game,
                      user: another_user,
                      created_at: Time.parse('2018.01.01, 13:00'),
                      current_level: 5,
                      is_failed: true,
                      finished_at: Time.parse('2018.01.01, 13:10'),
                      prize: 500)

    login_as user
  end

  scenario 'user goes to another user’s page from the main page' do
    visit '/'

    click_link another_user.name

    #  Ожидаем, что попадем на нужный url
    expect(page).to have_current_path '/users/5'

    # Ожидаем, что на странице пользователя,
    # к которому заходим обязательно есть имя пользователя.
    expect(page).to have_content another_user.name

    # Ожидаем, что на странице другого пользователя
    # нет ссылки "Сменить имя и пароль"
    expect(page).not_to have_content 'Сменить имя и пароль'

    # Ожидаем, что на странице есть наша тестовая игра
    # Игра 1
    expect(page).to have_content 'в процессе'
    expect(page).to have_content '19 окт., 13:00'
    expect(page).to have_content '10'
    expect(page).to have_content '1 000 ₽'

    # Игра 2
    expect(page).to have_content 'проигрыш'
    expect(page).to have_content '01 янв., 13:00'
    expect(page).to have_content '5'
    expect(page).to have_content '500 ₽'
  end
end
