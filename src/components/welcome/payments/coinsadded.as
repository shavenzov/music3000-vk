import classes.api.MainAPI;
import classes.api.MainAPIImplementation;

import com.utils.ConjugationUtils;

import components.managers.HintManager;
import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

import flashx.textLayout.conversion.TextConverter;

private function setInitialState() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
}

private var api : MainAPIImplementation;

private function onShow() : void
{
	api = MainAPI.impl;
	
	setInitialState();
	
	var str : String = 'Твой счет пополнился на <br><b>' + initializedAction.other.toString() + ' ' + ConjugationUtils.formatCoins2( initializedAction.other ) + '</b>.'; 
	
	caption.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
	
	addButton.label = api.userInfo.pro ? 'Продлить' : 'Подключить';
	addButton.toolTip = 'Щелкни для ' + ( api.userInfo.pro ? 'продления' : 'подключения' ) + ' режима PRO';
	
	timeOutId = setTimeout( showBuyTip, 2000 );
}

private var timeOutId : uint = 0;

private function showBuyTip() : void
{
	timeOutId = 0;
	HintManager.show( addButton.toolTip, false, addButton, false, 10000, false ); 
}

private function clearTimeOut() : void
{
	if ( timeOutId != 0 )
	{
		clearTimeout( timeOutId );
	}
}

private function clear() : void
{
	clearTimeOut();
	HintManager.hideAll();
}

private function onCloseClick() : void
{
	clear();
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}

private function onProClick() : void
{
	clear();
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.ADD_PRO_MODE, null, initializedAction.fromIndex, initializedAction.fromState ) );
}

private function onHide() : void
{
	clear();
}