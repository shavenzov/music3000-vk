import classes.api.MainAPI;
import classes.api.MainAPIImplementation;
import classes.api.errors.APIError;
import classes.api.events.ProTariffsEvent;
import classes.api.events.SwitchedOnProModeEvent;
import classes.api.events.UserEvent;

import components.managers.HintManager;
import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

import flash.utils.clearTimeout;
import flash.utils.setTimeout;

import flashx.textLayout.conversion.TextConverter;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.managers.ToolTipManager;
import mx.utils.ObjectUtil;

import spark.events.IndexChangeEvent;

private var api : MainAPIImplementation;

private function setInitialState() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
}

private var tariffs : Array;

private function onGotTariffs( e : ProTariffsEvent ) : void
{
	api.removeListener( ProTariffsEvent.PRO_TARIFFS, onGotTariffs );
	ApplicationModel.userInfo.enabled = true;
	
	tariffs = e.tariffs;
	
	for ( var i : int = 0; i < tariffs.length; i ++ )
	{
		tariffs[ i ].fromIndex = initializedAction.fromIndex;
		tariffs[ i ].fromState = initializedAction.fromState;
		tariffs[ i ].time      = e.time;
	}
	
	updateAfterGetTarifs();
	
	setInitialState();
}

private function updateAfterGetTarifs( justRefresh : Boolean = false ) : void
{
	indicator.label = api.userInfo.pro ? 'Продлеваю...' : 'Подключаю...';
	
	var optimalTariffIndex : int = getOptimalTariffIndex( tariffs );
	
	if ( ! justRefresh )
	{
		prices.dataProvider  = new ArrayCollection( tariffs );
	}
	
	prices.selectedIndex = optimalTariffIndex;
	
	if ( optimalTariffIndex == -1 ) //Денег не достаточно
	{
		var str : String = 'Недостаточно монет для ' + ( api.userInfo.pro ? 'продления' : 'подключения' ) + ' режима <b>PRO</b>!';
		
		notEnoughCouns.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
		
		timeOutId = setTimeout( showBuyTip, 2000 );
	}
	
	addButton.visible = addButton.includeInLayout = optimalTariffIndex != -1;
	buyButton.visible = buyButton.includeInLayout = ! addButton.visible;
	notEnoughCoinsContainer.visible = notEnoughCoinsContainer.includeInLayout = buyButton.visible;
}

private var timeOutId : uint = 0;

private function showBuyTip() : void
{
	timeOutId = 0;
	HintManager.show( buyButton.toolTip, false, buyButton, false, 10000 ); 
}

private function clearTimeOut() : void
{
	if ( timeOutId != 0 )
	{
		clearTimeout( timeOutId );
	}
}

private function onShow() : void
{
	setInitialState();
	
	api = MainAPI.impl;
	
	caption.text    = api.userInfo.pro ? 'Продление режима' : 'Подключение режима';
	addButton.label = api.userInfo.pro ? 'Продлить' : 'Подключить';
	
	if ( ! tariffs )
	{
		currentState = 'loading';
		ApplicationModel.userInfo.enabled = false;
		api.addListener( ProTariffsEvent.PRO_TARIFFS, onGotTariffs, this );
		api.getProTariffs();
		return;
	}
	
	updateAfterGetTarifs( true );
}

private function getOptimalTariffIndex( tariffs : Array ) : int
{
	for ( var i : int = tariffs.length - 1; i >= 0; i -- )
	{
		if ( api.userInfo.money >= tariffs[ i ].price )
		 return i;	
	}
	
	return -1;
}

private function onSwitchedOnProMode( e : SwitchedOnProModeEvent ) : void
{
	api.removeListener( SwitchedOnProModeEvent.SWITCHED_ON, onSwitchedOnProMode );
	
	if ( e.error )
	{
		api.removeListener( UserEvent.UPDATE, onInfoUpdated );
		ApplicationModel.userInfo.enabled = true;
		setInitialState();
		
		if ( e.errorCode == APIError.NOT_ENOUGH_MONEY )
		{
			Alert.showError( 'Недостаточно монет для выполнения операции.' );
		}
		else
		if ( e.errorCode == APIError.PRICE_INDEX_NOT_EXISTS )
		{
			Alert.showError( 'Выбранная опция недоступна.' );
		}	
	}
}

private function onInfoUpdated( e : UserEvent ) : void
{
	ApplicationModel.userInfo.enabled = true;
	api.removeListener( UserEvent.UPDATE, onInfoUpdated );
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.PRO_MODE_ACTIVATED, e.userInfo.pro && ( ! e.lastUserInfo.pro ) ? "proActivated" : "proProlongation", 
		                          initializedAction.fromIndex, initializedAction.fromState ) ); 
	
}

private function onSwitchOnProModeClick() : void
{
	HintManager.hideAll();
	ApplicationModel.userInfo.enabled = false;
	currentState = 'loading';
	
	api.addListener( SwitchedOnProModeEvent.SWITCHED_ON, onSwitchedOnProMode, this );
	api.addListener( UserEvent.UPDATE, onInfoUpdated, this );
	api.switchOnProMode( prices.selectedIndex );
	api.touch();
}

private function onTableChanging( e : IndexChangeEvent ) : void
{
	if ( e.newIndex == -1 ) return;
	
	//Если денег для подключения выбранного тарифа не достаточно, то выбрать этот тариф нельзя
	if ( tariffs[ e.newIndex ].price > api.userInfo.money )
	{
		e.preventDefault();
	}
}

private function clear() : void
{
	clearTimeOut();
	HintManager.hideAll();
}

private function onBuyClick() : void
{
	clear();
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.BUY_COINS, null, initializedAction.fromIndex, initializedAction.fromState ) );
}

private function onCloseClick() : void
{
	clear();
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}

private function onHide() : void
{
	clear();
}