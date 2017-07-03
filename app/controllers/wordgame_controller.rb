# require 'open-uri'
# require 'json'

class WordgameController < ApplicationController
  def game
    @message = params[:message]
     @guess = params[:guess]

    # @grid = generate_grid(params[:grid_size].to_i).join if params[:grid_size]

    # @attempt = 0
    if session[:attempt]
      session[:attempt] += 1
    else
      session[:attempt] = 0
    end

    if params[:grid].present?
      @grid = params[:grid]
    else
      @grid = generate_grid(params[:grid_size].to_i).join if params[:grid_size]
    end
  end

  def score
     @grid = params[:grid]
     @guess = params[:guess]
     start_time = params[:start_time].to_i
     end_time = Time.now.to_i
     time_taken = end_time - start_time
     # @attempt += 1
     translation = get_translation(@guess)
     # byebug


      @results = run_game(@guess, @grid, start_time, end_time)



     if @results[:score] > 0
      @score = @results[:score]
    else
      redirect_to game_path(grid: @grid, message: @results[:message])
    end
  end

  private

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def included?(guess, grid)
    guess = guess.split("")
    guess.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(
    attempt, result[:translation], grid, result[:time])

    result
  end

  def score_and_message(attempt, translation, grid, time)
    if included?(attempt.upcase, grid)
      if translation
        score = compute_score(attempt, time)
        message = [score, "Well done"]
      else
        message = [0, "Not an english word! Try Again!"]
      end
    else
      message = [0, "Not in the grid. Try again!"]
    end
  end

  def get_translation(word)
    api_key = "73eb0293-bbb6-4f3b-ba8b-a1158ef83508"
    begin
      response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=#{api_key}&input=#{word}")
      json = JSON.parse(response.read.to_s)
      if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
        return json['outputs'][0]['output']
      end
    rescue
      if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
        return word
      else
        return nil
      end
    end
  end


end
