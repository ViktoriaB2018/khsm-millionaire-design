require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  # Пользоваль для создания игр
  let(:user) { FactoryBot.create(:user) }

  # Игра с вопросами для проверки работы
  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики по созданию новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Используем метод: создадим 60 вопросов, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создали игру, обернули в блок, на который накладываем проверки
      # Смотрим, как этот блок кода изменит базу
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
          # GameQuestion.count +15
          change(GameQuestion, :count).by(15).and(
              # Game.count не должен измениться
              change(Question, :count).by(0)
          )
      )

      # Проверяем юзера и статус
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем, сколько было вопросов
      expect(game.game_questions.size).to eq(15)
      # Проверяем массив уровней
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Проверяем начальный статус игры
      level = game_w_questions.current_level
      # Текущий вопрос
      q = game_w_questions.current_game_question
      # Проверяем, что статус in_progress
      expect(game_w_questions.status).to eq(:in_progress)

      # Выполняем метод answer_current_question! и сразу передаём верный ответ
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Проверяем, что уровень изменился
      expect(game_w_questions.current_level).to eq(level + 1)

      # Проверяем, что изменился текущий вопрос
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Проверяем, что игра продолжается/не закончена
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    # Проверяем метод .current_game_question
    it '.current_game_question returns new current question' do
      q = game_w_questions.game_questions[0]
      expect(game_w_questions.current_game_question).to eq(q)
    end

    # Проверяем метод .previous_level
    it '.previous_level returns (current_level - 1)' do
      # При current_level в начале игры
      expect(game_w_questions.previous_level).to eq(-1)

      # При current_level в середине игры
      game_w_questions.current_level = 6
      expect(game_w_questions.previous_level).to eq(5)
    end

    # Проверяем статусы игры
    context '.status' do
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.finished?).to be_truthy
      end

      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end

      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end

      it ':timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end

      it ':money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end

    # Проверяем метод answer_current_question!
    context '.answer_current_question!' do
      # Неправильный ответ должен заканчивать игру
      it 'wrong answer finishes game' do
        game_w_questions.current_level = 6
        # Проверяем неверный ответ
        expect(game_w_questions.answer_current_question!('a')).to be_falsey

        # Проверяем что игра закончилась если ответ не верный
        expect(game_w_questions.finished?).to be_truthy

        # Проверяем что приз равен ближ. несгораемой сумме
        expect(game_w_questions.prize).to eq(1_000)
      end

      # Последний правильный ответ должен заканчивать игру
      it 'last right answer finishes game' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max

        # Проверяем верный ответ
        expect(game_w_questions.answer_current_question!('d')).to be_truthy

        # Проверяем что игра закончилась при последнем верном ответе
        expect(game_w_questions.finished?).to be_truthy

        # Проверяем что приз равен миллиону
        expect(game_w_questions.prize).to eq(1_000_000)
      end

      # Правильный ответ продолжает игру
      it 'right answer continues game' do
        game_w_questions.current_level = 6

        # Проверяем верный ответ
        expect(game_w_questions.answer_current_question!('d')).to be_truthy

        # Проверяем что игра не закончилась
        expect(game_w_questions.finished?).to be_falsey
      end

      # Проверяем правильный ответ после timeout
      it 'answer is right after timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.time_out!

        # Проверяем что при timeout правильный ответ уже не true
        expect(game_w_questions.answer_current_question!('d')).to be_falsey

        # Проверяем что игра закончилась
        expect(game_w_questions.finished?).to be_truthy

        # Проверяем что приз равен нулю
        expect(game_w_questions.prize).to eq(0)
      end

    end
  end
end
