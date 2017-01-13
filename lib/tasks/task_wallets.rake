namespace :task_wallets do
  desc "TODO"
  task create_wallet_address: :environment do
    @tasks =  Task.where.not( state: 'suggested_task')
    @tasks.each do |task|
      if  task.wallet_address.blank?
        task.assign_address
        puts "Wallet Address for #{ task.id } has been created "
      end
    end
  end

end