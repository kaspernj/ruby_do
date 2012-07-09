class Ruby_do::Database
  SCHEMA = {
    "tables" => {
      "Option" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "title", "type" => "varchar"},
          {"name" => "value", "type" => "text"}
        ],
        "indexes" => [
          "title"
        ]
      },
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