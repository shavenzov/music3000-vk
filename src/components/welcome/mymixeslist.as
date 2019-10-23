import classes.api.MainAPI;
import classes.api.data.ProjectInfo;
import classes.api.events.BrowseProjectEvent;
import classes.api.events.RemoveProjectEvent;
import classes.api.events.SaveProjectEvent;
import classes.api.social.vk.VKApi;

import components.welcome.events.OpenProjectEvent;

import flash.events.Event;

import mx.collections.ArrayCollection;

/**
 * Количество отображаемых проектов в миксе 
 */
private static const numVisibleProjects : int = 8;

/**
 * Выбранный проект 
 */
public var selectedProject : ProjectInfo;

/**
 * Текущий выбранный пользователь, чьи миксы необходимо отображать 
 */
public var selectedUser : Object;

public function refresh() : void
{
	if ( currentState != 'updating' )
	{
		currentState = 'updating';
		selectedProject = null;
		
		MainAPI.impl.addListener( BrowseProjectEvent.BROWSE_PROJECTS, onBrowsedProjects, this, 1000 );
		MainAPI.impl.browseProjectsByNetUserID( selectedUser.uid, 0, numVisibleProjects );
		
		dispatchEvent( new Event( 'startUpdate' ) );
	}
}

private function onAddedToStage() : void
{
	MainAPI.impl.addListener( RemoveProjectEvent.REMOVE, onUpdate, this );
	MainAPI.impl.addListener( SaveProjectEvent.UPDATE, onUpdate, this );
}

private function onRemovedFromStage() : void
{
	MainAPI.impl.removeAllObjectListeners( this );
}

private function onUpdate( e : Event ) : void
{
	refresh();
}

private function onBrowsedProjects( e : BrowseProjectEvent ) : void
{
	MainAPI.impl.removeListener( BrowseProjectEvent.BROWSE_PROJECTS, onBrowsedProjects );
	
	projects.dataProvider = new ArrayCollection( e.projects );
		
	if ( e.projects.length == 0 )
	{
		currentState = 'empty';
	}
	else
	{
		currentState = 'normal';
	}
	
	if ( VKApi.userInfo.uid == selectedUser.uid )
	{
		header.text = 'Мои последние миксы';
	}
	else
	{
		header.text = 'Последние миксы ' + VKApi.formatUserFullName( selectedUser );
	}
	
	dispatchEvent( new Event( 'updated' ) );
	
	e.stopImmediatePropagation();
}

private function selectProject() : void
{
	selectedProject = projects.selectedItem;
	dispatchEvent( new OpenProjectEvent( OpenProjectEvent.OPEN, selectedProject ) );
}
/*
private static const ProjectItemRenderer        : ClassFactory = new ClassFactory( TinyProjectRenderer );
private static const BrowseProjectsItemRenderer : ClassFactory = new ClassFactory( BrowseProjectsRenderer );

private function selectRenderer( item : Object ) : ClassFactory
{
	if ( item )
	{
		return ProjectItemRenderer;
	}
	
	return BrowseProjectsItemRenderer;
}
*/