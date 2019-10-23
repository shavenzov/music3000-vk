import classes.BaseDescription;
import classes.PaletteSample;
import classes.SampleDescription;
import classes.SamplesPalette;
import classes.Sequencer;
import classes.SequencerImplementation;

import components.library.controls.events.ResultSortEvent;
import components.library.events.LibraryModuleEvent;

import flash.display.DisplayObject;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.CloseEvent;
import mx.events.CollectionEvent;

import spark.collections.Sort;

private var palette : SamplesPalette;
private var seq : SequencerImplementation;
private var dataProvider : ArrayCollection;

private var _searchText : String;
private var _showOnlyFavorite : Boolean;

public function get searchText() : String
{
	return _searchText;
}

public function set searchText( value : String ) : void
{
	_searchText = value;
}

public function get mainComponent() : DisplayObject
{
	return result;
}

public function get showOnlyFavorite() : Boolean
{
	return _showOnlyFavorite;
}

public function set showOnlyFavorite( value : Boolean ) : void
{
	_showOnlyFavorite = value;
}

public function get ready() : Boolean
{
	return dataProvider != null;
}

public function reset() : void
{
	_searchText = null;
	_search();
}

public function search() : void
{
	_search();
}

public function get searchBoxEnabled() : Boolean
{
	return palette.samples.length > 0;
}

private function creationComplete() : void
{
	seq = Sequencer.impl;
	palette = seq.palette;
	
	var sort : Sort = new Sort();
	    sort.compareFunction = compareFunction;
	
	dataProvider = new ArrayCollection( palette.samples.source );
	dataProvider.filterFunction = filterFunction;
	dataProvider.sort = sort;
	
	result.dataProvider = dataProvider;
	
	palette.samples.addEventListener( CollectionEvent.COLLECTION_CHANGE, onCollectionChange );
	
	_search();
}

private function compactPalette() : void{
	Alert.showConfirmation( 'Действительно удалить неиспользуемые сэмплы?', compactPaletteCloseHandler );
}

private function compactPaletteCloseHandler( e : CloseEvent ) : void
{
	if ( e.detail == Alert.YES )
	{
		seq.compactPalette();
	}
}

private function onSortParamsChanged( e : ResultSortEvent ) : void
{
	dataProvider.refresh();
}

private var timeout_id : int = -1;

private function onCollectionChange( e : CollectionEvent ) : void
{
	//Изменения вступают в силу, только после 100 мс с последнего обновления
	//для предотвращения излишнего вызова filterFunction
	if ( timeout_id != -1 )
	{
		clearTimeout( timeout_id );
	}
	
	timeout_id = setTimeout( onTimeout, 100 );
}

private function onTimeout() : void
{
	timeout_id = -1;
	_search();
}

private function _search() : void
{
	dataProvider.refresh();
	emptyLabel.visible = emptyLabel.includeInLayout = palette.samples.length == 0;
	emptySearch.visible = emptySearch.includeInLayout = dataProvider.length == 0;
	
	content.visible = ! emptyLabel.visible;
	
	if ( emptyLabel.visible )
	{
		dispatchEvent( new LibraryModuleEvent( LibraryModuleEvent.SEARCH_BOX_ENABLED_CHANGED ) );
	}
}

private function filterFunction( item : Object ) : Boolean
{
	var searchTextCondition : Boolean = true;
	
	var s                   : PaletteSample = PaletteSample( item );
	
	//Фильтр по названию сэмпла
	if ( ( _searchText != null ) && ( _searchText.length > 0 ) )
	{
		searchTextCondition = s.description.name.toLocaleLowerCase().indexOf( _searchText.toLocaleLowerCase() ) != -1;
	}
	
	//Отображать только избранные сэмплы
	var favoriteCondition   : Boolean = true;
	
	if ( _showOnlyFavorite )
	{
		favoriteCondition = s.description.favorite;
	}
	
	return favoriteCondition && searchTextCondition;
}

private function compareFunction( a:Object, b:Object, fields:Array = null) : int
{
	var field : String  = sortList.sortField;
	var desc  : Boolean = sortList.descending;
	var itemA : BaseDescription = PaletteSample( a ).description;
	var itemB : BaseDescription = PaletteSample( b ).description;
	
	switch ( field )
	{
		case "duration" : if ( itemA.duration == itemB.duration )
			               return 0;
			
			              if ( itemA.duration > itemB.duration )
						  {
							  return desc ? -1 : 1;
						  }
						  else
						  {
							  return desc ? 1 : -1;
						  }
			
			              break;
		
		case "tempo"    : if ( itemA.bpm == itemB.bpm )
			               return 0;
			
			              if ( itemA.bpm > itemB.bpm )
			              {
				           return desc ? -1 : 1;
			              }
						  else
						  {
							  return desc ? 1 : -1;  
						  }
			
			              break;
		
		case "name"     : var r : int = desc ? itemB.name.localeCompare( itemA.name ) :
			                                   itemA.name.localeCompare( itemB.name );
			              					   
			              return r == 0 ? r : r / Math.abs( r );
			
			              break;
		
	}
	
	return 0;
}
