class VacationsController < ApplicationController

  before_filter :authenticate_user!, :except=>

      # GET /vacations
  def index
    #Populates the calendar, so restricted by manager
    @vacations = Vacation.team_holidays current_user.manager_id
    @vacation = Vacation.new

    @holiday_statuses = HolidayStatus.pending_only

    respond_to do |format|
      format.html
      format.json {
        holidays_json = Vacation.holidays_as_json params[:start], params[:end]
        render :json => holidays_json
      }
    end
  end

  # GET /vacations/1
  def show
    @vacation = Vacation.find(params[:id])

    respond_to do |format|
      format.html # index.html.erb
      format.json do |json|
      end
    end
  end

#
#  # GET /vacations/new
#  # GET /vacations/new.xml
#  def new
#    @vacation = Vacation.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @vacation }
#    end
#  end

  # GET /vacations/1/edit
#  def edit
#    @vacation = Vacation.find(params[:id])
#    @holiday_statuses = HolidayStatus.all
#
#    unless current_user.user_type != UserType.find_by_name("Manager")
#      @holiday_statuses.reject! { |status| status.status != "Pending" }
#    end
#
#  end

  # POST /vacations
  # POST /vacations.xml
  def create
    @vacation = Vacation.new(params[:vacation])
    @vacation.user = current_user
    @vacation.holiday_status_id = 1
    manager_id = current_user.manager_id
    @vacation.manager_id = manager_id # Add manager to all holidays
    manager = User.find_by_id(manager_id)

    respond_to do |format|
      if @vacation.save
        unless manager.nil?
          HolidayMailer.holiday_actioned(current_user, manager, @vacation).deliver
#          HolidayMailer.holiday_request(current_user, manager, @vacation).deliver
        end
        #TODO check the mailer was successful
        flash[:notice] = "Successfully created holiday."
        format.js
      else
        flash[:notice] = "Problem creating the holiday"
        format.js
      end
    end
  end

  # PUT /vacations/1
  # PUT /vacations/1.xml
=begin
  def update
    @row_id = params[:id]
    @vacation = Vacation.find(params[:id])
    @vacation.user = current_user
    holiday_status_id = params[:vacation][:holiday_status_id]
    manager = User.find_by_id(@vacation.manager_id)

    respond_to do |format|
      if holiday_status_id == "3" # cancelled

        if @vacation.holiday_status_id==1
          unless manager.nil?
            HolidayMailer.holiday_cancellation(current_user, manager, @vacation).deliver
          end
        end

        @vacation.destroy
        flash[:notice] = "Cancelled holiday was deleted"
        format.js {
          render 'delete_row.js.erb'
        }
      else
        if @vacation.update_attributes(params[:vacation])
          unless manager.nil?
            HolidayMailer.holiday_amendment(current_user, manager, @vacation).deliver
          end
          flash[:notice] = "Successfully changed your holiday."
          format.js
        else
          flash[:notice] = "Problem changing the holiday"
          format.js { render 'delete_row.js.erb' }
        end
      end
    end
  end

=end

  # DELETE /vacations/1
  # DELETE /vacations/1.xml
  def destroy
    @vacation = Vacation.find(params[:id])

    manager = User.find_by_id(@vacation.manager_id)

    respond_to do |format|
      if @vacation.destroy
        unless manager.nil?
          HolidayMailer.holiday_cancellation(current_user, manager, @vacation).deliver
        end
        @row_id = params[:id]
        flash[:notice] = "Holiday deleted"
        @failed = false
        format.js
      else
        flash[:notice] = "Could not delete a holiday which has passed"
        @failed = true
        format.js
      end
    end
  end

end
