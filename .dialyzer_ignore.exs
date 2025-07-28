[
  # Ignore warnings for common Phoenix patterns
  {"lib/car_park_web/endpoint.ex", :no_return},
  {"lib/car_park_web/router.ex", :no_return},
  {"lib/car_park/application.ex", :no_return},

  # Ignore warnings for Ecto schemas and changesets
  {"lib/car_park/", :call_without_opaque},
  {"lib/car_park/", :no_return},

  # Ignore warnings for LiveView callbacks
  {"lib/car_park_web/live/", :no_return},

  # Ignore warnings for controller actions
  {"lib/car_park_web/controllers/", :no_return},

  # Ignore warnings for test files
  {"test/", :no_return},
  {"test/", :call_without_opaque}
]
