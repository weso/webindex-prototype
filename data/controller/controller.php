<?php
  require('lightncandy/lightncandy.php');

  $element = "data";

  // Get template
  $template = file_get_contents("../view/$element.hbs");

  // Compile template
  $phpStr = LightnCandy::compile($template);

  // Store template
  $compiled = "compiled/$element.c";
  file_put_contents($compiled, $phpStr);
  $renderer = include($compiled);

  // Include model
  require("../model/$element.php");

  // Get settings
  $settings = json_decode(file_get_contents("settings.json"));

  // Get model data
  $className = ucfirst($element) . "Model";
  $modelClass = new ReflectionClass($className);
  $modelObj = $modelClass->newInstanceArgs(array($settings));
  $data = $modelObj->get();

  // Step 3. run native PHP render function any time
  echo $renderer($data);
