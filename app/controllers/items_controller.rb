class ItemsController < ApplicationController

  require 'csv'
  require 'peddler'
  #before_action :authenticate_user!, only: :get

  before_action :authenticate_user!, :except => [:regist]
  protect_from_forgery :except => [:regist]

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def get

    res = params[:data]
    logger.debug("Parameter=\n\n")
    logger.debug(res)
    @user = current_user.email

    current_email = current_user.email
    csv_data = CSV.read('app/others/csv/Flat.File.Toys.jp.csv', headers: true)
    gon.csv_head = csv_data

    if request.post? then
      if res != nil then
        parser = JSON.parse(res)
        result = parser[0]
        counter = parser[1]
        res = result

        i = counter
        maxnum = 5
        process = 0
        while i < result.length
          url = result[i][0]
          if url != "" && url != nil  then
            charset = nil
            begin
              if url[-1] != "/" then
                url = url + "/"
              end
              html = open(url) do |f|
                charset = f.charset # 文字種別を取得
                f.read # htmlを読み込んで変数htmlに渡す
              end
              logger.debug("=== URL OK ===")
              doc = Nokogiri::HTML.parse(html, nil, charset)
              #商品が出品中の場合
              if /"original":\{([\s\S]*?)original/.match(html) != nil then
                original = /"original":\{([\s\S]*?)original/.match(html)[1]
                title = /"original":\{"name":"([\s\S]*?)"/.match(html)[1]
                tags = /"tags":\[([\s\S]*?)\]/.match(original)[1]
                tags = tags.gsub('"','')
              else
                title = /"name":"([\s\S]*?)"/.match(html)[1]
              end
              logger.debug("========= INFO ==========")
              item_id = /items\/([\s\S]*?)\//.match(url)[1]
              price = /"price":([\s\S]*?),/.match(html)[1]

              condition = /Condition<\/div>([\s\S]*?)<\/div>/.match(html)[1]
              condition = />([\s\S]*?)$/.match(condition)[1]
              delivery = /"delivery_delay_type":([\s\S]*?),/.match(html)[1]

              if delivery.to_i == 1 then
                delivery = "2~3日で出荷"
              elsif delivery.to_i == 2 then
                delivery = "4~7日で出荷"
              else
                delivery = "8日以上で出荷"
              end

              seller = /"seller":\{([\s\S]*?)\}/.match(html)[1]
              seller_name = /"name":"([\s\S]*?)"/.match(seller)[1]

              image_set = /class="item-picture-viewer"([\s\S]*?)class="item-name"/.match(html)[1]
              #images = /src="([\s\S]*?)"/g.match(images_set)
              images = image_set.scan(/src="([\s\S]*?)"/)

              k = 0
              image = []
              while k < 3
                if images[k] != nil then
                  image[k] = images[k]
                else
                  image[k] = ""
                end
                k += 1
              end

              logger.debug(title)
              logger.debug(item_id)
              logger.debug(price)
              logger.debug(tags)
              logger.debug(condition)
              logger.debug(delivery)
              logger.debug(images)

            rescue => e
              logger.debug(e)
              #商品ページが存在しない場合
              title = "【商品ページなし】"
              item_id = ""
              price = ""
              tags = ""
              condition = ""
              seller_name = ""
              delivery = ""
              k = 0
              image = []
              while k < 3
                image[k] = ""
                k += 1
              end
            end
          else
            #urlが空白
            title = ""
            item_id = ""
            price = ""
            tags = ""
            condition = ""
            seller_name = ""
            delivery = ""
            k = 0
            image = []
            while k < 3
              image[k] = ""
              k += 1
            end
          end

          res[i] = [url,title,item_id,price,tags,condition,seller_name,delivery,image[0][0],image[1][0],image[2][0]]
          process += 1
          if process > maxnum - 1 then
            break
          end
          i += 1
        end
        @result = res
        render json: res
      end
    end
  end

  def upload
    logger.debug("\n\n\n")
    logger.debug("Debug Start!")
    current_email = current_user.email
    user = Account.find_by(email: current_email)
    aws = user.AWSkey
    skey = user.skey
    seller = user.sellerId

    res = params[:data]

    #client = MWS.sellers(
    #  primary_marketplace_id: "A1VC38T7YXB528",
    #  merchant_id: seller,
    #  aws_access_key_id: aws,
    #  aws_secret_access_key: skey
    #)
    client = MWS.feeds(
      primary_marketplace_id: "A1VC38T7YXB528",
      merchant_id: seller,
      aws_access_key_id: aws,
      aws_secret_access_key: skey
    )

    res1 = JSON.parse(res)
    #res1 = [["a","b","c"],[1,2,3],["村上","りえ","ネコ"]]

    logger.debug("Pre Feed Content is \n\n")
    logger.debug(res1)

    kk = 0
    feed_body = ""
    while kk < res1.length
      feed_body = feed_body + res1[kk].join("\t")
      feed_body = feed_body + "\n"
      kk += 1
    end

    new_body = feed_body.encode(Encoding::Windows_31J)

    #return

    logger.debug("Feed Content is \n\n")
    logger.debug(new_body)

    feed_type = "_POST_FLAT_FILE_LISTINGS_DATA_"
    parser = client.submit_feed(new_body, feed_type)
    doc = Nokogiri::XML(parser.body)

    submissionId = doc.xpath(".//mws:FeedSubmissionId", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text

    process = ""
    err = 0
    while process != "_DONE_" do
      sleep(25)
      list = {feed_submission_id_list: submissionId}
      parser = client.get_feed_submission_list(list)
      doc = Nokogiri::XML(parser.body)
      process = doc.xpath(".//mws:FeedProcessingStatus", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text
      logger.debug(doc)
      err += 1
      if err > 1 then
        break
      end
    end


    parser = client.get_feed_submission_result(submissionId)
    doc = Nokogiri::XML(parser.body)
    logger.debug(doc)
    logger.debug("\n\n")
    #submissionId = doc.match(/FeedSubmissionId>([\s\S]*?)<\/Feed/)[1]
    #parser.parse # will return a Hash object

    res = ["test"]
    render json: res
  end

  def set

    if request.post? then
      res = params[:data]
      res = JSON.parse(res)
      ptable = res['price']
      ttable = res['title']
      ftable = res['fixed']
      keytable = res['keyword']

      current_email = current_user.email

      temp = Setting.find_by(email:current_email)
      logger.debug("Account is search!!\n\n")
      logger.debug(Setting.select("price"))
      if temp != nil then
        logger.debug("Account is found!!!")
        user = Setting.find_by(email:current_email)
        user.update(fixed: ftable, keyword: keytable, title: ttable, price: ptable )
        user.save
      else
        user = Setting.create(
          email: current_user.email,
          fixed: ftable,
          keyword: keytable,
          price: ptable,
          title: ttable,
        )

      end
    else
      logger.debug("Access is GET")
      current_email = current_user.email
      temp = Setting.find_by(email:current_email)
      if temp != nil then
        logger.debug("Account is found")
        user = Setting.find_by(email:current_email)
        pt = user.price
        kt = user.keyword
        tt = user.title
        ft = user.fixed
        if pt.length < 500 then
          for num in pt.length..500 do
            pt[num] = [num * 500,2980+num * 500]
            kt[num] = ["","","","",""]
            tt[num] = ["",""]
            ft[num] = ["","",""]
          end
        end
        data = {price: pt, title: tt, keyword: kt, fixed: ft}
        logger.debug(data)
        gon.udata = data
      else
        pt = []
        kt = []
        tt = []
        ft = []

        for num in 0..500 do
          pt[num] = [num * 500,2980+num * 500]
          kt[num] = ["","","","",""]
          tt[num] = ["",""]
          ft[num] = ["","",""]
        end

        rnum = 100;

        ft[0][0] = "feed_product_type"
        ft[1][0] = "quantity"
        ft[2][0] = "recommended_browse_nodes"
        ft[3][0] = "fulfillment_latency"
        ft[4][0] = "condition_type"
        ft[5][0] = "condition_note"
        ft[6][0] = "standard_price_points"
        ft[0][1] = "商品タイプ"
        ft[1][1] = "数量"
        ft[2][1] = "推奨ブラウズノード番号"
        ft[3][1] = "出荷作業日数"
        ft[4][1] = "商品のコンディション"
        ft[5][1] = "商品のコンディション説明"
        ft[6][1] = "ポイント（販売価格に対するパーセントを記入）"

        data = {price: pt, title: tt, keyword: kt, fixed: ft}
        gon.udata = data
      end
    end
    logger.debug(user)

  end

  def set_csv

    current_email = current_user.email

    temp = Setting.find_by(email:current_email)
    if temp != nil then
      logger.debug("Account is found!!!")
      user = Setting.find_by(email:current_email)
      ttable = user.title
      ptable = user.price
      ftable = user.fixed
      ktable = user.keyword
      data = {title: ttable, price: ptable, fixed: ftable, keyword: ktable}
      logger.debug("OK start")
      logger.debug(data)
      render json: data
    else
      data = {fixed: ["none"]}
      render json: data
    end

  end

  def output
    res = params[:data]
    res = JSON.parse(res)
    send_data(res, filename: "test.csv", type: :csv)
  end


  def login_check
    @user = current_user
  end


  def regist
    if request.post? then
      user = params[:user]
      password = params[:password]
      #ulevel = params[:ulevel]
      logger.debug("====== Regist from Form =======")
      logger.debug(user)
      logger.debug(password)
      #logger.debug(ulevel)
      tuser = User.find_or_initialize_by(email: user)
      if tuser.new_record? # 新規作成の場合は保存
        tuser = User.create(email: user, password: password)
      end
      tuser = Account.find_or_create_by(email: user)
      #tuser.update(user_level: ulevel)
      logger.debug("====== Regist from Form End =======")
    end
    redirect_to items_get_path
  end

  private def CCur(value)
    res = value.gsub(/\,/,"")
    res = res.gsub(/円/,"")
    return res
  end

end
