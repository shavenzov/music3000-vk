import classes.api.MainAPI;

import com.utils.DateUtils;

import components.welcome.events.BackEvent;

import flashx.textLayout.conversion.TextConverter;

private function onShow() : void
{
	var str : String = 'Режим <b>PRO</b> ' + ( currentState == 'proActivated' ? 'подключен' : 'продлен' ) + '<br>до ' 
		               + DateUtils.format( MainAPI.impl.userInfo.pro_expired, false ) + '.';
	
	caption.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
}

private function onCloseClick() : void
{
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}