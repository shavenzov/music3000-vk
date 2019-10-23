/**
 * Базовый паттерн реализующий интерфейс IPositioned
 * 
 */

/**
 * Положение курсора воспроизведения в секундах 
 */		
protected var _position : Number = 0;

 /**
 *  Положение объекта в секундах
 */		
[Bindable("positionChanged")]
public function get position() : Number
{
	return _position;
}

public function set position( value : Number ) : void
{
	if ( value != _position )
	{
		_position = value;
		invalidateDisplayList();
	}	
}