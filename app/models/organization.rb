# == Schema Information
# Schema version: 9
#
# Table name: organizations
#
#  id         :integer(11)     not null, primary key
#  name       :string(255)     
#  key        :string(255)     
#  timezone   :string(255)     
#  created_at :datetime        
#  updated_at :datetime        
#  location   :string(255)     
#

class Organization < ActiveRecord::Base
  tz_time_attributes :created_at, :updated_at
  
  has_many :people, :dependent => :destroy

  validates_presence_of :name, :key, :timezone
  validates_length_of :name, :within => 3..40,    :unless => proc { |organization| organization.errors.on :name }
  validates_uniqueness_of :key,                   :unless => proc { |organization| organization.errors.on :key }
  validates_length_of :key, :within => 3..20,     :unless => proc { |organization| organization.errors.on :key }
  validates_format_of :key, :with => /\A\w+\Z/i,  :unless => proc { |organization| organization.errors.on :key }
  validate :validate_timezone

  acts_as_authorizable
  
  def initialize(attributes=nil)
    super(attributes)
    self[:timezone] ||= 'Pacific Time (US & Canada)'
  end

  def member_count
    @member_count ||= Service.for_organization(self).end_after(Date.yesterday).for_service_types(ServiceType[:membership].id).paginate(:size => 0).size
  end

  def last_visit
    @last_visit ||= Visit.for_organization(self).paginate(:size => 1).to_a.first
  end

  private

  def validate_timezone
    if !errors.on(:timezone)
      errors.add :timezone if !TimeZone[self.timezone]
    end
  end
end
