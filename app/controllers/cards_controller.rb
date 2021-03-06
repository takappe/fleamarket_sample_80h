class CardsController < ApplicationController
  require "payjp"
  before_action :authenticate_user!, only: [:new]
  before_action :set_card, only: [:new, :show, :destroy]

  def new
    card = Card.where(user_id: current_user.id)
    redirect_to card_path(@card.id) if card.present?
  end

  def pay
    Payjp.api_key = Rails.application.credentials.PAYJP[:secret_access_key]
    return redirect_to action: "new" if params["payjp_token"].blank?
      customer = Payjp::Customer.create(
        description: 'test',
        email: current_user.email,
        card: params["payjp_token"],
        metadata: {user_id: current_user.id}
      )
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      return redirect_to card_path(current_user.id) if @card.save
        redirect_to action: "pay"
  end

  def show
    return redirect_to action: "new" if @card.blank?
      Payjp.api_key = Rails.application.credentials.PAYJP[:secret_access_key]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @card_info = customer.cards.retrieve(@card.card_id)
      @card_brand = @card_info.brand
      @exp_month = @card_info.exp_month.to_s
      @exp_year = @card_info.exp_year.to_s.slice(2,3) 
      case @card_brand
      when "Visa"
        @card_image = "visa.png"
      when "JCB"
        @card_image = "jcb.png"
      when "MasterCard"
        @card_image = "master.png"
      when "American Express"
        @card_image = "amex.png"
      when "Diners Club"
        @card_image = "diners.png"
      when "Discover"
        @card_image = "discover.png"
      end
  end

  def destroy
    if @card.present?
      Payjp.api_key = Rails.application.credentials.PAYJP[:secret_access_key]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      customer.delete
      @card.delete
    end
      redirect_to card_path(@card.id)
  end

  private
  def set_card
    @card = Card.find_by(user_id: current_user.id)
  end

end


