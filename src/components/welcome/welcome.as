import classes.api.MainAPI;
import classes.api.MainAPIImplementation;
import classes.api.events.LimitationsEvent;
import classes.api.social.vk.VKApi;

import components.controls.tips.AddProToolTip;
import components.managers.HintManager;
import components.welcome.Slides;
import components.welcome.events.BrowseProjectsEvent;
import components.welcome.events.GoToEvent;
import components.welcome.events.OpenProjectEvent;

import flash.events.Event;

import flashx.textLayout.conversion.TextConverter;

private var api : MainAPIImplementation;

private function creationComplete() : void
{
	api = MainAPI.impl;
	ApplicationModel.userInfo.visible = true;
	title.textFlow = TextConverter.importToFlow( '<b>' + VKApi.userInfo.first_name + '</b>, Добро Пожаловать в Музыкальный Конструктор!', TextConverter.TEXT_FIELD_HTML_FORMAT );
	/*
	if ( api.firstTime )
	{
		if ( initializedAction.fromIndex == Slides.VIDEO )
		{
			menu.visible = menu.includeInLayout = false;
			return;
		}
	}
	*/
	onUsersChange();
}

private function onUsersChange() : void
{
	myMixes.selectedUser = userslist.selectedItem;
	myMixes.refresh();
}

private function browseClick() : void
{
	HintManager.hideAll();
	dispatchEvent( new BrowseProjectsEvent( BrowseProjectsEvent.BROWSE_PROJECTS, userslist.selectedItem ) );
}

private function onGotLimitations( e : LimitationsEvent ) : void
{
	api.removeAllObjectListeners( this );
	ApplicationModel.userInfo.enabled = true;
	if ( e.projectsExceeded )
	{
		currentState = 'normal';
		AddProToolTip.showLimitationTip( e.projectsErrorCode, newMixButton );
	}
	else
	{
		dispatchEvent( new Event( 'newProject' ) );	
	}
}

private function newMixClick() : void
{
	currentState = 'newMixLoading';
	ApplicationModel.userInfo.enabled = false;
	api.addListener( LimitationsEvent.GOT_LIMITATIONS, onGotLimitations, this );
	api.getLimitations();
}

private function onOpen( e : OpenProjectEvent ) : void
{
	HintManager.hideAll();
	dispatchEvent( e );
}

private function videoClick() : void
{
	HintManager.hideAll();
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.VIDEO, 'normal' ) );
}

private function onProjectsLoaded() : void
{
	projectsButton.visible = myMixes.currentState != 'empty';
	ApplicationModel.userInfo.enabled = true;
	currentState = 'normal';
}

private function onStartUpdate() : void
{
	currentState = 'loadingProjects';
	ApplicationModel.userInfo.enabled = false;
}