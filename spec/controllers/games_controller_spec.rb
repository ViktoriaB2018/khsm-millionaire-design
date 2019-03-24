require 'rails_helper'
require 'support/my_spec_helper'

Devise::Test::ControllerHelpers

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Юзер не залогинен
  context 'Anon' do
    # Аноним не может смотреть игру
    it 'kick from #show' do
      # Вызываем экшен
      get :show, id: game_w_questions.id
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    # Аноним не может cоздать игру
    it 'kick from #create' do
      # Вызываем экшен
      post :create
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    # Аноним не может ответить на вопрос
    it 'kick from #answer' do
      # Вызываем экшен
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end

    # Аноним не может забрать деньги
    it 'kick from #take_money' do
      # Вызываем экшен
      put :take_money, id: game_w_questions.id
      # Проверяем ответ
      # статус ответа не равен 200
      expect(response.status).not_to eq(200)
      # Devise должен отправить на логин
      expect(response).to redirect_to(new_user_session_path)
      # Во flash должно быть сообщение об ошибке
      expect(flash[:alert]).to be
    end
  end

  # Юзер залогинен
  context 'Usual user' do
    # Этот блок будет выполняться перед каждым тестом в группе
    # Логиним юзера с помощью девайзовского метода sign_in
    before(:each) { sign_in user }

    it 'creates game' do
      # Создадим пачку вопросов
      generate_questions(15)
      # Экшен create у нас отвечает на запрос POST
      post :create
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Проверяем состояние этой игры: она не закончена
      # Юзер должен быть именно тот, которого залогинили
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # Проверяем, есть ли редирект на страницу этой игры
      # И есть ли сообщение об этом
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      # Показываем по GET-запросу
      get :show, id: game_w_questions.id
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)
      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Юзер именно тот, которого залогинили
      expect(game.user).to eq(user)

      # Проверяем статус ответа (200 ОК)
      expect(response.status).to eq(200)
      # Проверяем рендерится ли шаблон show (НЕ сам шаблон!)
      expect(response).to render_template('show')
    end

    # Проверяет поведение контроллера, если юзер ответил на вопрос верно
    it 'answers correct' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Уровень больше 0
      expect(game.current_level).to be > 0

      # Редирект на страницу игры
      expect(response).to redirect_to(game_path(game))
      # Флеш пустой
      expect(flash.empty?).to be_truthy
    end

    # Проверяет поведение контроллера, если юзер ответил на вопрос неверно
    it 'answers not correct' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: "a"
      game = assigns(:game)

      # Игра закончена поражением
      expect(game.finished?).to be_truthy
      expect(game.status).to eq(:fail)

      # Редирект на профиль юзера
      expect(response).to redirect_to(user_path(user))
      # Флеш
      expect(flash[:alert]).to be
    end

    # Пользователь не может смотреть чужую игру
    it 'kick from #show another game' do
      # создаем новую игру, юзер не прописан, будет создан фабрикой новый
      another_game = FactoryBot.create(:game_with_questions)

      # пробуем зайти на эту игру как текущий залогиненный user
      get :show, id: another_game.id

      # статус не 200 ОК
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)

      # во flash должна быть прописана ошибка
      expect(flash[:alert]).to be
    end

    # Пользователь берет деньги
    it 'takes money' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # Пользователь пытается создать новую игру, не закончив старую
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be_falsey

      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game).to be_nil

      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    # Пользователь использует "помощь зала"
    it 'uses audience help' do
      # Проверяем, что у текущего вопроса нет подсказок
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      # И подсказка не использована
      expect(game_w_questions.audience_help_used).to be_falsey

      # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    # Пользователь использует "50/50"
    it 'uses fifty_fifty help' do
      # Проверяем, что у текущего вопроса нет подсказки 50/50
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      # И подсказка не использована
      expect(game_w_questions.fifty_fifty_used).to be_falsey

      # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      game = assigns(:game)

      # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.fifty_fifty_used).to be_truthy
      expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
      expect(game.current_game_question.help_hash[:fifty_fifty]).to include('d')
      expect(response).to redirect_to(game_path(game))
    end
  end
end
