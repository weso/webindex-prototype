<?php
  class DataModel {
    function DataModel($settings) {
      $this->settings = $settings;
    }

    function get() {
      $api = $this->settings->api_url;

      $indicators = json_decode(file_get_contents($api . "/indicators/INDEX"), true);

      $data = Array();

      if ($indicators["success"] == true)
        $data["indicators"] = $indicators["data"];

      return $data;
    }
  }
