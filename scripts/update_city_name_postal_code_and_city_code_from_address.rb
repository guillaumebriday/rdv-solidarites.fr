# frozen_string_literal: true

require "csv"

API_ENDPOINT = "https://api-adresse.data.gouv.fr/search/csv/"

def update_user_city_name_from(geocoded_addresses)
  puts "#{geocoded_addresses.length} ville(s) d'usager à mettre à jour"
  geocoded_addresses.each do |id, city_data|
    User.find(id).update_columns(city_data)
  end
end

def geocode(file)
  response = Typhoeus.post(
    API_ENDPOINT,
    method: :post,
    body: { data: File.new(file) }
  )
  geocoded_addresses = {}
  CSV.parse(response.body, headers: true).map do |line|
    geocoded_addresses[line[0]] = {
      city_name: line[12],
      post_code: line[11],
      city_code: line[14]
    }
  end
  geocoded_addresses
end

def addresses_in_csv
  file = Tempfile.create("bla.csv")
  CSV.open(file, "wb") do |csv|
    csv << %w[id adresse]
    User.where.not(address: [nil, ""]).where(city_name: [nil, ""]).in_batches(of: 500).each_with_index do |users, index|
      Rails.logger.info("Récupère l'ensemble d'utilisateurs du batch #{index}")
      users.map { |u| [u.id, u.address] }.each { |ia| csv << ia }
    end
  end
  file
end

puts "mise à jour du nom de ville de l'usager à partir de son adresse"
puts ""

update_user_city_name_from geocode addresses_in_csv

puts "Terminé"
