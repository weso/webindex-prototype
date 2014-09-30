<?php return function ($in, $debugopt = 1) {
    $cx = array(
        'flags' => array(
            'jstrue' => false,
            'jsobj' => false,
            'spvar' => false,
            'prop' => false,
            'method' => false,
            'mustlok' => false,
            'mustsec' => false,
            'debug' => $debugopt,
        ),
        'helpers' => array(),
        'blockhelpers' => array(),
        'hbhelpers' => array(),
        'partials' => array(),
        'scopes' => array($in),
        'sp_vars' => array(),

    );
    ob_start();echo '<!DOCTYPE HTML>
<html>
  <head>
    <meta content="width=device-width" name="viewport" />
    <title>The Web Index</title>
    <script src="../js/libraries/wesCountry.min.js"></script>
  </head>
  <body>
    <select id="indicator-select">
      ',LCRun3::sec($cx, ((isset($in['indicators']) && is_array($in)) ? $in['indicators'] : null), $in, false, function($cx, $in) {echo '
       <option value="',htmlentities((string)((isset($in['indicator']) && is_array($in)) ? $in['indicator'] : null), ENT_QUOTES, 'UTF-8'),'">',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
       <optgroup label="&nbsp;---------------">
         ',LCRun3::sec($cx, ((isset($in['children']) && is_array($in)) ? $in['children'] : null), $in, false, function($cx, $in) {echo '
            <option value="',htmlentities((string)((isset($in['indicator']) && is_array($in)) ? $in['indicator'] : null), ENT_QUOTES, 'UTF-8'),'">',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
            <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;---------------">
            ',LCRun3::sec($cx, ((isset($in['children']) && is_array($in)) ? $in['children'] : null), $in, false, function($cx, $in) {echo '
               <option value="',htmlentities((string)((isset($in['indicator']) && is_array($in)) ? $in['indicator'] : null), ENT_QUOTES, 'UTF-8'),'">&nbsp;&nbsp;&nbsp;&nbsp;',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
               <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;---------------------------------------------">
                 ',LCRun3::sec($cx, ((isset($in['children']) && is_array($in)) ? $in['children'] : null), $in, false, function($cx, $in) {echo '
                    <option value="',htmlentities((string)((isset($in['indicator']) && is_array($in)) ? $in['indicator'] : null), ENT_QUOTES, 'UTF-8'),'">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
                 ';}),'
               </optgroup>
            ';}),'
          </optgroup>
         ';}),'
       </optgroup>
      ';}),'
    </select>

    <select id="area-select">
      ',LCRun3::sec($cx, ((isset($in['areas']) && is_array($in)) ? $in['areas'] : null), $in, false, function($cx, $in) {echo '
       <option value="',htmlentities((string)((isset($in['iso3']) && is_array($in)) ? $in['iso3'] : null), ENT_QUOTES, 'UTF-8'),'">',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
       <optgroup label="&nbsp;---------------">
         ',LCRun3::sec($cx, ((isset($in['countries']) && is_array($in)) ? $in['countries'] : null), $in, false, function($cx, $in) {echo '
            <option value="',htmlentities((string)((isset($in['iso3']) && is_array($in)) ? $in['iso3'] : null), ENT_QUOTES, 'UTF-8'),'">',htmlentities((string)((isset($in['name']) && is_array($in)) ? $in['name'] : null), ENT_QUOTES, 'UTF-8'),'</option>
         ';}),'
       </optgroup>
      ';}),'
    </select>

    <select id="year-select">
      ',LCRun3::sec($cx, ((isset($in['years']) && is_array($in)) ? $in['years'] : null), $in, true, function($cx, $in) {echo '
       <option>',htmlentities((string)((isset($in['value']) && is_array($in)) ? $in['value'] : null), ENT_QUOTES, 'UTF-8'),'</option>
      ';}),'
    </select>

    <script src="../js/data.js"></script>
  </body>
</html>
';return ob_get_clean();
}
?>