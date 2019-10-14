# frozen_string_literal: true

# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq('a' => game_question.question.answer2,
                                           'b' => game_question.question.answer1,
                                           'c' => game_question.question.answer4,
                                           'd' => game_question.question.answer3)
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      ah = game_question.help_hash[:audience_help]
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  it 'correct .level & .text delegates' do
    expect(game_question.text).to eq(game_question.question.text)
    expect(game_question.level).to eq(game_question.question.level)
  end

  it 'correct .correct_answer_key' do
    # правильный ответ b
    expect(game_question.correct_answer_key).to eq('b')
  end

  it 'using method .help_hash' do
    expect(game_question.help_hash).to be_empty

    game_question.add_audience_help
    expect(game_question.help_hash).to include(:audience_help)
    ah = game_question.help_hash[:audience_help]
    expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')

    game_question.add_friend_call
    expect(game_question.help_hash).to include(:friend_call)

    game_question.add_fifty_fifty
    expect(game_question.help_hash).to include(:fifty_fifty)
    # правильный ответ 'b'
    expect(game_question.help_hash[:fifty_fifty]).to start_with('b')
  end

  it 'using help fifty fifty' do
    expect(game_question.help_hash).to be_empty

    game_question.add_fifty_fifty

    expect(game_question.help_hash).to include(:fifty_fifty)
    fifty_fifty = game_question.help_hash[:fifty_fifty]
    # правильный ответ 'b'
    expect(fifty_fifty).to start_with(game_question.correct_answer_key)
    expect(fifty_fifty.size).to eq 2
  end

  it 'using help friend call' do
    expect(game_question.help_hash).to be_empty

    game_question.add_friend_call

    expect(game_question.help_hash).to include(:friend_call)
  end
end
