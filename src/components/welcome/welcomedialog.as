import flash.events.Event;

import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.FlexEvent;

import classes.api.MainAPI;
import classes.api.social.vk.VKApi;

import components.welcome.NavigatorContent;
import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;
import components.welcome.events.OpenProjectEvent;

private static const TWEEN_DURATION : Number = 250;

private var _selectedIndex : int;

private function onGo( e : GoToEvent ) : void
{
	if ( e.toIndex == viewStack.selectedIndex )
	{
		return;
	}
	
	/*
	Отдаем управление hook
	*/
	if ( preNextSlideHook( e.toIndex ) )
	{
		return;
	}
	
	var fromSlide : NavigatorContent = NavigatorContent( viewStack.selectedChild );
	var toSlide   : NavigatorContent = NavigatorContent( viewStack.getChildAt( e.toIndex ) );
	
	//Меняем св-во initializedAction, только если оно ещё не инициализировано
	//Если это не первый слайд ( с которого начался просмотр )
	//Если groupIndex слайдов равен или повышается
	if ( ( toSlide.initializedAction == null ) || ( ( fromSlide.groupIndex <= toSlide.groupIndex ) && ( toSlide.initializedAction.toIndex != -1 ) ) )
	{
		toSlide.initializedAction  = new GoToEvent( GoToEvent.GO, e.toIndex, e.toState, 
				e.fromIndex == -2 ? viewStack.selectedIndex : e.fromIndex,
				e.fromState == -2 ? UIComponent( viewStack.selectedChild ).currentState : e.fromState, e.other );
	}
	
	if ( e.toState != null )
	{
		toSlide.currentState = e.toState;
	}
	
	viewStack.selectedIndex = e.toIndex;    
}
/**
 * 
 * @param viewIndex - индекс слайда куда отправляться
 * @param viewState - состояние слайда куда отправляться
 * @param fromViewIndex - с какого слайда осуществлен переход, если -2 номер слайда определяется автоматически, -1 означает что текущий слайд корневой
 * @param fromViewState - состояние слайда с которого совершен переход, если -2, состояние слайда определяется автоматически
 * 
 */
public function go( viewIndex : int, viewState : String, fromViewIndex : int = -2, fromViewState : * = -2, other : * = null ) : void
{
	onGo( new GoToEvent( GoToEvent.GO, viewIndex, viewState, fromViewIndex, fromViewState, other ) );
}

private function onOpen( e : OpenProjectEvent ) : void
{
	if ( e.fromIndex == -1 )
	{
		e.fromIndex = Slides.WELCOME; //По умолчанию, всегда возвращаемся на окно приветствия и выбора последних миксов
	}
	
	dispatchEvent( e );
}

private function onNewProject( e : Event ) : void
{
	dispatchEvent( e );
}

private function onBrowseProjects( e : Event ) : void
{
	dispatchEvent( e );
}

private function onClose( e : CloseEvent ) : void
{
	dispatchEvent( e );
}

public var viewIndex : int;
public var viewState : String;
public var fromIndex : int = -2;
public var fromState : *;
public var other : *;

private function viewStackPreinitialize() : void
{
	viewStack.selectedIndex = viewIndex;
}

private function viewStackInitialize() : void
{
	var slide : NavigatorContent = NavigatorContent( viewStack.getChildAt( viewIndex ) );
	    slide.initializedAction = new GoToEvent( GoToEvent.GO, -1, viewState, fromIndex, fromState, other );
	    slide.currentState = viewState;
		slide.addEventListener( FlexEvent.CONTENT_CREATION_COMPLETE, onFirstSlideContentCreationComplete );
}

private function onFirstSlideContentCreationComplete( e : FlexEvent ) : void
{
	var slide : UIComponent = UIComponent( e.currentTarget );
	    slide.removeEventListener( FlexEvent.CONTENT_CREATION_COMPLETE, onFirstSlideContentCreationComplete );
		slide.dispatchEvent( new FlexEvent( FlexEvent.SHOW ) );
		
		preNextSlideHook( viewIndex );
}

/* 
   Если в командной строке указан ID микса который необходимо открыть, то при попадании на Welcome.mxml, вместо отображения диалога, запускаем процесс открытия микса
   true  - если переход перехвачен
   false - переход не перехвачен, отрабатывается переход по умолчанию
*/
private function preNextSlideHook( slideIndex : int ) : Boolean
{
	if ( slideIndex == Slides.WELCOME )
	{
		if ( VKApi.initialized )
		{
			if ( VKApi.params.hasOwnProperty( Settings.PROJECT_ID_PARAM_NAME ) )
			{
				callLater( onOpen, [ new OpenProjectEvent( OpenProjectEvent.OPEN, VKApi.params[ Settings.PROJECT_ID_PARAM_NAME ], slideIndex ) ] );
				
				//Если есть информация о миксе который необходимо открыть по умолчанию, то удаляем её
				if ( VKApi.initialized )
				{
					if ( VKApi.params.hasOwnProperty( Settings.PROJECT_ID_PARAM_NAME ) )
					{
						delete VKApi.params[ Settings.PROJECT_ID_PARAM_NAME ];
					}
				}
				
				return true;
			}
		}
	}
	
	return false;
}

/*Отдельные ф-ии для диалогов серии payments*/

//Обработчик нажатия на кнопке "назад" или "закрыть" для все сладйов "payments"
private function paymentsGroupBack( e : BackEvent ) : void
{
	if (  ApplicationModel.project.opened  && ( MainAPI.impl.userInfo.pro != ApplicationModel.project.openedInProMode ) )
	{
		go( Slides.RELOAD_PROJECT_DIALOG, null ); //Отправляем на сообщение о необходимости перезагрузки микса
	}
	else
	{
		var slide : NavigatorContent = NavigatorContent( e.currentTarget );
		
		if ( slide.initializedAction.fromIndex == -1 )
		{
			dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
		}
		else
		{
			go( slide.initializedAction.fromIndex, slide.initializedAction.fromState );  
		}
	}
}

/*----------------------------------------------*/


