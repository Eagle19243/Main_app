class CreateAdminService
  def call
    user = User.find_or_create_by!(email: Rails.application.secrets.admin_email) do |user|
        user.password = Rails.application.secrets.admin_password
        user.password_confirmation = Rails.application.secrets.admin_password
        user.name = Rails.application.secrets.admin_name
        user.skip_confirmation!
        user.admin!
    end
  end

  def create_additional_admins
    count = 0
    admins = Rails.application.secrets.additional_admins
    if !admins.nil?
      admins.each do |value|
        user = User.find_or_create_by!(email: value["email"]) do |admin|
          admin.password = value["password"]
          admin.password_confirmation = value["password"]
          admin.name = value["name"]
          admin.skip_confirmation!
          admin.admin!
        end
        count += 1
      end
    end
    count
  end

  def create_admin_wallet
    unless ( AdminReseveWallet.any?)
    AdminReseveWallet.new.create_we_serve_wallet
    end
  end

end
