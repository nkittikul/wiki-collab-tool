class ChargesController < ApplicationController
  def new
    # Because large hashes in haml are no fun
    @stripe_btn_hash = {
      src: "https://checkout.stripe.com/checkout.js", 
      class: 'stripe-button',
      data: {
        key: "#{ Rails.configuration.stripe[:publishable_key] }",
        description: "Premium Membership - #{current_user.email}",
        amount: 5_00 
        # We're like the Snapchat for Wikipedia. But really, 
        # change this amount. Stripe won't charge $9 billion.
      }
    }
  end

  def create
    @amount = params[:amount]

    # Creates a Stripe Customer object, for associating
    # with the charge
    customer = Stripe::Customer.create(
      email: current_user.email,
      card: params[:stripeToken]
    )

    # Where the real magic happens
    charge = Stripe::Charge.create(
      customer: customer.id, # Note -- this is NOT the user_id in your app
      amount: @amount,
      description: "Premium Membership - #{current_user.email}",
      currency: 'usd'
    )

    flash[:notice] = "Thank you, #{current_user.email}! You are now a premium member."
    current_user.update_attribute(:premium, true)
    redirect_to wikis_path # or wherever

    # Stripe will send back CardErrors, with friendly messages
    # when something goes wrong.
    # This `rescue block` catches and displays those errors.
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to new_charge_path
  end

end
