import components.library.ErrorItemRenderer;
import components.library.PendingItemRenderer;
import components.library.SampleItemRenderer;
import components.library.acapellas.AcapellaAPI;
import components.library.acapellas.AsyncAcapellaCollection;
import components.library.acapellas.events.TagEvent;
import components.library.controls.events.ResultSortEvent;
import components.library.events.AssyncItemError;
import components.library.events.DataEvent;
import components.library.events.ItemPendingError;

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

use namespace mx_internal;

public var collection : AsyncAcapellaCollection;
private var api : AcapellaAPI;

private var selectedGenres : Array = [];
private var selectedGenders : Array = [];
private var selectedStyles : Array = [];
private var selectedKeys : Array = [];
private var selectedAutotunes : Array = [];

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

public function get showOnlyFavorite() : Boolean
{
	return _showOnlyFavorite;
}

public function set showOnlyFavorite( value : Boolean ) : void
{
	_showOnlyFavorite = value;
}

public function get mainComponent() : DisplayObject
{
	return result;
}

public function get searchBoxEnabled() : Boolean
{
	return true;
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
	collection = new AsyncAcapellaCollection();
	collection.addEventListener( components.library.events.DataEvent.DATA_COMPLETE, onResultComplete );
	
    result.dataProvider = collection;
	result.scroller.verticalScrollBar.addEventListener( FlexEvent.CHANGE_START, onResultChangeStart );
	result.scroller.verticalScrollBar.addEventListener( FlexEvent.CHANGE_END, onResultChangeEnd );
	result.scroller.verticalScrollBar.addEventListener( Event.CHANGE, onResultChange );
	
	api = new AcapellaAPI();
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

private function updateGenders( genders : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( gendersContainer.numElements > 0 )
	{
		gendersContainer.removeAllElements();
	}
		
	i = 0;
	
	while( i < genders.length )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = Settings.getAcapellaGenderDescription( genders[ i ] );
		b.data = genders[ i ];
		b.addEventListener( MouseEvent.CLICK, onGendersClick );
				
		gendersContainer.addElement( b );
		
		i ++;
	}
	
	gendersLabel.visible = genders.length > 0;
}

private function updateStyles( styles : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( stylesContainer.numElements > 0 )
	{
		stylesContainer.removeAllElements();
	}
	
	i = 0;
	//R&P - всегда должен быть вконце списка
	while( i < styles.length )
	{
		if ( styles[ i ] == 'R&P' )
		{
			var s : String = styles[ styles.length - 1 ];
			styles[ styles.length - 1 ] = styles[ i ];
			styles[ i ] = s;
			break;
		}
		
		i ++;
	}
	
	i = 0;
	
	while( i < styles.length )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = Settings.getAcapellaStyleDescription( styles[ i ] );
		b.data = styles[ i ];
		b.addEventListener( MouseEvent.CLICK, onStylesClick );
		
		stylesContainer.addElement( b );
		
		i ++;
	}
	
	stylesLabel.visible = styles.length > 0;
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

private function updateAutotune( autotunes : Array ) : void
{
	var i : int;
	var b : Button;
	
	if ( autotuneContainer.numElements > 0 )
	{
		autotuneContainer.removeAllElements();
	}
	
	i = autotunes.length - 1;
	
	while( i >= 0 )
	{
		b = new LinkButton();
		b.height = 21;
		b.toggle = true;
		b.focusEnabled = false;
		b.tabEnabled = false;
		b.label = Settings.getYesNoDescription( autotunes[ i ] ); 
		b.data = autotunes[ i ];
		b.addEventListener( MouseEvent.CLICK, onAutotuneClick );
		
		autotuneContainer.addElement( b );
		
		i --;
	}
	
	autotuneLabel.visible = autotunes.length > 0;
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

private function onStylesClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;
	
	if ( b.selected )
	{
		selectedStyles.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedStyles, String( b.data ) );
	}
	
	_search();
}

private function onGendersClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;
	
	if ( b.selected )
	{
		selectedGenders.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedGenders, String( b.data ) );
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

private function onAutotuneClick( e : MouseEvent ) : void
{
	var b : Button = e.currentTarget as Button;
	
	if ( b.selected )
	{
		selectedAutotunes.push( String( b.data ) );
	}
	else
	{
		excludeFromList( selectedAutotunes, String( b.data ) );
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
	gendersContainer.enabled = value;
	stylesContainer.enabled = value;
	keysContainer.enabled = value;
	autotuneContainer.enabled = value;
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
	selectedGenders = [];
	selectedStyles = [];
	selectedKeys = [];
	selectedAutotunes = [];

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
	
	var searchParams : Object = { genres : selectedGenres, genders : selectedGenders, styles : selectedStyles, tempoFrom : tempo.values[ 0 ], tempoTo : tempo.values[ 1 ], 
		                          keys : selectedKeys, showOnlyFavorite : _showOnlyFavorite, orderBy : sortList.sortField, order : sortList.descending ? 'desc' : 'asc'
	                            };
	
	if ( selectedAutotunes.length == 1 )
	{
		searchParams.autotune = selectedAutotunes[ 0 ];
	}
	
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
		var updateGenders : Boolean = selectedGenders.length == 0;
		var updateStyles : Boolean = selectedStyles.length == 0;
		var updateKeys : Boolean = selectedKeys.length == 0;
		var updateAutotunes : Boolean = selectedAutotunes.length == 0;
		
		if ( ! updateGenres )
		{
			tagParams.genres = selectedGenres;
		}
		
		if ( ! updateGenders )
		{
			tagParams.genders = selectedGenders;
		}
		
		if ( ! updateStyles )
		{
			tagParams.styles = selectedStyles;
		}
		
		if ( ! updateKeys )
		{
			tagParams.keys = selectedKeys;
		}
		
		if ( ! updateAutotunes )
		{
			if ( searchParams.autotune != undefined )
			{
				tagParams.autotune = searchParams.autotune;
			}
		}
		
		if ( updateGenres || updateGenders || updateStyles || updateKeys || updateAutotunes )
		{
			api.getSearchParams( tagParams, updateGenres, updateGenders, false, updateKeys, updateStyles, updateAutotunes );	
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
		
	if ( e.genders )
	{
		updateGenders( e.genders );
	}
	
	if ( e.styles )
	{
		updateStyles( e.styles );
	}
	
	if ( e.keys )
	{
	   updateKeys( e.keys );	
	}
	
	if ( e.autotunes )
	{
		updateAutotune( e.autotunes );
	}
		
	tagLoading = false;
	
	setTagEnabled( ! tagLoading &&  ! resultLoading );
}