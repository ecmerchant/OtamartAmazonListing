class AccountsController < ApplicationController
  def regist
    current_email = current_user.email

    if request.patch? then
      @account = Account.new
      data = params[:account]
      logger.debug('\n\nDebug')
      logger.debug(data)
      user = Account.find_by(email: current_email)
      if data[:AWSkey] != nil && data[:skey] != nil && data[:sellerId] != nil then
        if user == nil then
          Account.create(
            email: current_user.email,
            AWSkey: data[:AWSkey],
            skey: data[:skey],
            sellerId:data[:sellerId]
          )
        else
          user.AWSkey = data[:AWSkey]
          user.skey = data[:skey]
          user.sellerId = data[:sellerId]
          user.save
          @res1 = data[:AWSkey]
          @res2 = data[:skey]
          @res3 = data[:sellerId]
        end
      end
    else
      temp = Account.find_by(email:current_email)
      data = params[:account]
      logger.debug("Account is search!!\n\n")
      logger.debug(Account.select("AWSkey"))
      if temp != nil then
        logger.debug("Account is found")
        @account = Account.find_by(email:current_email)
        @res1 = temp.AWSkey
        @res2 = temp.skey
        @res3 = temp.sellerId
      else
        if data != nil then
          @account = Account.create(
            email: current_user.email,
            AWSkey: data[:AWSkey],
            skey: data[:skey],
            sellerId:data[:sellerId]
          )
          @res1 = temp.AWSkey
          @res2 = temp.skey
          @res3 = temp.sellerId
        else
          @account = Account.create(
            email: current_user.email,
            AWSkey: "",
            skey: "",
            sellerId:""
          )
          @res1 = @account.AWSkey
          @res2 = @account.skey
          @res3 = @account.sellerId
        end
      end
    end
  end
end

private
def account_params
  params.require(:account).permit(:AWSkey, :skey, :sellerId)
end
