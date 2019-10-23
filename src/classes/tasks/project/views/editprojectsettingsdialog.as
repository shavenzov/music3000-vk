import com.audioengine.core.TimeConversion;
import com.utils.TimeUtils;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.CloseEvent;

import spark.components.ComboBox;

import classes.api.data.ProjectAccess;
import classes.api.data.ProjectInfo;

import components.utils.ErrorUtils;

public var info : ProjectInfo;

private function closeClick() : void
{
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE, false, false, Alert.CANCEL ) );
}

private function creationComplete() : void
{
	projectName.text = info.name;
	genre.dataProvider = new ArrayCollection( Settings.LOOPERMAN_GENRES );
    
	var item : Array = Settings.processGenres( [ info.genre ], true );

	genre.selectedItem = item.length == 0 ? info.genre : item[ 0 ];
	
	description.text = info.description;
	tempo.text    = ' ' + info.tempo;
	time.text = ' ' + TimeUtils.formatSeconds3( TimeConversion.numSamplesToSeconds( info.duration ) );
	
	userGenre = info.userGenre;
	
	autoGenre.selected = ! userGenre;
	genre.enabled = userGenre;
	
	inputGenre = info.genre;
	
	for ( var i : int = 0; i < access.dataProvider.length; i ++ )
	{
		if ( access.dataProvider.getItemAt( i ).access == info.access )
		{
			access.selectedIndex = i;
			break;
		}
	}
	
	readonly.selected = info.readonly;
	readonly.visible = access.selectedItem.access != ProjectAccess.NOBODY;
}

private var dataChanged : Boolean;

/**
 * Жанр изменен пользователем 
 */
private var userGenre : Boolean;

/**
 * Жанр определенный системой 
 */
public var defaultGenre : String;

/**
 * Жанр выбранный пользователем 
 */
private var inputGenre : String;

private function genreChange() : void
{
	if ( genre.selectedIndex == -1 )
	{
		inputGenre = '';
	}
	else
	{
		inputGenre = genre.selectedIndex == ComboBox.CUSTOM_SELECTED_ITEM ? genre.selectedItem : genre.selectedItem.id;	
	}
	
	change();
}

private function checkFields( showError : Boolean = false ) : Boolean
{
	var error : Boolean = true;
	
	if ( projectName.text.length == 0 )
	{
		projectName.errorString = 'Не указано название микса.';
		if ( showError ) ErrorUtils.justShow( projectName );
		error = false;
	}
	else
	{
		projectName.errorString = null;
	}
	
	if ( genre.selectedIndex == -1 )
	{
		genre.errorString = 'Не указан жанр микса';
		if ( showError && error ) ErrorUtils.justShow( genre );
		error = false;
	}
	else
	{
		genre.errorString = null;
	}
	
	return error;
}

private function checkBoxClick() : void
{
	userGenre = ! autoGenre.selected;
	genre.enabled = userGenre;
	
	if (  userGenre )
	{
		var item : Array = Settings.processGenres( [ inputGenre ], true );
		genre.selectedItem = item.length == 0 ? inputGenre : item[ 0 ];
	}
	else
	{
		genre.selectedItem = Settings.processGenres( [ defaultGenre ] )[ 0 ];
	}
	
	change();
}

private function commitClick() : void
{
	if ( checkFields( true ) )
	{
		info.name  = projectName.text;
		info.genre = genre.selectedIndex == ComboBox.CUSTOM_SELECTED_ITEM ? genre.selectedItem : genre.selectedItem.id;
		info.description = description.text;
		info.userGenre = userGenre;
		info.access = access.selectedItem.access;
		info.readonly = readonly.selected;
		ErrorUtils.hide( projectName );
		dispatchEvent( new CloseEvent( CloseEvent.CLOSE, false, false, Alert.OK ) );
	}
}

private function accessChange() : void
{
	readonly.visible = access.selectedItem.access == ProjectAccess.FRIENDS;
	change();
}

private function change() : void
{
	dataChanged = true;
	commitButton.enabled = true;
	checkFields();
}

public function setError( str : String ) : void
{
	ErrorUtils.show( projectName, str );
}

public function get applying() : Boolean
{
	return apply.visible;
}

public function set applying( value : Boolean ) : void
{
	content.enabled = ! value;
	apply.visible  = value;	
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
		if ( ! applying )
		{
			closeClick();
		}
	}
}