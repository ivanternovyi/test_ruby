require 'yaml'
require 'ostruct'
require_relative 'constants'

class ATM
  def initialize
    @data = YAML.load_file(ARGV.first || 'config.yml')
    ARGV.clear
    @user = welcome_menu
    choice_menu
  end

  private

  def find_user(id, passw)
    @data['accounts'].each_pair do |id_key, info|
      if id == id_key.to_s && info['password'] == passw
        return OpenStruct.new(name: info['name'], password: info['password'],
                              balance: info['balance'])
      end
    end
    nil
  end

  def atm_balance
    @data['banknotes'].map { |cash, count| cash * count }.reduce(:+)
  end

  def can_cash_in?(amount)
    @data['banknotes'].each_pair do |cash, count|
      count.times do
        break unless amount - cash >= 0
        amount -= cash
        count -= 1
      end
    end
    amount.zero?
  end

  def log_out
    puts "\n#{@user[:name]}, " + GOOD_BYE
    @user = welcome_menu
    puts "\nHello, #{@user[:name]}!\n\n"
  end

  def check_withdraw(amount)
    if amount > @user[:balance]
      print INSUFFICIENT_FUNDS
    elsif amount > atm_balance
      print MAX_AMOUNT_ATM + '₴' + atm_balance.to_s + ENTER_DIFF_VALUE
    elsif !can_cash_in?(amount)
      print COMPOSE_ERR
    else
      true
    end
  end

  def withdraw(amount)
    @user[:balance] -= amount
    @data['accounts'].each_pair { |_id, info| info['balance'] -= amount if info['name'] == @user['name']}
    @data['banknotes'].each_pair do |cash, count|
      count.times do
        break unless amount - cash >= 0
        amount -= cash
        @data['banknotes'][cash] -= 1
      end
    end
  end

  def welcome_menu
    loop do
      print ENTER_ACC_ID
      id = gets.chomp
      print ENTER_PASSW
      passw = gets.chomp
      return find_user(id, passw) if find_user(id, passw)
      puts ERR_LOGIN
    end
  end

  def choice_menu
    puts "\nHello, #{@user[:name]}!\n\n"
    loop do
      print CHOICES
      choice = gets.chomp
      case choice
      when '1'
        puts "\nYour Current Balance is ₴#{@user[:balance]}\n\n"
      when '2'
        withdraw_menu
      when '3'
        log_out
      else
        print BAD_CHOICE
      end
    end
  end

  def withdraw_menu
    print WISH_WITHDRAW
    loop do
      amount = gets.chomp
      if amount.to_i.to_s == amount
        amount = amount.to_i
      else
        print ERR_INT
        next
      end
      next unless check_withdraw amount
      withdraw amount
      print "\nYour New Balance is ₴#{@user[:balance]}\n\n"
      break
    end
  end
end

ATM.new