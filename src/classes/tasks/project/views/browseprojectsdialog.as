import classes.api.MainAPI;
import classes.api.data.ProjectInfo;

import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.events.InvalidateRequestData;

import spark.events.IndexChangeEvent;

private var _loading : Boolean = true;
private var _loadingChanged : Boolean;

/**
 *  Выбранный пользователем проект
 * 
 */
public var selectedProject : ProjectInfo;

public function get loading() : Boolean
{
	return _loading;
}

public function set loading( value : Boolean ) : void
{
	_loading = value;
	_loadingChanged = true;
	invalidateProperties();
}

private var scrollPos : Number;

public function updateProjects( value : Array, restore : Boolean = true ) : void
{
	var selectedIndex : int = -1;
	    scrollPos = projectsList.layout.verticalScrollPosition;   
	
	if ( projectsList.dataProvider )
	{
		selectedIndex = projectsList.selectedIndex;
	}
	
	projectsList.dataProvider = new ArrayCollection( value );
	
	if ( restore && ( value.length > 0 ) )
	{
		projectsList.selectedIndex = selectedIndex == -1 ? -1 : ( ( selectedIndex < value.length ) ? selectedIndex : value.length - 1 );
		selectedProject = projectsList.selectedItem;
		callLater( restoreScrollPos );
	}
	else
	{
		selectedProject = null;
	}
	
	count.text = value.length.toString();
	count.visible = value.length > 0;
	
	noMixes.visible = noMixes.includeInLayout = ( value.length == 0 );
	setToolsEnabled( selectedProject != null );
}

private function restoreScrollPos() : void
{
	projectsList.layout.verticalScrollPosition = scrollPos;
}

override protected function commitProperties() : void
{
	super.commitProperties();
	
	if ( _loadingChanged )
	{
		progress.visible = progress.includeInLayout = _loading;
		content.enabled = ! _loading;
		_loadingChanged = false;
	}
}

private function closeClick() : void
{
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE, false, false, Alert.CANCEL ) );
}

private function creationComplete() : void
{
  projectsList.scroller.setStyle( "horizontalScrollPolicy", "off" );
}

private function setToolsEnabled( value : Boolean ) : void
{
	openButton.enabled =
		deleteButton.enabled = 
		propertiesButton.enabled = value;
}

private function projectsListChange( e : IndexChangeEvent ) : void
{
	setToolsEnabled( e.newIndex != -1 );
	selectedProject = projectsList.selectedItem;
}

private function projectsListDoubleClick() : void
{
	if ( projectsList.selectedIndex != -1 )
	{
		dispatchEvent( new CloseEvent( CloseEvent.CLOSE, false, false, Alert.OK ) );
	}
}

private function onAddedToStage() : void
{
	stage.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
}

private function onRemovedFromStage() : void
{
	stage.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp );
}

private function onKeyUp( e : KeyboardEvent ) : void
{
	if ( e.charCode == Keyboard.ESCAPE )
	{
		if ( ! _loading )
		{
			closeClick();
		}
	}
}