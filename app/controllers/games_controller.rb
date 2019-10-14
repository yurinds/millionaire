# frozen_string_literal: true

# (c) goodprogrammer.ru
#
# Основной игровой контроллер
# Создает новую игру, обновляет статус игры по ответам юзера, выдает подсказки
#
class GamesController < ApplicationController
  before_action :authenticate_user!

  # проверка нет ли у залогиненного юзера начатой игры
  before_action :goto_game_in_progress!, only: [:create]

  # загружаем игру из базы для текущего юзера
  before_action :set_game, except: [:create]

  # проверка - если игра завершена, отправляем юзера на его профиль,
  # где он может увидеть статистику сыгранных игр
  before_action :redirect_from_finished_game!, except: [:create]

  def show
    @game_question = @game.current_game_question
  end

  # создаем новую игру и отправляем на экшен #show в случае успеха
  def create
    # создаем игру для залогиненного юзера
    @game = Game.create_game_for_user!(current_user)

    # отправляемся на страницу игры
    redirect_to game_path(@game), notice: I18n.t('controllers.games.game_created', created_at: @game.created_at)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e # если ошибка создания игры
    Rails.logger.error("Error creating game for user #{current_user.id}, msg = #{e}. #{e.backtrace}")
    # отправляемся назад с алертом
    redirect_to :back, alert: I18n.t('controllers.games.game_not_created')
  end

  # params[:letter] - единственный параметр
  def answer
    # выясняем, правильно ли оветили
    @answer_is_correct = @game.answer_current_question!(params[:letter])
    @game_question = @game.current_game_question

    unless @answer_is_correct
      flash[:alert] = I18n.t(
        'controllers.games.bad_answer',
        answer: @game_question.correct_answer,
        prize: view_context.number_to_currency(@game.prize)
      )
    end

    # Выбираем поведение в зависимости от формата запроса
    respond_to do |format|
      # Если это html-запрос, по-старинке редиректим пользователя в зависимости от ситуации
      format.html do
        if @answer_is_correct && !@game.finished?
          redirect_to game_path(@game)
        else
          redirect_to user_path(current_user)
        end
      end

      # Если это js-запрос, то ничего не делаем и контролл попытается отрисовать шаблон
      # <controller>/<action>.<format>.erb (в нашем случае games/answer.js.erb)
      format.js {}
    end
  end

  # вызывается из вьюхи без параметров
  def take_money
    @game.take_money!
    redirect_to user_path(current_user),
                flash: { warning: I18n.t('controllers.games.game_finished', prize: view_context.number_to_currency(@game.prize)) }
  end

  # запрашиваем помощь в текущем вопросе
  # params[:help_type]
  def help
    # используем помощь в игре и по результату задаем сообщение юзеру

    msg = if @game.use_help(params[:help_type].to_sym)
            { flash: { info: I18n.t('controllers.games.help_used') } }
          else
            { flash: { alert: I18n.t('controllers.games.help_not_used') } }
          end

    redirect_to game_path(@game), msg
  end

  private

  def redirect_from_finished_game!
    if @game.finished?
      redirect_to user_path(current_user), alert: I18n.t('controllers.games.game_closed', game_id: @game.id)
    end
  end

  def goto_game_in_progress!
    # вот нам и пригодился наш scope из модели Game
    game_in_progress = current_user.games.in_progress.first
    unless game_in_progress.blank?
      redirect_to game_path(game_in_progress), alert: I18n.t('controllers.games.game_not_finished')
    end
  end

  def set_game
    @game = current_user.games.find_by(id: params[:id])
    # если у current_user нет игры - посылаем
    if @game.blank?
      redirect_to root_path, alert: I18n.t('controllers.games.not_your_game')
    end
  end
end
