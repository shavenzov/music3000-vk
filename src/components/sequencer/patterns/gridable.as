/**
 *Интервал сетки в секундах при масштабе ( _scale = 1 (1:1) ),
 * 
 */
protected var _gridInterval : Number;

//минимальное расстояние между основными засечками сетки в пикселях
protected var _minStep : Number;

public function get minStep() : Number
{
	return _minStep;	
}

public function set minStep( value : Number ) : void
{
	if ( value != _minStep )
	{
		_minStep = value;
		invalidateDisplayList();
	}	
}

public function get gridInterval() : Number
{
	return _gridInterval;	
}

public function set gridInterval( value : Number ) : void
{
	if ( value != _gridInterval )
	{
		_gridInterval = value;
		invalidateDisplayList();
	}	
}