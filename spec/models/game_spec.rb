# frozen_string_literal: true

# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect do
        game = Game.create_game_for_user!(user)
      end.to change(Game, :count).by(1).and( # проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and( # GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  # забираем деньги
  it '.take_money! complete the game' do
    # текущий уровень игры и статус
    q = game_w_questions.current_game_question

    # перешли на след. уровень
    game_w_questions.answer_current_question!(q.correct_answer_key)

    # забираем деньги
    game_w_questions.take_money!

    expect(game_w_questions.status).to eq :money
    expect(game_w_questions.prize).to eq(Game::PRIZES[game_w_questions.previous_level])
    expect(game_w_questions.finished?).to be_truthy
  end

  # проверяет предыдущий уровень
  it 'return the .previous_level' do
    expect(game_w_questions.previous_level).to eq(-1)
    15.times do |try|
      question = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(question.correct_answer_key)
      expect(game_w_questions.previous_level).to eq(try)
    end
  end

  # проверяет текущий вопрос
  it 'return the .current_game_question' do
    15.times do |try|
      question = game_w_questions.current_game_question
      expect(question.level).to eq(try)

      game_w_questions.answer_current_question!(question.correct_answer_key)
    end
  end

  context '.answer_current_question' do
    before(:each) do
      @question = game_w_questions.current_game_question
    end

    it 'end game because time out' do
      game_w_questions.created_at -= (Game::TIME_LIMIT + 5.minutes)

      expect(game_w_questions.answer_current_question!(@question.correct_answer_key)).to eq false
      expect(game_w_questions.status).to eq :timeout
    end

    it 'end game because game is finished' do
      game_w_questions.finished_at = Time.now

      expect(game_w_questions.answer_current_question!(@question.correct_answer_key)).to eq false
    end

    it 'end game because answer is wrong' do
      expect(game_w_questions.answer_current_question!('a')).to eq false
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'finish game because it is last question' do
      question_levels = Question::QUESTION_LEVELS

      game_w_questions.current_level = question_levels.max

      expect(game_w_questions.answer_current_question!(@question.correct_answer_key)).to eq true
      expect(game_w_questions.current_level).to eq question_levels.max + 1
      expect(game_w_questions.prize).to eq(Game::PRIZES[question_levels.max])
    end

    it 'set new question level' do
      level = game_w_questions.current_level

      expect(game_w_questions.answer_current_question!(@question.correct_answer_key)).to eq true
      expect(game_w_questions.current_level).to eq level + 1
    end
  end

  context '.status' do
    before(:each) do
      @question = game_w_questions.current_game_question
    end

    # статус :in_progress
    it 'game status in_progress' do
      # текущий уровень игры и статус
      expect(game_w_questions.status).to eq(:in_progress)
    end

    # статус :fail
    it 'game status fail' do
      game_w_questions.answer_current_question!('a')
      expect(game_w_questions.status).to eq(:fail)
    end

    # статус :money
    it 'game status money' do
      game_w_questions.answer_current_question!(@question.correct_answer_key)
      game_w_questions.take_money!

      expect(game_w_questions.status).to eq :money
    end

    # статус :won
    it 'game status won' do
      15.times do
        question = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(question.correct_answer_key)
      end

      expect(game_w_questions.status).to eq :won
    end

    # статус :timeout
    it 'game status timeout' do
      game_w_questions.created_at -= (Game::TIME_LIMIT + 5.minutes)
      game_w_questions.answer_current_question!(@question.correct_answer_key)

      expect(game_w_questions.status).to eq :timeout
    end
  end
end
