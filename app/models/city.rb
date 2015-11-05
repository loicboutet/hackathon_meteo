class City < ActiveRecord::Base
 geocoded_by :name
 after_validation :geocode

 validates_presence_of :name

 TIME_IN_CACHE = 1.minute

 def weather
  need_to_update_api
  self.read_attribute(:weather)
 end

 def tide
  need_to_update_api
  self.read_attribute(:tide)
 end

 private

 # we do not want to query the API each time the tide or weather is called (in the view each time a user call the index page for example)
 # because it would be very slow and we would make a LOT of calls to the API which would not be very nice to them
 # so we store the results in attributes, and we check wether the last time we called the API was more than TIME_IN_CACHE ago
 def need_to_update_api
  if api_updated.blank? || api_updated < Time.now - TIME_IN_CACHE
    update_api
  end
 end

 def update_api
  self.weather = update_weather
  self.tide = update_tide
  self.api_updated = Time.now
  self.save
 end


 # calling the forecast API
 def update_weather
  begin
    forecast = ForecastIO.forecast(latitude, longitude)
    forecast.currently.icon
  rescue => e
    return "unknown"
  end
 end

 # calling the opendatasoft API
 def update_tide
  uri = URI.parse("http://shom.opendatasoft.com/api/records/1.0/search?dataset=references-altimetriques-maritimes0&rows=1&facet=zone&facet=rf&facet=organisme&facet=reference&geofilter.distance=#{latitude}%2C#{longitude}%2C20000")
  response = Net::HTTP.get_response(uri)
  json_data = JSON.parse(response.body)
  if json_data["records"].present?
    pmve = json_data["records"].first["fields"]["pmve"]
    bmve = json_data["records"].first["fields"]["bmve"]
    coef = (pmve - bmve)/6.1 # function to calculate the tide as given by Lucy
    return coef
  else
    return 0
  end
 end

end
