FactoryBot.define do
  factory :address do
    street { "123 Main St" }
    city { "Anytown" }
    state { "CA" }
    zip { "12345" }
  end
end
