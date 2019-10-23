import classes.api.MainAPI;
import classes.api.MainAPIImplementation;
import classes.api.events.UserEvent;
import classes.api.social.vk.APIConnection;
import classes.api.social.vk.VKApi;
import classes.api.social.vk.events.CustomEvent;

import com.utils.ConjugationUtils;

import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

import mx.events.CloseEvent;

private static const DEFAULT_COINS : uint = 90;

private var vk  : APIConnection;
private var api : MainAPIImplementation;

private function setInitialState() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
}

private function onContentCreationComplete() : void
{
	vk = VKApi.impl;
	api = MainAPI.impl;
}

private function onShow() : void
{
	setInitialState();
	
	if ( initializedAction.other )
	{
		coins.value = initializedAction.other;
	}
	else
	{
		coins.value = DEFAULT_COINS;
	}
	
	coinsChange();
}

private function coinsChange() : void
{
	votes.text = coins.value.toString();
	coinsSymbol.toolTip = coins.value.toString() + ' ' + ConjugationUtils.formatCoins( coins.value );
	votesSymbol.toolTip = votes.text + ' ' + ConjugationUtils.formatVKVoices( coins.value );
}

private function setLoadingState( value : Boolean ) : void
{
	if ( value )
	{
		currentState = 'loading';
	}
	else
	{
		setInitialState();
	}
	
	ApplicationModel.userInfo.enabled = ! value;
}

private function buyCoinsClick() : void
{
	ApplicationModel.exitFromFullScreen();
	
	setLoadingState( true );
	
	api.addListener( UserEvent.UPDATE, onInfoUpdated, this, 1000 );
	
	vk.addListener( 'onOrderCancel', onOrderResult, this );
	vk.addListener( 'onOrderSuccess', onOrderResult, this );
	vk.addListener( 'onOrderFail',  onOrderResult, this );
	
	vk.callMethod( 'showOrderBox', { type : 'item', item : 'coins_' + coins.value.toString() } );
}

private function onInfoUpdated( e : UserEvent ) : void
{
	//Если увеличилось количество монет
	if ( e.moneyIncremented )
	{
		api.removeAllObjectListeners( this );
		setLoadingState( false );
		dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.COINS_ADDED, null, initializedAction.fromIndex, initializedAction.fromState, e.moneyAdded ) );
	    e.lastUserInfo = null; //Устанавливаем это св-во в null, что-бы не всплыли другие оповещалки или подсказки этого события 
	}
}

private function onOrderResult( e : CustomEvent ) : void
{
	vk.removeAllObjectListeners( this );
	
	if ( e.type == 'onOrderSuccess' )
	{
		api.touch();
		return;
	}
	
	api.removeAllObjectListeners( this );
	setLoadingState( false );
}

private function getFreeCoins() : void
{
	ApplicationModel.exitFromFullScreen();
	vk.callMethod( 'showOrderBox', { type : 'offers', currency : '1' } );
}

private function onCloseClick() : void
{
	dispatchEvent( new BackEvent( BackEvent.BACK ) );
}