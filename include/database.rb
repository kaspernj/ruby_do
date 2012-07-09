class Ruby_do::Database
  SCHEMA = {
    "tables" => {
      "Plugin" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "name", "type" => "varchar"},
          {"name" => "classname", "type" => "varchar"},
          {"name" => "active", "type" => "enum", "maxlength" => "'0','1'", "default" => 0}
        ],
        "indexes" => [
          "name",
          "classname"
        ]
      }
    }
  }
end