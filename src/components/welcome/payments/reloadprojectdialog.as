import classes.api.MainAPI;

import components.welcome.events.OpenProjectEvent;

import flashx.textLayout.conversion.TextConverter;

private function onShow() : void
{
	ApplicationModel.userInfo.visible = false;
	
	var str : String = 'Сейчас микс <i>' + ApplicationModel.project.info.name + '</i> будет сохранен и открыт заново для продолжения работы ';
	    str += MainAPI.impl.userInfo.pro ? 'в режиме <b>PRO</b>.' : 'в обычном режиме.';
	
	
	caption.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
}

private function onOkClick() : void
{
	dispatchEvent( new OpenProjectEvent( OpenProjectEvent.OPEN, ApplicationModel.project.info ) );
}