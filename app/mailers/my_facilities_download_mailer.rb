class MyFacilitiesDownloadMailer < ApplicationMailer
  def my_facilities_mail
    mail(to: "carloshpena93@gmail.com", subject: "test test test")
  end
end
