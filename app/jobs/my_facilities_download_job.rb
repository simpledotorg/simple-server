class MyFacilitiesDownloadJob < ApplicationJob
  queue_as :default
# *args = recipient_email, 
  def perform
    # Do something later
   MyFacilitiesDownloadMailer.my_facilities_mail.deliver_now
  end
end
