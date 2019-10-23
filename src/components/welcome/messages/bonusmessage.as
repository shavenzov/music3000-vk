import classes.api.MainAPI;
import classes.api.data.MessageType;
import classes.api.events.MessageEvent;

import components.welcome.events.BackEvent;

import flashx.textLayout.conversion.TextConverter;

/**
 * Список простых сообщений которые необходимо отобразить 
 */
private var messages : Array;
/**
 * Текущее отображаемое сообщение 
 */
private var currentMessage : Object;

private function setInitialState() : void
{
	currentState = initializedAction.fromIndex == -1 ? 'fromOther' : 'fromMenu';
}

private function onNewMessages( e : MessageEvent ) : void
{
  messages = messages.concat( e.messages );
  e.stopImmediatePropagation();
}

private function onHide() : void
{
	MainAPI.impl.removeAllObjectListeners( this );
}

private function onShow() : void
{
	MainAPI.impl.addListener( MessageEvent.MESSAGE, onNewMessages, this, 1000 );
	
	setInitialState();
	messages = ( initializedAction.other as Array ).slice();
	currentMessage = getMessage();
	updateDialog();
}

private function getMessage() : Object
{
	return messages.length > 0 ?  messages.shift() : null;
}

private function updateDialog() : void
{	
	if ( currentMessage.type == MessageType.FRIEND_INVITED )
	{
		image.source = Assets.FRIEND_INVITED_ICON;
	}
	else
	{
		image.source = Assets.OK_ICON_BIG;
	}
	
	coins.text = currentMessage.money;
	caption.textFlow = TextConverter.importToFlow( currentMessage.message, TextConverter.TEXT_FIELD_HTML_FORMAT );
}

private function onCloseClick() : void
{
	currentMessage = getMessage();
	
	if ( currentMessage )
	{
		updateDialog();
	}
	else
	{
		dispatchEvent( new BackEvent( BackEvent.BACK ) );	
	}
}

