module PowerBI
  class Capacity < Object

    def initialize(tenant, parent, id = nil)
      super(tenant, id)
    end

    def get_data(id)
      @tenant.get("/capacities", {'$filter': "id eq #{id}"})[:value].first
    end

    def data_to_attributes(data)
      {
        id: data[:id],
        display_name: data[:displayName],
        sku: data[:sku],
        state: data[:state],
        region: data[:region],
        capacity_user_access_right: data[:capacityUserAccessRight],
        admins: data[:admins],
      }
    end

  end

  class CapacityArray < Array
    def self.get_class
      Capacity
    end

    def get_data
      @tenant.get("/capacities")[:value]
    end
  end
end