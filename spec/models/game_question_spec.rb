require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: переменная будет создаваться заново для каждого блока it, где её вызываем
  # Распределяем варианты ответов по-своему
  let(:game_question) do
    FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  context 'game status' do
    # Тест на правильную генерацию хеша с вариантами
    it 'correct .variants' do
      # Ожидаем, что варианты ответов будут соответствовать тем,
      # которые мы написали выше
      expect(game_question.variants).to eq(
                                            'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                        )
    end

    # Проверяем метод correct_answer_key
    it 'correct .correct_answer_key' do
      expect(game_question.correct_answer_key).to eq('b')
    end

    # Проверяем метод answer_correct?
    it 'correct .answer_correct?' do
      # Именно под буквой b выше мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  context 'make methods delegates' do
    it 'correct .text' do
      expect(game_question.text).to eq(game_question.question.text)
    end

    it 'correct .level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }

  #Тесты для нового функционала подсказок
  context 'user helpers' do
    it 'correct audience_help' do
      # Проверяем, что объект не включает эту подсказку
      expect(game_question.help_hash).not_to include(:audience_help)

      # Добавили подсказку. Этот метод реализуем в модели
      # GameQuestion
      game_question.add_audience_help

      # Ожидаем, что в хеше появилась подсказка
      expect(game_question.help_hash).to include(:audience_help)

      # Дёргаем хеш
      ah = game_question.help_hash[:audience_help]
      # Проверяем, что входят только ключи a, b, c, d
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end

    it 'correct .help_hash' do
      # на фабрике у нас изначально хэш пустой
      expect(game_question.help_hash).to eq({})

      # добавляем пару ключей
      game_question.help_hash[:key1] = 'one'
      game_question.help_hash['key2'] = 'two'

      # сохраняем модель и ожидаем сохранения хорошего
      expect(game_question.save).to be_truthy

      # загрузим этот же вопрос из базы для чистоты эксперимента
      gq = GameQuestion.find(game_question.id)

      # проверяем новые значение хэша
      expect(gq.help_hash).to eq({key1: 'one', 'key2' => 'two'})
    end
  end
end
