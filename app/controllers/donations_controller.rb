class DonationsController < ApplicationController
       



  def new
  	@task = Task.find(params[:task_id])
  	@donation = Donation.new
    
  end

  def create
    @donation = Donation.new(donation_params)
    redirect_to @donation.payment_url(@donation)
  	   
  end

  



private
def donation_params
  params.require(:donation).permit(:task_id, :amount, :paypal_email)

end



end
