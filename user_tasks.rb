require './intercom_client'
require "csv"

class UserTasks < IntercomClient
  def initialize()
  end

  def find_user(criteria)
    begin
      #Check for users via the unique ID
      user = @@intercom.users.find(:id => criteria)
    rescue Intercom::ResourceNotFound
      begin
        #Check for users via user id if we receive not found error
        user = @@intercom.users.find(:user_id=> criteria)
      rescue Intercom::ResourceNotFound
        #Check for users via email address
        user = @@intercom.users.find(:email => criteria)
      end
    end
  end

  def delete_user(criteria)
    #delete user using either email, user id or id
    user = find_user(criteria)
    deleted_user = @@intercom.users.delete(user)
  end

  def update_customer_attrib(criteria, attrib, value)
    #Create new custom attributes for a user or update existing ones
    #1/ Find the user first
    user = find_user(criteria)
    # Set/Update the relevant Attribute
    user.custom_attributes[attrib] = value
    # Save the resultant change
    intercom.users.save(user)
  end

  def create_user(args)
    #Create a new user with list of values passed on setup
    user = @@intercom.users.create(args)
  end

  def show_attrib(criteria, attrib )
    begin
      #First we check whether this is a standard attribute
      user = find_user(criteria)
      user.send(attrib.to_sym)
    rescue Intercom::AttributeNotSetError
      begin
        #If we cannot find it is a standard attribute lets check if it is a customer attribute
        user.custom_attributes[attrib]
      end
    end
  end

  def bulk_delete(*tag)
    case attrib.length
      when 0
        emails = @@intercom.users.all.map {|user| user.email }
        email_array = emails.collect{|e|{'email'.to_sym => e}}
        @@intercom.users.submit_bulk_job(delete_items: email_array)
      when 1
        emails = @@intercom.users.all.map do |user|
          user.tags.each {|val| user.email if val.include?(tag)}
        end
      else
        puts("Only one tag please!")
    end
  end

  def bulk_create(csv_file)
    #Check to make sure the CSV file eixsts
    if File.exist?(csv_file)
      file = File.open(csv_file, "rb")
      body = file.read

      #Need to add to the CSV model to handle empty fields
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.empty? ? nil : field
      end
      csv = CSV.new(body, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil])
      csv_data = csv.to_a.map {|row| row.to_hash }

      @@intercom.users.submit_bulk_job(create_items: csv_data )
    else
      puts("No CSV file found")
    end
  end
end

