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
    ob_start();echo '<select>
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
';return ob_get_clean();
}
?>