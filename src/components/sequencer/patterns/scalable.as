import flash.events.Event;

/**
 *Масштаб Количество секунд в пикселе
 *Это значение используется для определения длины трека по умолчанию на основании _duration 
 */
protected var _scale : Number = 1/25;

/**
 *Длина объекта в секундах 
 * 
 */
protected var _duration : Number = 3;

[Bindable (event="scaleChanged")]
public function get scale():Number
{
	return _scale;
}

public function set scale(value:Number):void
{
	if ( _scale != value )
	{  
		_scale = value;
		dispatchEvent( new Event( "scaleChanged" ) );
		invalidateSize();
	}
}

[Bindable (event="durationChanged")]
public function get duration():Number
{
	return _duration;
}

public function set duration(value:Number):void
{
	if ( _duration != value )
	{
		_duration = value;
		dispatchEvent( new Event( "durationChanged" ) );
		invalidateSize();
	}	  
}

protected function getMeasuredWidth() : Number
{
	return _duration / _scale;
}	

override protected function measure():void
{
	super.measure();
	
	measuredWidth = getMeasuredWidth();
}