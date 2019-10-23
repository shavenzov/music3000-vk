import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

import mx.controls.Button;
import mx.controls.LinkButton;
import mx.core.ClassFactory;
import mx.core.mx_internal;
import mx.events.FlexEvent;
import mx.events.SliderEvent;
import mx.utils.StringUtil;

import components.library.ErrorItemRenderer;
import components.library.PendingItemRenderer;
import components.library.SampleItemRenderer;
import components.library.controls.events.ResultSortEvent;
import components.library.events.AssyncItemError;
import components.library.events.DataEvent;
import components.library.events.ItemPendingError;
import components.library.looperman.AsyncLoopermanCollection;
import components.library.looperman.LoopermanAPI;
import components.library.looperman.events.TagEvent;

use namespace mx_internal;

public var collection : AsyncLoopermanCollection;
private var api : LoopermanAPI;

private var selectedGenres : Array = [];
private var selectedCategories : Array = [];
private var selectedKeys : Array = [];

private static const UPDATE_DELAY : Number = 500.0;

private var firstRequest : Boolean = true;

private var tagLoading : Boolean;
private var resultLoading : Boolean;

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

public function get searchBoxEnabled() : Boolean
{
	return true;
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
	return ! firstRequest;
}

private function creationComplete() : void
{
	setTimeout( init, 1000 );
}

private function init() : void
{
	collection = new AsyncLoopermanCollection();
	collection.addEventListener( components.library.events.DataEvent.DATA_COMPLETE, onResultComplete );
	
    result.dataProvider = collection;
	result.scroller.verticalScrollBar.addEventListener( FlexEvent.CHANGE_START, onResultChangeStart );
	result.scroller.verticalScrollBar.addEventListener( FlexEvent.CHANGE_END, onResultChangeEnd );
	result.scroller.verticalScrollBar.addEventListener( Event.CHANGE, onResultChange );
	
	api = new LoopermanAPI();
	api.addListener( TagEvent.TAG_COMPLETE, onTagComplete, this );
	api.getSearchParams( { showOnlyFavorite : _showOnlyFavorite }, true );
	firstSearch();
	tagLoading = true;
	resultLoading = true;
	setTagEnabled( false );
}

/**
 * Полоса прокрутки списка семплов захвачена пользователем 
 * 
 */
private var resultScrolling : Boolean;

private function onResultChangeStart( e : FlexEvent ) : void
{
    resultScrolling = true;
}

private function onResultChangeEnd( e : FlexEvent ) : void
{
	clearTimer();
	resultScrolling = false;
	updateResult();
}

private function onResultChange( e : Event ) : void
{
	if ( resultScrolling )
	{
		collection.autoUpdate = false;
		clearTimer();
		setTimer();
	}
}

private function updateResult() : void
{
	collection.autoUpdate = true;
	collection.updateItems( result.dataGroup.getItemIndicesInView() );
}

private var timerID : int = -1;

private function setTimer() : void
{
  if ( timerID == -1 )
  {
	timerID = setTimeout( updateResult, UPDATE_DELAY );
  }
}

private function clearTimer() : void
{
	if ( timerID != -1 )
	{
		clearTimeout( timerID );
		timerID = -1;
	}
}

private function onResultComplete( e : components.library.events.DataEvent ) : void
{
	resultLoading = false;
	setTagEnabled( ! tagLoading &&  ! resultLoading );
	emptySearch.visible = emptySearch.includeInLayout = e.count == 0;
	
	//total.text = 'Найдено : ' + e.count;
}

private static const PendingItemRendererFactory   : ClassFactory = new ClassFactory( PendingItemRenderer );
private static const ItemRendererFactory : ClassFactory = new ClassFactory( SampleItemRenderer );
private static const ErrorItemRendererFactory     : ClassFactory = new ClassFactory( ErrorItemRenderer );

private function selectRenderer( item : Object ) : ClassFactory
{
	if ( ( item is ItemPendingError ) || ( item == null ) )
	{
		return PendingItemRendererFactory;
	}
	else
	if ( item is AssyncItemError )
	{
		return ErrorItemRendererFactory
	}
	
	return ItemRendererFactory;
}

private function updateGenres( genres : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( genresContainer.numElements > 0 )
	{
		genresContainer.removeAllElements();
	}
	
	i = 0;
	
	while( i < genres.length )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = genres[ i ].label;
		b.data = genres[ i ].id;
		b.addEventListener( MouseEvent.CLICK, onGenreClick );
		
		genresContainer.addElement( b );
		
		i ++;
	}
	
	genresLabel.visible = genres.length > 0;
}

private function updateCategories( categories : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( categoriesContainer.numElements > 0 )
	{
		categoriesContainer.removeAllElements();
	}
		
	i = 0;
	
	while( i < categories.length )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = categories[ i ].label;
		b.data = categories[ i ].id;
		b.addEventListener( MouseEvent.CLICK, onCategoriesClick );
				
		categoriesContainer.addElement( b );
		
		i ++;
	}
	
	categoriesLabel.visible = categories.length > 0;
}

private function updateKeys( keys : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( keysContainer.numElements > 0 )
	{
		keysContainer.removeAllElements();
	}
	
	i = 0;
	
	while( i < keys.length )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = keys[ i ];
		b.data = keys[ i ];
		b.addEventListener( MouseEvent.CLICK, onKeysClick );
		
		keysContainer.addElement( b );
		
		i ++;
	}
	
	keysLabel.visible = keys.length > 0;
}

private function updateTempos( tempos : Array ) : void
{
	if ( tempos.length <= 1 )
	{
		tempo.enabled = false;
		
		if ( tempos.length == 1 )
		{
			tempo.minimum = tempo.maximum = tempos[ 0 ];
			tempo.values = [ tempos[ 0 ], tempos[ 0 ] ];
			tempo.labels = [ tempos[ 0 ] ];
		}	
	}
	else
	{
	   tempo.enabled = true;
	   
	   tempo.minimum = tempos[ 0 ];
	   tempo.maximum = tempos[ tempos.length - 1 ];
	   
	   tempo.values[ 0 ] = tempos[ 0 ];
	   tempo.values[ 1 ] = tempos[ tempos.length - 1 ];
	   
	   tempo.labels  = [ tempos[ 0 ], tempos[ tempos.length - 1 ] ];
	   tempo.tickValues = tempos;
	}
	
	updateTempoLabel();
}

private function itemExists( list : Array, item : * ) : Boolean
{
	var i : int = 0;
	var v1 : String = item as String ? item : item.id; 
	var v2 : String;
	
	while( i < list.length )
	{
		v2 = list[ i ] as String ? list[ i ] : list[ i ].id;
		
		if ( v1 == v2 )
		{
			return true;
		}
		
		i ++;
	}
	
	return false;
}


private function excludeFromList( list : Array, item : String ) : void
{
	var i : int = 0;
	
	while( i < list.length )
	{
		if ( list[ i ] == item )
		{
			list.splice( i, 1 );
			break;
		}	
		
		i ++;
	}
}

private function onCategoriesClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;	
	
	if ( b.selected )
	{
		selectedCategories.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedCategories, String( b.data ) );
	}
	
	_search();
} 

private function onGenreClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;
	
	if ( b.selected )
	{
		selectedGenres.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedGenres, String( b.data ) );
	}
	
	_search();
}

private function onKeysClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;
	
	if ( b.selected )
	{
		selectedKeys.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedKeys, String( b.data ) );
	}
	
	_search();
}
	
private function onSortParamsChanged( e : ResultSortEvent ) : void
{
	_search( false );
}

private function updateTempoLabel() : void
{
	tempoText.text =  tempo.values[ 0 ] + ' - ' + tempo.values[ 1 ];
}

private function tempoChange( e : SliderEvent ) : void
{
	updateTempoLabel();
	_search();
}

private function setTagEnabled( value : Boolean ) : void
{
	genresContainer.enabled = value;
	categoriesContainer.enabled = value;
	keysContainer.enabled = value;
	tempo.enabled = value;
	result.enabled = value;
	sortList.enabled = value;
	indicator.visible = ! value;
	
	ApplicationModel.bottomPanel.searchBox.searchButton.enabled = value;
	ApplicationModel.bottomPanel.searchBox.resetButton.enabled = value;
}

public function reset() : void
{
	selectedGenres = [];
	selectedCategories = [];
	selectedKeys = [];

	tempo.setThumbValueAt( 0, tempo.minimum );
	tempo.setThumbValueAt( 1, tempo.maximum );
	
	_searchText = null;
	_search();
}

public function search() : void
{
	_search();
}

private function _search( updateParams : Boolean = true ) : void
{
	tagLoading = updateParams;
	resultLoading = true;
	
	var searchParams : Object = { genres : selectedGenres, categories : selectedCategories, tempoFrom : tempo.values[ 0 ], tempoTo : tempo.values[ 1 ], 
		                          keys : selectedKeys, showOnlyFavorite : _showOnlyFavorite, orderBy : sortList.sortField, order : sortList.descending ? 'desc' : 'asc'
	                            };
	
	if ( _searchText && _searchText.length > 0 )
	{
		searchParams.name = _searchText;
	}
	
	if ( updateParams )
	{
		var tagParams : Object = { showOnlyFavorite : _showOnlyFavorite, tempoFrom : tempo.values[ 0 ], tempoTo : tempo.values[ 1 ] };
		
		if ( searchParams.name != undefined )
		{
			tagParams.name = searchParams.name;
		}
		
		var updateGenres : Boolean = selectedGenres.length == 0;
		var updateCategories : Boolean = selectedCategories.length == 0;
		var updateKeys : Boolean = selectedKeys.length == 0;
		
		if ( ! updateGenres )
		{
			tagParams.genres = selectedGenres;
		}
		
		if ( ! updateCategories )
		{
			tagParams.categories = selectedCategories;
		}
		
		if ( ! updateKeys )
		{
			tagParams.keys = selectedKeys;
		}
		
		if ( updateCategories || updateGenres || updateKeys )
		{
			api.getSearchParams( tagParams, updateGenres, updateCategories, false, updateKeys );	
		}
		else
		{
			tagLoading = false;
		}
	}

	collection.search( searchParams );
	
	result.selectedIndex = -1;
	result.scroller.verticalScrollBar.value = 0;
	
	setTagEnabled( false );
}

private function firstSearch() : void
{
	collection.search( { showOnlyFavorite : _showOnlyFavorite, orderBy : sortList.sortField, order : sortList.descending ? 'desc' : 'asc' } );
}

private function onTagComplete( e : TagEvent ) : void
{
	if ( firstRequest )
	{
		firstRequest = false;
		paramsGroup.visible = true;
		
		updateTempos( e.tempos );
	}	
	
	if ( e.genres )
	{
		updateGenres( e.genres );
	}
		
	if ( e.categories )
	{
		updateCategories( e.categories );
	}
	
	if ( e.keys )
	{
	   updateKeys( e.keys );	
	}
		
	tagLoading = false;
	
	setTagEnabled( ! tagLoading &&  ! resultLoading );
}