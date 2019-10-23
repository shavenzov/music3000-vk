import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

import flashx.textLayout.conversion.TextConverter;

private function onShow() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
	
	var str : String = 'Истек срок действия <b>PRO</b> режима.<br>Для дальнейшего использования всех преимуществ режима <b>PRO</b> просто подключи его!';
	caption.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
}

private function onCloseClick() : void
{
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}

private function onProClick() : void
{
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.PRO_ADVANTAGES, null, initializedAction.fromIndex, initializedAction.fromState ) );
}