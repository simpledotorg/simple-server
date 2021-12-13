class MyFacilitiesDownloadMailer < ApplicationMailer
  def my_facilities_mail
    mail(to: "cpena.intern@resolvetosavelives.org", subject: "test test test")
  end
end
