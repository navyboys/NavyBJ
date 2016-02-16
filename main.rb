require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards)
    # keep only value info
    values = cards.map{|e| e[1]}

    # calculate
    total = 0
    values.each { |e| total += numerate(e) }

    # correct for 'A'
    values.select{|e| e == 'A'}.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end

    total
  end

  def numerate(card)
    if card == 'A'
      11
    elsif card.to_i == 0
      10
    else
      card.to_i
    end
  end

  def card_image(card)
    suit = card[0].downcase

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def win!(msg)
    @once_again = true
    @show_player_action_button = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @success = "<strong>You win!</strong> #{msg}"
  end

  def lose!(msg)
    @once_again = true
    @show_player_action_button = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @error = "<strong>You lose!</strong> #{msg}"
  end

  def tie!(msg)
    @once_again = true
    @show_player_action_button = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_player_action_button = true
  @show_dealer_action_button = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect 'new_player'
  end
end

get '/new_player' do
  session[:player_pot] = 500
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is empty!"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  if session[:player_pot] == 0
    redirect 'game_over'
  end

  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Please make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Sorry, you have no enough money. Make a bet under $#{session[:player_pot]}."
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
  # create deck
  suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  # deal card
  session[:player_cards] << session[:deck].pop

  # decision tree
  player_total = calculate_total(session[:player_cards])
  if player_total > BLACKJACK_AMOUNT
    lose!("You busted at #{player_total}.")
  elsif player_total == BLACKJACK_AMOUNT
    win!("You hit blackjack.")
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "You have chosen to stay!"
  @show_player_action_button = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = 'dealer'
  @show_player_action_button = false

  # decision tree
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total > BLACKJACK_AMOUNT
    win!("Dealer busted at #{dealer_total}.")
  elsif dealer_total == BLACKJACK_AMOUNT
    lose!("Dealer hit blackjack.")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_action_button = true
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_player_action_button = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  # decision tree
  if player_total > dealer_total
    win!("You stayed at #{player_total} and the dealer stayed at #{dealer_total}.")
  elsif player_total < dealer_total
    lose!("You stayed at #{player_total} and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both you and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end
