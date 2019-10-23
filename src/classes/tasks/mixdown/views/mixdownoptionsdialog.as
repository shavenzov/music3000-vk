import com.audioengine.core.AudioData;
import com.audioengine.core.TimeConversion;
import com.utils.NumberUtils;

import flash.display.DisplayObject;
import flash.events.MouseEvent;

import mx.controls.Button;
import mx.core.IVisualElement;
import mx.core.IVisualElementContainer;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.events.CloseEvent;
import mx.events.FlexEvent;

import classes.Sequencer;
import classes.SequencerImplementation;
import classes.api.MainAPI;
import classes.api.MainAPIImplementation;
import classes.api.PublisherAPI;
import classes.api.social.vk.tasks.PublishAudio;
import classes.tasks.mixdown.MixdownAction;
import classes.tasks.mixdown.events.MixdownOptionsEvent;

import components.controls.LinkButton;
import components.controls.tips.AddProToolTip;
import components.managers.HintManager;
import components.welcome.Slides;

use namespace mx_internal;

private var api         : MainAPIImplementation;
private var seq         : SequencerImplementation;

private var params : Object = new Object();

private function onInit() : void
{
	api         = MainAPI.impl;
	seq         = Sequencer.impl;
}

private function publishSelectedOptionCheckboxClick() : void
{
	if ( publishSelectedOption.selected )
	{
		var playingArea : Object = seq.getLoopArea();
		
		if ( playingArea.length <= PublishAudio.MIN_MUSIC_FRAMES )
		{
			HintManager.show( 'Выбранная область слишком короткая. Выбери большую область и повтори попытку публикации.', true, publishSelectedOption );
			publishSelectedOption.selected = false;
		}
	}
}

private function creationComplete() : void
{
	currentState = 'start';
}

private function onPublishSelectedGroupContentCreated() : void
{
	publishSelectedGroup.visible = publishSelectedGroup.includeInLayout = seq.loop;
}

private function onSelect( e : MouseEvent ) : void
{
	var group : UIComponent = UIComponent( UIComponent( e.currentTarget ).parent );
	
	if ( ! api.userInfo.pro )
	{
		if ( group.name != PublisherAPI.QUALITY_128_K )
		{
			AddProToolTip.show( 'Для публикации в этом качестве необходимо подключить режим PRO.', null, e.currentTarget, this );
			return;
		}
	}
	
	params.quality = group.name;
	
	selectButton( IVisualElementContainer( group.parent ), group.name );	
}

private function getButton( subGroup : IVisualElementContainer ) : Button
{
	var result : Button;
	
	for ( var i : int = 0; i < subGroup.numElements; i ++ )
	{
		var button : Button = subGroup.getElementAt( i ) as Button;
		
		if ( button )
		{
			return button; 
		}
	}
	
	return result;
}

private function selectButton( group : IVisualElementContainer, buttonName : String ) : void
{
	for ( var i : int = 0; i < group.numElements; i ++ )
	{
	  var element : UIComponent = UIComponent( group.getElementAt( i ) );
	  var button  : Button      = getButton( IVisualElementContainer( element ) );
	  
	  if ( button )
	  {
		  button.selected = element.name == buttonName;
	  }
	}
}

private function getSelectedButtonName( group : IVisualElementContainer ) : String
{
	for ( var i : int = 0; i < group.numElements; i ++ )
	{
		var element : UIComponent = UIComponent( group.getElementAt( i ) );
		var button  : Button      = getButton( IVisualElementContainer( element ) );
		
		if ( button.selected )
		{
			return element.name;
		}
	}
	
	return null;
}

private var _nextState : String;

private function onEffectEnd() : void
{
	currentState = _nextState;
}

private function changeCurrentState( state : String ) : void
{
	_nextState = state;
	fadeEffect.play();
}

private function goToFormatIndex( index : int ) : void
{
	formatViewStack.selectedIndex = index;
}

private function closeClick() : void
{
	HintManager.hideAll();
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
}

private function switchOnProModeClick() : void
{
	closeClick();
	ApplicationModel.topPanel.showWelcomeDialog( Slides.PRO_ADVANTAGES );
}

private var fromErrorState : String;

private function onPublishToMyAudioClick( e : MouseEvent ) : void
{
	params.action      = MixdownAction.SAVE_TO_MY_AUDIO;
	params.format      = PublisherAPI.FORMAT_MP3;
	params.quality     = api.userInfo.pro ? PublisherAPI.QUALITY_320_K : PublisherAPI.QUALITY_128_K;
	params.playingArea = seq.getPlayingArea( publishSelectedOption.selected );
	
	if ( isMaxDurationExceeded( params.playingArea ) )
	{
		changeCurrentState( 'tooLongError' );
	}
	else
	{
		changeCurrentState( 'publish' );
	}
	
	fromErrorState = 'publish';
}

private function onSaveToMyComputerClick( e : MouseEvent ) : void
{
	if ( api.userInfo.pro )
	{
		params.action      = MixdownAction.SAVE_TO_MY_COMPUTER;
		params.format      = PublisherAPI.FORMAT_MP3;
		params.quality     = api.userInfo.pro ? PublisherAPI.QUALITY_320_K : PublisherAPI.QUALITY_128_K;
		params.playingArea = seq.getPlayingArea( publishSelectedOption.selected );
		
		if ( isMaxDurationExceeded( params.playingArea ) )
		{
			changeCurrentState( 'tooLongError' );
		}
		else
		{
			changeCurrentState( 'save' );
		}
	}
	else
	{
		AddProToolTip.show( 'Для использования этой возможности необходимо подключить режим PRO.', null, e.currentTarget, this );
	}
	
	fromErrorState = 'save';
}

private function isMaxDurationExceeded( playingArea : Object ) : Boolean
{
	/*
	В режиме PRO, длина ограничена 5-тью минутами.
	Предупреждаем об этом пользователя, если необходимо
	*/
	if ( ! api.userInfo.pro )
	{
		//Ограничение, длительность микса по умолчанию + 1 секунда
		return playingArea.length > Settings.DEFAULT_PROJECT_DURATION_IN_FRAMES + TimeConversion.secondsToNumSamples( 1.0 );
	}
	
	return false;
}

private function updateFormatButtons( selected : Button ) : void
{
	var g : IVisualElementContainer = IVisualElementContainer( selected.parent );
	
	for ( var i : int = 0; i < g.numElements; i ++ )
	{
		var b : Button = g.getElementAt( i ) as Button;
		
		if ( b )
		{
			b.selected = false;
		}
	}
	
	selected.selected = true;
}

private function mp3ButtonClick( e : MouseEvent ) : void
{
	goToFormatIndex( 0 );
	
	params.format = PublisherAPI.FORMAT_MP3;
	
	var g : IVisualElementContainer = IVisualElementContainer( formatViewStack.selectedChild );
	var q : String                  = getSelectedButtonName( g ); 
	
	if ( q )
	{
		params.quality = q;
	}
	
	updateFormatButtons( Button( e.currentTarget ) );
}

private function wavButtonClick( e : MouseEvent ) : void
{
	if ( api.userInfo.pro )
	{
		goToFormatIndex( 1 );
		
		params.format  = PublisherAPI.FORMAT_WAVE;
		
		var g : IVisualElementContainer = IVisualElementContainer( formatViewStack.selectedChild );
		var q : String                  = getSelectedButtonName( g ); 
		
		if ( q )
		{
			params.quality = q;
		}
		else
		{
			params.quality = PublisherAPI.QUALITY_16_BIT_44100;
		}
	}
	else
	{
		AddProToolTip.show( 'Для публикации в этом формате необходимо подключить режим PRO.', null, e.currentTarget, this );
	}
	
	updateFormatButtons( Button( e.currentTarget ) );
}

private function selectDefaultFormatAndQuality( e : FlexEvent ) : void
{
	selectButton( IVisualElementContainer( e.currentTarget ), params.quality );
}

private function publishClick() : void
{
	if ( currentState == 'tooLongError' )
	{
		params.playingArea.to -= params.playingArea.length - ( Settings.DEFAULT_PROJECT_DURATION_IN_FRAMES + TimeConversion.secondsToNumSamples( 1.0 ) );
		changeCurrentState( fromErrorState );
		return;
	}
	
	dispatchEvent( new MixdownOptionsEvent( MixdownOptionsEvent.SELECTED, params ) );
}