class ModelCorona {
  Coordinate coordinate;
  String country;
  String countryCode;
  int id;
  String lastUpdated;
  Latest latest;
  String province;
  ModelCorona.fromJson(Map<String, dynamic> map)
      : coordinate = Coordinate.fromJson(map["coordinates"]),
        country = map["country"],
        countryCode = map["country_code"],
        id = map["id"],
        lastUpdated = map["last_updated"],
        latest = Latest.fromJson(map["latest"]),
        province = map["province"];
}

class Coordinate {
  String latitude;
  String longitude;
  Coordinate({this.latitude, this.longitude});
  Coordinate.fromJson(Map<String, dynamic> map)
      : latitude = map["latitude"],
        longitude = map["longitude"];
}

class Latest {
  int confirmed;
  int deaths;
  int recovered;
  Latest({this.confirmed, this.deaths, this.recovered});
  Latest.fromJson(Map<String, dynamic> map)
      : confirmed = map["confirmed"],
        deaths = map["deaths"],
        recovered = map["recovered"];
}
