module CreateMachineUser
  def self.create(name, organization_id)
    organization = Organization.find_by(id: organization_id)
    MachineUser.create!(name: name, organization: organization)
  end
end
