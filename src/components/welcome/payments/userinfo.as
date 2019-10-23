import classes.api.MainAPI;
import classes.api.MainAPIImplementation;
import classes.api.data.UserInfo;
import classes.api.events.UserEvent;
import classes.api.social.vk.VKApi;

import com.utils.ConjugationUtils;
import com.utils.DateUtils;

import components.managers.HintManager;
import components.welcome.NavigatorContent;
import components.welcome.Slides;
import components.welcome.events.GoToEvent;

import mx.containers.ViewStack;

private var api : MainAPIImplementation;

public var viewStack : ViewStack;

private function initialization() : void
{
	coinsText.setStyle( 'toolTipPlacement', 'errorTipBelow' );
	coinsText.toolTip = 'Щелкни для пополнения количества монет';
	
	pro_info.setStyle( 'toolTipPlacement', 'errorTipBelow' );
	
	face.url      = VKApi.userInfo.photo_50;
	userName.text = VKApi.userFullName;
	
	updateInfo( api.userInfo );
}

private function updateInfo( info : classes.api.data.UserInfo ) : void
{
	face.pro      = info.pro;
	
	coins.text = info.money.toString();
	pro_info.text = info.pro ? 'PRO режим до ' + DateUtils.format( info.pro_expired, false ) : 'Подключить режим PRO';
	pro_info.toolTip = info.pro ? 'Щелкни для продления режима PRO' : 'Щелкни для подключеня режима PRO';
}

private function goTo( slideIndex : int ) : void
{
	var cSlide : NavigatorContent = NavigatorContent( viewStack.selectedChild );
	var evt    : GoToEvent = new GoToEvent( GoToEvent.GO, slideIndex, null );
	    
	if ( cSlide.groupIndex == 1 )
	{
		evt.fromIndex = cSlide.initializedAction.fromIndex;
		evt.fromState = cSlide.initializedAction.fromState;
	}
	
	dispatchEvent( evt );
}

private function onProInfoClick() : void
{
	goTo( Slides.PRO_ADVANTAGES );
}

private function onCoinsClick() : void
{
	goTo( Slides.BUY_COINS );
}

private function onUserInfoUpdated( e : UserEvent ) : void
{
	updateInfo( e.userInfo );
	
	if ( e.lastUserInfo )
	{
		//Показываем всплывающую подсказку, если количество монет прибавилось
		if ( e.moneyIncremented )
		{
			var incCount : int = e.moneyAdded;
			HintManager.show( 'Твой счет пополнился на ' + incCount.toString() + ' ' + ConjugationUtils.formatCoins2( incCount ), false, coinsText, true, 10000, false ); 
		}
	}
}

private function onAddedToStage() : void
{
	ApplicationModel.userInfo = this;
	
	api = MainAPI.impl;
	api.addListener( UserEvent.UPDATE, onUserInfoUpdated, this );
}

private function onRemovedFromStage() : void
{
	ApplicationModel.userInfo = null;
	
	api.removeAllObjectListeners( this );
}