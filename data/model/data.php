<?php
  class DataModel {
    function DataModel($settings) {
      $this->settings = $settings;
    }

    function get() {
      $api = $this->settings->api_url;

      $indicators = json_decode(file_get_contents($api . "/indicators/INDEX"), true);

      $areas = json_decode(file_get_contents($api . "/areas/continents"), true);

      $years = json_decode(file_get_contents($api . "/years"), true);

      $data = Array();

      if ($indicators["success"] == true)
        $data["indicators"] = $indicators["data"];

      if ($areas["success"] == true)
        $data["areas"] = $areas["data"];

      if ($years["success"] == true)
        $data["years"] = $years["data"];

      return $data;
    }
  }
