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
          {"name" => "order_no", "type" => "int"},
          {"name" => "active", "type" => "enum", "maxlength" => "'0','1'", "default" => 0}
        ],
        "indexes" => [
          "name",
          "classname",
          "order_no"
        ]
      },
      "Static_result" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "plugin_id", "type" => "int"},
          {"name" => "id_str", "type" => "varchar"},
          {"name" => "title", "type" => "varchar"},
          {"name" => "title_lower", "type" => "varchar"},
          {"name" => "descr", "type" => "text"},
          {"name" => "data", "type" => "text"},
          {"name" => "icon_path", "type" => "text"}
        ],
        "indexes" => [
          "plugin_id",
          "id_str",
          "title",
          "title_lower"
        ]
      }
    }
  }
end