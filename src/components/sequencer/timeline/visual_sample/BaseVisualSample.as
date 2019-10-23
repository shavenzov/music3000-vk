/**
 * Базовый класс всех визуальных семплов 
 */
package components.sequencer.timeline.visual_sample
{
	import classes.BaseDescription;
	
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sequencer.Note;
	
	import components.Base;
	import components.sequencer.ColorPalette;
	import components.sequencer.timeline.ILoop;
	import components.sequencer.timeline.IPosition;
	import components.sequencer.timeline.IScale;
	
	import flash.events.MouseEvent;

	public class BaseVisualSample extends Base implements IScale, IPosition, ILoop
	{
		/**
		 * Описание семпла 
		 */		
		private var _description : BaseDescription;
		
		/**
		 * Цвет 
		 */		
		protected var _color : uint;
		
		/**
		 * Номер дорожки на которой находится семпл 
		 */		
		protected var _trackNumber : int;
		
		/**
		 *Масштаб Количество фреймов в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		protected var _scale        : Number  = 1/25;
		
		/**
		 * Общая длина семпла в фреймах 
		 * 
		 */
		protected var _duration        : Number  = 3 * AudioData.RATE;
		
		/**
		 * Длина петли в пределах одного семпла
		 */		
		protected var _loopDuration : Number = 0;
		
		/**
		 * Смещение петли
		 */		
		protected var _offset : Number = 0;
		
		/**
		 * Смещение фазы семпла относительно самого семпла 
		 */
		protected var _localOffset : Number = 0;
		
		/**
		 * Положение на треке в фреймах 
		 */		
		protected var _position : Number = 0;
		
		/**
		 * Указатель семпла в секвенсоре 
		 */		
		public var note : Note;
		
		/**
		 * Изменился один из параметров необходимо перерасчитать параметры 
		 */		
		protected var _needRecalc : Boolean;
		
		public function BaseVisualSample()
		{
			super();
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		private function onMouseDown( e : MouseEvent ) : void
		{
			//trace( _position + ',' + _duration );
		}	
		
		public function get description() : BaseDescription
		{
			return _description;
		}
		
		public function set description( value : BaseDescription ) : void
		{
			_description = value;
		}
		
		public function get trackNumber() : int
		{
			return _trackNumber;
		}
		
		public function set trackNumber( value : int ) : void
		{
			_trackNumber = value;
			_color = ColorPalette.getColor( _trackNumber );
			_needUpdate = true;
		}	
		
		public function get scale() : Number
		{
			return _scale;
		}
		
		public function set scale( value : Number ) : void
		{	
		  if ( _scale != value )
		  {
			  _scale = value;
			  
			  _needMeasure = true;
			  _needUpdate = true;
			  _needRecalc = true;
		  }	   
		}	
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
		   if ( _duration != value )
		   {
			  _duration = value;
				  
			  _needMeasure = true;
			  _needUpdate = true;
			  _needRecalc = true; 
		   }   
		}
		
		public function get timeDuration() : Number
		{
			return TimeConversion.numSamplesToSeconds( _duration );
		}
		
		public function set timeDuration( value : Number ) : void
		{
			duration = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get position() : Number
		{
			return _position;
		}
		
		public function set position( value : Number ) : void
		{
			_position = value;
		}
		
		public function get timePosition() : Number
		{
			return TimeConversion.numSamplesToSeconds( _position );
		}
		
		public function set timePosition( value : Number ) : void
		{
			position = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get loopDuration() : Number
		{
			return _loopDuration;
		}
		
		public function set loopDuration( value : Number ) : void
		{
			//value = Math.round( value * 100 ) / 100;
			
			if ( _loopDuration != value )
			{
				_loopDuration = value;
				
				_needMeasure = true;
				_needUpdate = true;
				_needRecalc = true;	
			}
		}
		
		public function get timeLoopDuration() : Number
		{
			return TimeConversion.numSamplesToSeconds( _duration );
		}
		
		public function set timeLoopDuration( value : Number ) : void
		{
			loopDuration = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get offset() : Number
		{
			return _offset;
		}
		
		public function set offset( value : Number ) : void
		{
		   if ( value != _offset )
		   {
			   _offset = value;
			   _localOffset = Math.abs( _offset - Math.ceil( _offset / _loopDuration ) * _loopDuration );
			   //trace( 'localOffset =', _localOffset );
			   //_localOffset = Math.round( _localOffset * 1000 ) / 1000;
			   _needUpdate = true;
			   _needRecalc = true;
		   }   
		}
		
		public function get timeOffset() : Number
		{
			return TimeConversion.numSamplesToSeconds( _offset );
		}
		
		public function set timeOffset( value : Number ) : void
		{
			offset = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get localOffset() : Number
		{
			return _localOffset;
		}	
		
		override protected function measure() : void
		{
			contentWidth = _duration / _scale;
		}	
		
		public function clone() : BaseVisualSample
		{
			throw new Error( "This method must be overrided in childs." );
		}	
	}
}