import flash.events.Event;

/**
 *Смещение фазы семпла в секундах
 */		
protected var _sampleOffset : Number = 0;

/**
 * Смещение фазы семпла относительно самого семпла 
 */
protected var _localSampleOffset : Number = 0;

/**
 *Общая длительность лупа в секундах 
 */
//protected var _loopDuration : Number = _timeDuration;

/**
 *Общая длительность лупа в секундах 
 */
[Bindable (event="loopDurationChanged")]
/*
public function get loopDuration() : Number
{
	return _loopDuration;
}
*/
public function set loopDuration( value : Number ) : void
{
	/*if ( value != _loopDuration )
	{
		if ( value < _timeDuration )
		{
			_loopDuration = _timeDuration;
		}
		else
		{
			_loopDuration = value;
		}
		
		dispatchEvent( new Event( "loopDurationChanged" ) );
		invalidateSize();
		invalidateDisplayList();
	}	*/
}	


/**
 *Смещение фазы семпла в секундах
 */
[Bindable (event="sampleOffsetChanged")]
public function get sampleOffset() : Number
{
	return _sampleOffset;
}

public function set sampleOffset( value : Number ) : void
{
	if ( value != _sampleOffset )
	{
		_sampleOffset = value;
		//_localSampleOffset = _sampleOffset - Math.floor( _sampleOffset / _timeDuration ) * _timeDuration;
		
		dispatchEvent( new Event( "sampleOffsetChanged" ) );
		invalidateDisplayList();
	}	
}

/**
 * Смещение фазы семпла относительно самого семпла 
 */
public function get localSampleOffset() : Number
{
	return _localSampleOffset;
}	
/*
override public function set timeDuration(value:Number):void
{
	if ( _timeDuration != value )
	{
		_timeDuration = value;
		if ( _timeDuration > _loopDuration )
		{
			_loopDuration = _timeDuration;
		}	
		
		invalidateDisplayList();
		invalidateSize();
	}	  
}
*/
override protected function measure():void
{
	super.measure();
	//measuredWidth =  _loopDuration  / _scale;
}