class DonationsController < ApplicationController
 



  def new
  	@task = Task.find(params[:task_id])
  	@donation = Donation.new
  end

  def create
  	@donation = Donation.build_params
  end

  def update
  end

  def destroy
  end





end
