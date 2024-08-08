FactoryBot.define do
  factory :driver do
    association :home_address, factory: :address
  end
end
