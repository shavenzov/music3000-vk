
import components.controls.SortButton;
import components.library.controls.events.ResultSortEvent;

import flash.events.Event;
import flash.events.MouseEvent;

private var _descending : Boolean = true;
private var _sortField : String;

private var buttons : Vector.<SortButton>; 

/**
 * Список полей по которым совершать сортировку 
 */
private var _sortFields : Array = [ 'id', 'name', 'duration', 'tempo' ];
private var _sortFieldsChanged : Boolean;

public function get sortFields() : Array
{
	return _sortFields;
}

public function set sortFields( value : Array ) : void
{
	_sortFields = value;
	_sortFieldsChanged = true;
	invalidateProperties();
}

private static function getSortButtonIcon( fieldName : String ) : Class
{
	switch( fieldName )
	{
		case 'id'       : return Assets.CALENDAR_ICON;
		case 'duration' : return Assets.DURATION_ICON;
		case 'tempo'    : return Assets.METRONOME_ICON;
		case 'name'     : return Assets.SYMBOL_ICON;	
	}
	
	return Assets.SYMBOL_ICON;
}

private function updateSortButtons() : void
{
	var i : int;
	var b : SortButton;
	
	//Удаляем предыдущие кнопки
	for ( i = this.numElements - 1; i >= 0; i -- )
	{
		b = this.getElementAt( i ) as SortButton;
		
		if ( b )
		{
			b.removeEventListener( Event.SELECT, onSelect );
			b.removeEventListener( MouseEvent.CLICK, onClick );
			
			this.removeElementAt( i );
		}
	}
	
	//Добавляем другие - новые
	buttons = new Vector.<SortButton>();
	
	for ( i = 0; i < _sortFields.length; i ++ )
	{
		b = new SortButton();
		b.width = b.height = 23;
		b.descending = _descending;
		b.sortField = _sortFields[ i ];
		b.setStyle( 'icon', getSortButtonIcon( _sortFields[ i ] ) );
		b.addEventListener( Event.SELECT, onSelect );
		b.addEventListener( MouseEvent.CLICK, onClick );
		
		buttons.push( b );
	    this.addElement( b );
	}
	
	_sortField = buttons[ 0 ].sortField;
	buttons[ 0 ].selected = true;
	updateToolTips();
}

public function get sortField() : String
{
	return _sortField;
}

public function get descending() : Boolean
{
	return _descending;
}

override protected function createChildren() : void
{
	super.createChildren();
	updateSortButtons();
}

override protected function commitProperties() : void
{
	super.commitProperties();
	
	if ( _sortFieldsChanged )
	{
		updateSortButtons();
		_sortFieldsChanged = false;
		dispatchEvent( new ResultSortEvent( ResultSortEvent.SORT_PARAMS_CHANGED, _sortField, _descending ) );
	}
}

/**
 * Изменился только порядок сортировки, но не поле 
 * @param e
 * 
 */
private function onSelect( e : Event ) : void
{
	var sorter : SortButton = SortButton( e.currentTarget );
	_descending = sorter.descending;
	updateToolTips();
	
	dispatchEvent( new ResultSortEvent( ResultSortEvent.SORT_PARAMS_CHANGED, _sortField, _descending ) );
}

/**
 * Изменился парметр сортировки 
 * @param e
 * 
 */
private function onClick( e : MouseEvent ) : void
{
	var sorter : SortButton = SortButton( e.currentTarget );
	    sorter.descending = _descending;
	
	_sortField = sorter.sortField;	
		
	for each( var s : SortButton in buttons )
	{
		if ( s != sorter )
		{
			s.selected = false;
		}
	}
	
	updateToolTips();
	
	dispatchEvent( new ResultSortEvent( ResultSortEvent.SORT_PARAMS_CHANGED, _sortField, _descending ) );
}

private static const tips : Vector.<String> = Vector.<String>([
	'Щелкни для сортировки по названию. От Z до A.',
	'Щелкни для сортировки по названию. От А до Z.',
	'Щелкни для сортировки по длине. Самые длинные будут вверху.',
	'Щелкни для сортировки по длине. Самые длинные будут внизу.',
	'Щелкни для сортировки по темпу. Самые быстрые будут вверху.',
	'Щелкни для сортировки по темпу. Самые быстрые будут внизу.',
	'Щелкни для сортировки по дате добавления. Самые новые будут вверху.',
	'Щелкни для сортировки по дате добавления. Самые новые будут внизу.'
	]);

private function updateToolTips() : void
{
	for ( var i : int = 0; i < buttons.length; i ++ )
	{
		var b : SortButton = buttons[ i ];
		
		switch( b.sortField )
		{
			case 'name' : b.toolTip = _descending ? ( b.selected ? tips[ 1 ] : tips[ 0 ] )
				                                : ( b.selected ? tips[ 0 ] : tips[ 1 ] );
									break;
			case 'duration' : b.toolTip = _descending ? ( b.selected ? tips[ 3 ] : tips[ 2 ] )
				                                      : ( b.selected ? tips[ 2 ] : tips[ 3 ] );
								    break;
			case 'tempo' : b.toolTip = _descending ? ( b.selected ? tips[ 5 ] : tips[ 4 ] )
				                                   : ( b.selected ? tips[ 4 ] : tips[ 5 ] );
									 break;
			case 'id' : b.toolTip = _descending ? ( b.selected ? tips[ 7 ] : tips[ 6 ] )
				                                  : ( b.selected ? tips[ 6 ] : tips[ 7 ] );
									 break;
		}
	}
}