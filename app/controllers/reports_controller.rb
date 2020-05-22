class ReportsController < ApplicationController
  layout "reports"
  def index
    data = [
      { value: 0, date: "Jan 2017" },
      { value: 50, date: "Feb 2017" },
      { value: 125, date: "Mar 2017" },
      { value: 170, date: "Apr 2017" },
      { value: 210, date: "May 2017" },
      { value: 260, date: "Jun 2017" },
      { value: 300, date: "Jul 2017" },
      { value: 310, date: "Aug 2017" },
      { value: 350, date: "Sep 2017" },
      { value: 370, date: "Oct 2017" },
      { value: 400, date: "Nov 2017" },
      { value: 425, date: "Dec 2017" },
    ]
  end
end
